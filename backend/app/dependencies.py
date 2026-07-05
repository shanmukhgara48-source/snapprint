from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .config import settings
from .database import get_db
from .models import User
from .services.firebase_service import verify_firebase_token

bearer_scheme = HTTPBearer()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Verify Firebase ID token and return the corresponding User."""
    token = credentials.credentials

    # Dev bypass: token format "dev_{secret}_{firebase_uid}" (only when DEV_BYPASS_SECRET is set)
    if settings.dev_bypass_secret and token.startswith(f"dev_{settings.dev_bypass_secret}_"):
        prefix = f"dev_{settings.dev_bypass_secret}_"
        firebase_uid = token[len(prefix):]
    else:
        try:
            decoded = verify_firebase_token(token)
            firebase_uid = decoded["uid"]
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
            )

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
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
) -> dict:
    """Verify the admin JWT issued by POST /auth/admin/login. Payload contains
    admin_user_id, username, and admin_role (super_admin|manager|support_staff|
    printing_staff|delivery_staff)."""
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.secret_key,
            algorithms=[settings.algorithm],
        )
        if payload.get("role") != "admin" or not payload.get("admin_user_id"):
            raise ValueError("Not an admin token")
        return payload
    except (JWTError, ValueError):
        raise HTTPException(status_code=401, detail="Invalid or expired admin token")


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
