from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings
from .database import get_db
from .models import AdminUser, User

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Verify our application access token (minted once by POST /auth/verify
    after a genuine Firebase ID token check) and return the corresponding
    User. The raw Firebase ID token is never re-verified per request."""
    token = credentials.credentials

    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = payload["user_id"]
    except (JWTError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not registered. Please complete registration.",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated.",
        )
    return user


async def require_customer(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if user.role not in ("customer", "admin"):
        raise HTTPException(status_code=403, detail="Customer access required")
    return user


async def require_delivery(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if user.role not in ("delivery", "admin"):
        raise HTTPException(status_code=403, detail="Delivery partner access required")
    return user


async def require_admin(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return user


async def require_admin_jwt(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    """Verify the admin JWT issued by POST /auth/admin/login, then re-check the
    admin's current is_active/role against the DB so a disable or role change
    takes effect immediately instead of waiting out the token's 8h lifetime.
    Payload contains admin_user_id, username, and admin_role (super_admin|
    manager|support_staff|printing_staff|delivery_staff), refreshed from the DB."""
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )
        if payload.get("role") != "admin" or not payload.get("admin_user_id"):
            raise ValueError("Not an admin token")
    except (JWTError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired admin token")

    result = await db.execute(select(AdminUser).where(AdminUser.id == payload["admin_user_id"]))
    admin_user = result.scalar_one_or_none()
    if admin_user is None or not admin_user.is_active:
        raise HTTPException(status_code=401, detail="Admin account is deactivated or no longer exists")

    payload["admin_role"] = admin_user.role
    return payload


def require_admin_role(*allowed_roles: str):
    """Dependency factory: restrict an admin endpoint to specific admin_role values.
    Usage: Depends(require_admin_role("super_admin", "manager"))"""

    async def _check(
        payload: Annotated[dict, Depends(require_admin_jwt)],
    ) -> dict:
        if payload.get("admin_role") not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail=f"Requires one of roles: {', '.join(allowed_roles)}",
            )
        return payload

    return _check
