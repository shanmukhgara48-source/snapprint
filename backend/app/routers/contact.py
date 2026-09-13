import logging

from fastapi import APIRouter, Depends, Request
from pydantic import BaseModel, EmailStr, Field
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..dependencies import get_current_user
from ..models import ContactMessage, User

logger = logging.getLogger(__name__)

limiter = Limiter(key_func=get_remote_address)
router = APIRouter(prefix="/contact", tags=["contact"])


class ContactRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr = Field(max_length=254)
    subject: str = Field(min_length=4, max_length=160)
    message: str = Field(min_length=10, max_length=5000)


class ContactResponse(BaseModel):
    ok: bool = True


def _client_ip(request: Request) -> str | None:
    if request.client:
        return request.client.host
    return None


async def _current_user_id(request: Request, db: AsyncSession) -> str | None:
    """Best-effort link to the sender's account; anonymous messages allowed."""
    auth = request.headers.get("authorization", "")
    if not auth.lower().startswith("bearer "):
        return None
    try:
        from fastapi.security import HTTPAuthorizationCredentials

        user: User = await get_current_user(
            HTTPAuthorizationCredentials(scheme="Bearer", credentials=auth[7:]), db
        )
        return user.id
    except Exception:
        return None


@router.post("", response_model=ContactResponse, status_code=201)
@limiter.limit("5/hour")
async def submit_contact(
    request: Request,
    payload: ContactRequest,
    db: AsyncSession = Depends(get_db),
) -> ContactResponse:
    """Public contact form. Rate-limited; stored for the support team."""
    user_id = await _current_user_id(request, db)
    db.add(
        ContactMessage(
            name=payload.name.strip(),
            email=str(payload.email).strip().lower(),
            subject=payload.subject.strip(),
            message=payload.message.strip(),
            user_id=user_id,
            ip_address=_client_ip(request),
        )
    )
    await db.commit()
    logger.info("Contact message received from %s", payload.email)
    return ContactResponse()
