import asyncio
import uuid
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..database import get_db
from ..dependencies import get_current_user
from ..models import Address, AdminLoginHistory, AdminUser, Coupon, Order, User
from ..schemas.auth import AuthResponse, FirebaseAuthRequest, UserResponse
from ..services.firebase_service import verify_firebase_token, get_firebase_app, set_user_role_claim
from ..services.password import verify_password
from ..services.r2_storage import delete_prefixes

limiter = Limiter(key_func=get_remote_address)


class DevLoginRequest(BaseModel):
    phone: str = Field(pattern=r"^\+[1-9][0-9]{7,14}$")
    secret: str = Field(min_length=1, max_length=512)


class DevLoginResponse(BaseModel):
    dev_token: str
    firebase_uid: str
    user: UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])


class AdminLoginRequest(BaseModel):
    username: str = Field(min_length=1, max_length=128)
    password: str = Field(min_length=1, max_length=512)


class AdminTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


@router.post("/admin/login", response_model=AdminTokenResponse)
@limiter.limit("5/minute")
async def admin_login(
    request: Request,
    payload: AdminLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Username + password login for the admin panel, backed by admin_users."""
    ip = request.client.host if request.client else None

    result = await db.execute(
        select(AdminUser).where(AdminUser.username == payload.username)
    )
    admin = result.scalar_one_or_none()

    valid = admin is not None and admin.is_active and verify_password(
        payload.password, admin.password_hash
    )

    db.add(
        AdminLoginHistory(
            admin_user_id=admin.id if admin else None,
            username_attempted=payload.username,
            ip_address=ip,
            success=valid,
        )
    )
    await db.commit()

    if not valid:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    admin.last_login_at = datetime.now(timezone.utc)
    await db.commit()

    token_data = {
        "sub": admin.username,
        "role": "admin",
        "admin_user_id": admin.id,
        "admin_role": admin.role,
        "exp": datetime.now(timezone.utc) + timedelta(hours=8),
    }
    token = jwt.encode(token_data, settings.secret_key, algorithm=settings.algorithm)
    return AdminTokenResponse(access_token=token)

def _create_app_access_token(user: User) -> str:
    """Mints our own short-lived application JWT after a one-time Firebase
    ID token verification — the client uses this (not the raw Firebase
    token) for every subsequent authenticated request."""
    token_data = {
        "sub": user.id,
        "user_id": user.id,
        "firebase_uid": user.firebase_uid,
        "role": user.role,
        "exp": datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes),
    }
    return jwt.encode(token_data, settings.secret_key, algorithm=settings.algorithm)


# Reward amounts for the referral program
_REFERRAL_NEW_USER_DISCOUNT = 50.0   # ₹50 off for the new user's first order
_REFERRAL_REFERRER_DISCOUNT = 50.0   # ₹50 off for the referrer's next order


async def _create_referral_coupon(
    db: AsyncSession,
    for_user_id: str,
    prefix: str,
) -> Coupon:
    """Creates a one-time ₹50 flat coupon valid for 90 days."""
    code = f"{prefix}{str(uuid.uuid4())[:6].upper()}"
    coupon = Coupon(
        code=code,
        owner_user_id=for_user_id,
        discount_type="flat",
        value=_REFERRAL_NEW_USER_DISCOUNT,
        min_order=0,
        max_uses=1,
        expires_at=datetime.now(timezone.utc) + timedelta(days=90),
    )
    db.add(coupon)
    return coupon


@router.post("/dev-login", response_model=DevLoginResponse)
@limiter.limit("3/minute")
async def dev_login(
    request: Request,
    payload: DevLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> DevLoginResponse:
    """Dev-only bypass login. Disabled when DEV_BYPASS_SECRET is not set."""
    if not settings.dev_bypass_secret or payload.secret != settings.dev_bypass_secret:
        raise HTTPException(status_code=403, detail="Dev login is disabled or secret is invalid")

    result = await db.execute(select(User).where(User.phone == payload.phone))
    user = result.scalar_one_or_none()

    if user is None:
        user = User(
            firebase_uid=f"dev_{uuid.uuid4().hex[:16]}",
            phone=payload.phone,
            role="customer",
            referral_code=str(uuid.uuid4())[:8].upper(),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    dev_token = _create_app_access_token(user)
    return DevLoginResponse(
        dev_token=dev_token,
        firebase_uid=user.firebase_uid,
        user=UserResponse.model_validate(user),
    )


@router.post("/verify", response_model=AuthResponse)
@limiter.limit("10/minute")
async def verify_user(
    request: Request,
    payload: FirebaseAuthRequest,
    db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    """
    Called immediately after Firebase Phone OTP verification. Exchanges a
    short-lived Firebase ID token (proof the caller owns the UID, verified
    via firebase_admin.auth.verify_id_token) for our own application access
    token — the client never uses the raw Firebase token again after this.
    - Creates user if new (with auto-generated referral code).
    - Handles referral: if referred_by_code is provided and valid, creates
      a ₹50 coupon for the new user AND a ₹50 coupon for the referrer.
    - Updates FCM token if user already exists.
    """
    try:
        decoded = verify_firebase_token(payload.id_token)
        firebase_uid: str = decoded["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired Firebase ID token")

    verified_phone = decoded.get("phone_number")
    if not isinstance(verified_phone, str) or verified_phone != payload.phone:
        raise HTTPException(
            status_code=400,
            detail="Phone number does not match the verified Firebase identity.",
        )

    result = await db.execute(
        select(User).where(User.firebase_uid == firebase_uid)
    )
    user = result.scalar_one_or_none()

    if user is None:
        # New user registration — only customers can self-register via OTP
        # Delivery accounts must be created by admin
        if payload.role not in ("customer",):
            raise HTTPException(status_code=400, detail="Invalid role. Self-registration is only available for customers.")

        # Resolve referral code
        referrer: User | None = None
        if payload.referred_by_code:
            ref_result = await db.execute(
                select(User).where(
                    User.referral_code == payload.referred_by_code.strip().upper()
                )
            )
            referrer = ref_result.scalar_one_or_none()

        user = User(
            firebase_uid=firebase_uid,
            phone=payload.phone,
            role=payload.role,
            fcm_token=payload.fcm_token,
            referral_code=str(uuid.uuid4())[:8].upper(),
            referred_by_id=referrer.id if referrer else None,
        )
        db.add(user)
        await db.flush()  # get user.id before creating coupons

        # Set Firebase custom claim so Firestore rules can enforce role checks
        try:
            set_user_role_claim(firebase_uid, payload.role)
        except Exception:
            pass  # Non-fatal; rules fall back to DB-enforced access

        if referrer:
            # Reward: new user gets ₹50 off their first order
            await _create_referral_coupon(db, user.id, prefix="WELCOME")
            # Reward: referrer gets ₹50 off their next order
            await _create_referral_coupon(db, referrer.id, prefix="REFER")

    else:
        # Existing user — just refresh FCM token
        if payload.fcm_token:
            user.fcm_token = payload.fcm_token

    await db.commit()
    await db.refresh(user)
    return AuthResponse(
        access_token=_create_app_access_token(user),
        user=UserResponse.model_validate(user),
    )


@router.delete("/me", status_code=204)
@limiter.limit("3/minute")
async def delete_account(
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """
    Permanently delete the authenticated user's account and all associated data.
    Also deletes the Firebase Authentication user so they cannot sign back in
    with the same phone number without re-registering.
    Required by Google Play policy for apps with account creation.
    """
    active_customer_orders = await db.execute(
        select(Order.id).where(
            Order.user_id == current_user.id,
            Order.status.notin_(["delivered", "cancelled"]),
        )
    )
    active_delivery_orders = await db.execute(
        select(Order.id).where(
            Order.delivery_partner_id == current_user.id,
            Order.status.notin_(["delivered", "cancelled"]),
        )
    )
    if active_customer_orders.first() or active_delivery_orders.first():
        raise HTTPException(
            status_code=409,
            detail="Complete or cancel active orders before deleting this account.",
        )

    is_dev_identity = (
        not settings.is_production
        and current_user.firebase_uid.startswith("dev_")
    )
    order_result = await db.execute(
        select(Order.id).where(Order.user_id == current_user.id)
    )
    order_ids = list(order_result.scalars().all())
    prefixes = [
        f"customizations/{current_user.id}/",
        f"ai-edits/{current_user.id}/",
        *(f"delivery-proofs/{order_id}/" for order_id in order_ids),
    ]
    r2_configured = all(
        (
            settings.r2_account_id,
            settings.r2_access_key_id,
            settings.r2_secret_access_key,
        )
    )
    if r2_configured:
        try:
            await asyncio.to_thread(delete_prefixes, prefixes)
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail="Could not delete stored account media. Please try again.",
            ) from exc
    elif settings.is_production:
        raise HTTPException(
            status_code=500,
            detail="Account media cleanup is not configured.",
        )

    if not is_dev_identity:
        import firebase_admin.auth as fb_auth
        try:
            get_firebase_app()
            await asyncio.to_thread(fb_auth.delete_user, current_user.firebase_uid)
        except fb_auth.UserNotFoundError:
            pass
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail="Could not delete the Firebase account. Please try again.",
            ) from exc

    # Preserve non-personal financial/order history while removing all account
    # identifiers and fulfillment data. Hard deletion would cascade paid orders.
    order_result = await db.execute(
        select(Order).where(Order.user_id == current_user.id)
    )
    for order in order_result.scalars().all():
        order.address_id = None
        order.delivery_address_snapshot = None
        order.delivery_city_snapshot = None
        order.delivery_pincode_snapshot = None
    await db.execute(delete(Address).where(Address.user_id == current_user.id))
    await db.execute(delete(Coupon).where(Coupon.owner_user_id == current_user.id))
    anonymized = uuid.uuid4().hex
    current_user.firebase_uid = f"deleted_{anonymized}"
    current_user.phone = f"deleted_{anonymized}"
    current_user.role = "deleted"
    current_user.is_active = False
    current_user.fcm_token = None
    current_user.referral_code = None
    current_user.referred_by_id = None
    await db.commit()
