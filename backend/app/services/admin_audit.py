from sqlalchemy.ext.asyncio import AsyncSession

from ..models.admin_audit_log import AdminAuditLog


async def log_admin_action(
    db: AsyncSession,
    admin_user_id: str,
    action: str,
    resource_type: str,
    resource_id: str | None = None,
    details: dict | None = None,
    ip_address: str | None = None,
) -> None:
    """Record an admin action. Caller is responsible for committing (or this
    commits independently so a failed later step doesn't lose the audit trail)."""
    db.add(
        AdminAuditLog(
            admin_user_id=admin_user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            ip_address=ip_address,
        )
    )
    await db.commit()
