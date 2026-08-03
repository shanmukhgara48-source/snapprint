from fastapi import HTTPException


ORDER_STATUS_TRANSITIONS: dict[str, set[str]] = {
    "confirmed": {"picked_up", "cancelled"},
    "picked_up": {"out_for_delivery", "cancelled"},
    "out_for_delivery": {"delivered"},
    "delivered": set(),
    "cancelled": set(),
}


def validate_order_status_transition(
    current: str,
    target: str,
    *,
    delivery_partner: bool = False,
) -> bool:
    if target == current:
        return False
    allowed = ORDER_STATUS_TRANSITIONS.get(current, set())
    if delivery_partner:
        allowed = allowed - {"cancelled"}
    if target not in allowed:
        raise HTTPException(
            status_code=409,
            detail=f"Cannot transition from {current!r} to {target!r}",
        )
    return True
