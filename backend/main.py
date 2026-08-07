import logging
from contextlib import asynccontextmanager
from pathlib import Path
from urllib.parse import urlparse

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy import select, text

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

from app.config import settings
from app.database import AsyncSessionLocal, Base, engine
from app.models.admin_user import AdminUser
from app.models.category import Category
from app.models.delivery_setting import DeliverySetting
from app.models.product import Product
from app.routers import admin, addresses, ai_editor, auth, banners, cart, categories, coupons, delivery, delivery_options, media, orders, payments, products, realtime, upload
from app.seed_data import DEFAULT_CATEGORIES, DEFAULT_PRODUCTS
from app.services.password import hash_password

_IS_PROD = settings.is_production

# Fail fast if critical secrets are missing in production
if _IS_PROD:
    _missing = [k for k, v in {
        "SECRET_KEY": settings.secret_key,
        "RAZORPAY_KEY_ID": settings.razorpay_key_id,
        "RAZORPAY_KEY_SECRET": settings.razorpay_key_secret,
        "FIREBASE_STORAGE_BUCKET": settings.firebase_storage_bucket,
        "FIREBASE_PROJECT_ID": settings.firebase_project_id,
        "R2_ACCESS_KEY_ID": settings.r2_access_key_id,
        "R2_SECRET_ACCESS_KEY": settings.r2_secret_access_key,
        "R2_ACCOUNT_ID": settings.r2_account_id,
        "PUBLIC_API_URL": settings.public_api_url,
        "AI_SEGMENTATION_URL": settings.ai_segmentation_url,
        "AI_SEGMENTATION_TOKEN": settings.ai_segmentation_token,
        "ADMIN_PASSWORD": settings.admin_password,
    }.items() if not v]
    if (
        not settings.firebase_credentials_json
        and (
            not settings.firebase_credentials_path
            or not Path(settings.firebase_credentials_path).exists()
        )
    ):
        _missing.append("FIREBASE_CREDENTIALS_JSON or FIREBASE_CREDENTIALS_PATH")
    # DATABASE_URL always has a value (pydantic default), so check it's not
    # still pointing at the local-dev default — that would mean it was never
    # actually set for this deploy.
    if settings.database_url == "postgresql+asyncpg://postgres:password@localhost:5432/snapprint":
        _missing.append("DATABASE_URL")
    if _missing:
        raise RuntimeError(f"Missing required production env vars: {', '.join(_missing)}")
    if settings.dev_bypass_secret:
        raise RuntimeError("DEV_BYPASS_SECRET must be empty when ENV=production")
    if settings.admin_password == "changeme123":
        raise RuntimeError("ADMIN_PASSWORD must be changed when ENV=production")
    if settings.allowed_hosts == "*":
        raise RuntimeError("ALLOWED_HOSTS must be restricted when ENV=production")
    if settings.razorpay_key_id.startswith("rzp_test_"):
        raise RuntimeError("RAZORPAY_KEY_ID must use live keys when ENV=production")
    if len(settings.secret_key) < 32:
        raise RuntimeError("SECRET_KEY must contain at least 32 characters in production")
    if urlparse(settings.public_api_url).scheme != "https":
        raise RuntimeError("PUBLIC_API_URL must use HTTPS in production")
    if "*" in settings.allowed_origin_list or any(
        urlparse(origin).scheme != "https" for origin in settings.allowed_origin_list
    ):
        raise RuntimeError("ALLOWED_ORIGINS must contain only explicit HTTPS origins")

_DEFAULT_DELIVERY_SETTINGS = [
    DeliverySetting(type="free",     label="Free Delivery",     price=0,  days_label="5-7 business days"),
    DeliverySetting(type="standard", label="Standard Delivery", price=49, days_label="3-4 business days"),
    DeliverySetting(type="express",  label="Express Delivery",  price=99, days_label="1-2 business days"),
]

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # Seed delivery settings
        for setting in _DEFAULT_DELIVERY_SETTINGS:
            existing = await db.execute(
                select(DeliverySetting).where(DeliverySetting.type == setting.type)
            )
            if existing.scalar_one_or_none() is None:
                db.add(DeliverySetting(
                    type=setting.type,
                    label=setting.label,
                    price=setting.price,
                    days_label=setting.days_label,
                ))

        # Seed default categories
        category_ids: dict[str, str] = {}
        for category_data in DEFAULT_CATEGORIES:
            existing = await db.execute(
                select(Category).where(Category.name == category_data["name"])
            )
            existing_category = existing.scalar_one_or_none()
            if existing_category is None:
                category = Category(**category_data)
                db.add(category)
                await db.flush()
                category_ids[category.name] = category.id
            else:
                for field, value in category_data.items():
                    setattr(existing_category, field, value)
                category_ids[existing_category.name] = existing_category.id

        # Seed missing products from the bundled catalog. Admin pricing and
        # availability changes remain authoritative after initial creation.
        for product_data in DEFAULT_PRODUCTS:
            data = dict(product_data)
            data["category_id"] = category_ids.get(data["category"])
            existing = await db.execute(
                select(Product).where(
                    Product.name == data["name"],
                    Product.category == data["category"],
                )
            )
            existing_product = existing.scalar_one_or_none()
            if existing_product is None:
                product = Product(**data)
                db.add(product)
            elif data.get("source_url") and not existing_product.source_url:
                # Recover source imports created before metadata columns were
                # available without overwriting later admin pricing changes.
                for field, value in data.items():
                    setattr(existing_product, field, value)

        # Bootstrap a super_admin from env credentials if no admin exists yet.
        # Subsequent admin management happens via the admin panel (AdminUser table),
        # not .env — ADMIN_USERNAME/ADMIN_PASSWORD only seed the very first account.
        existing_admin = await db.execute(select(AdminUser).limit(1))
        if existing_admin.scalar_one_or_none() is None:
            db.add(AdminUser(
                username=settings.admin_username,
                password_hash=hash_password(settings.admin_password),
                role="super_admin",
            ))

        await db.commit()

    yield
    await engine.dispose()


limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="SnapPrint API",
    description="Photo Product E-Commerce Backend",
    version="1.0.0",
    lifespan=lifespan,
    # Disable interactive docs in production
    docs_url=None if _IS_PROD else "/docs",
    redoc_url=None if _IS_PROD else "/redoc",
    openapi_url=None if _IS_PROD else "/openapi.json",
)

_ALLOWED_ORIGINS = settings.allowed_origin_list
_ALLOWED_HOSTS = settings.allowed_host_list

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Gzip responses over 1KB
app.add_middleware(GZipMiddleware, minimum_size=1024)

# Only trust declared hosts in production
if _IS_PROD and "*" not in _ALLOWED_HOSTS:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=_ALLOWED_HOSTS)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    if _IS_PROD:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response


@app.middleware("http")
async def limit_request_body(request: Request, call_next):
    max_bytes = (
        settings.ai_max_source_bytes + 1024 * 1024
        if request.url.path == "/upload/image"
        else 20 * 1024 * 1024
    )
    content_length = request.headers.get("content-length")
    if content_length:
        try:
            if int(content_length) > max_bytes:
                return JSONResponse(
                    status_code=413,
                    content={"detail": "Request body too large"},
                )
        except ValueError:
            return JSONResponse(
                status_code=400,
                content={"detail": "Invalid Content-Length header"},
            )
    return await call_next(request)

# Routers
app.include_router(auth.router)
app.include_router(products.router)
app.include_router(categories.router)
app.include_router(banners.router)
app.include_router(cart.router)
app.include_router(coupons.router)
app.include_router(addresses.router)
app.include_router(payments.router)
app.include_router(orders.router)
app.include_router(delivery.router)
app.include_router(delivery_options.router)
app.include_router(admin.router)
app.include_router(upload.router)
app.include_router(media.router)
app.include_router(ai_editor.router)
app.include_router(realtime.router)


@app.get("/health")
async def health() -> JSONResponse:
    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
    except Exception:
        logging.getLogger(__name__).exception("Health check DB connectivity failed")
        return JSONResponse(
            status_code=503,
            content={"status": "error", "service": "snapprint-api", "detail": "database unreachable"},
        )
    return JSONResponse(content={"status": "ok", "service": "snapprint-api"})
