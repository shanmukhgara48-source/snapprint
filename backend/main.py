import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from sqlalchemy import select

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)

from app.config import settings
from app.database import AsyncSessionLocal, Base, engine
from app.models.admin_user import AdminUser
from app.models.delivery_setting import DeliverySetting
from app.models.product import Product
from app.routers import admin, addresses, auth, cart, coupons, delivery, delivery_options, orders, payments, products, upload
from app.services.password import hash_password

_IS_PROD = os.getenv("ENV", "development").lower() == "production"

# Fail fast if critical secrets are missing in production
if _IS_PROD:
    _missing = [k for k, v in {
        "SECRET_KEY": settings.secret_key,
        "RAZORPAY_KEY_ID": settings.razorpay_key_id,
        "RAZORPAY_KEY_SECRET": settings.razorpay_key_secret,
        "R2_ACCESS_KEY_ID": settings.r2_access_key_id,
        "R2_SECRET_ACCESS_KEY": settings.r2_secret_access_key,
        "ADMIN_PASSWORD": settings.admin_password,
    }.items() if not v]
    if _missing:
        raise RuntimeError(f"Missing required production env vars: {', '.join(_missing)}")

_DEFAULT_DELIVERY_SETTINGS = [
    DeliverySetting(type="free",     label="Free Delivery",     price=0,  days_label="5-7 business days"),
    DeliverySetting(type="standard", label="Standard Delivery", price=49, days_label="3-4 business days"),
    DeliverySetting(type="express",  label="Express Delivery",  price=99, days_label="1-2 business days"),
]

_DEFAULT_PRODUCTS = [
    Product(
        name="Photo Prints",
        category="photo_prints",
        base_price=10.0,
        sizes=[
            {"label": "Wallet (2x3)",  "price": 10.0},
            {"label": "4x6",           "price": 15.0},
            {"label": "5x7",           "price": 30.0},
            {"label": "8x10",          "price": 65.0},
            {"label": "A4",            "price": 90.0},
            {"label": "A3",            "price": 150.0},
        ],
        description="High-quality glossy photo prints in popular sizes.",
        image_url="",
        is_active=True,
    ),
    Product(
        name="Classic Photo Mug",
        category="mugs",
        base_price=299.0,
        sizes=[
            {"label": "11oz", "price": 299.0},
            {"label": "15oz", "price": 349.0},
        ],
        description="Personalised ceramic mug with your favourite photo.",
        image_url="",
        is_active=True,
    ),
    Product(
        name="Magic Mug",
        category="mugs",
        base_price=399.0,
        sizes=[
            {"label": "11oz", "price": 399.0},
        ],
        description="Colour-changing magic mug — photo appears when hot.",
        image_url="",
        is_active=True,
    ),
    Product(
        name="Photo Album",
        category="albums",
        base_price=499.0,
        sizes=[
            {"label": "4x6 (36 photos)",  "price": 499.0},
            {"label": "5x7 (24 photos)",  "price": 699.0},
            {"label": "8x10 (20 photos)", "price": 999.0},
        ],
        description="Premium soft-cover photo album.",
        image_url="",
        is_active=True,
    ),
    Product(
        name="Photo Frame",
        category="frames",
        base_price=199.0,
        sizes=[
            {"label": "4x6",  "price": 199.0},
            {"label": "5x7",  "price": 299.0},
            {"label": "8x10", "price": 499.0},
        ],
        description="Classic wooden photo frame with your printed photo.",
        image_url="",
        is_active=True,
    ),
    Product(
        name="Digital Photo Frame",
        category="digital_frames",
        base_price=1999.0,
        sizes=[
            {"label": "7-inch",  "price": 1999.0},
            {"label": "10-inch", "price": 2999.0},
        ],
        description="Wi-Fi enabled digital frame — update photos from your phone.",
        image_url="",
        is_active=True,
    ),
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

        # Seed default products (one per category, skip if any exist in that category)
        for product in _DEFAULT_PRODUCTS:
            existing = await db.execute(
                select(Product).where(Product.category == product.category).limit(1)
            )
            if existing.scalar_one_or_none() is None:
                db.add(product)

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

_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")
    if o.strip()
]

_ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv("ALLOWED_HOSTS", "*").split(",")
    if h.strip()
]

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
    max_bytes = 20 * 1024 * 1024  # 20 MB global cap
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > max_bytes:
        return JSONResponse(status_code=413, content={"detail": "Request body too large"})
    return await call_next(request)

# Routers
app.include_router(auth.router)
app.include_router(products.router)
app.include_router(cart.router)
app.include_router(coupons.router)
app.include_router(addresses.router)
app.include_router(payments.router)
app.include_router(orders.router)
app.include_router(delivery.router)
app.include_router(delivery_options.router)
app.include_router(admin.router)
app.include_router(upload.router)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "snapprint-api"}
