"""Authenticated WebSocket endpoints for realtime sync.

Protocol (client → server):
    {"type": "auth", "token": "<app JWT | firebase id token>"}     (first message, within 10s)
    {"type": "ping"}                                               (heartbeat)

Protocol (server → client):
    {"type": "auth_ok", "channels": [...]}
    {"type": "pong"}
    {"type": "event", "topic": ..., "action": ..., "entity_id": ..., "data": ..., "ts": ..., "v": 1}

Close codes: 4401 auth failed / timed out, 4403 forbidden.

Tokens travel in the first WS message rather than the URL so they never land
in access logs or proxy logs. Use WSS in production (same TLS termination as HTTPS).
"""

import asyncio
import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy import select

from ..config import settings
from ..database import AsyncSessionLocal
from ..models import User
from ..services.event_bus import event_bus
from ..services.firebase_service import verify_firebase_token

logger = logging.getLogger(__name__)

router = APIRouter(tags=["realtime"])

_AUTH_TIMEOUT_SECONDS = 10


async def _safe_close(websocket: WebSocket, code: int, reason: str) -> None:
    """websocket.close() raises if the client already disconnected during the
    auth handshake (the socket is closed on both ends by then) — that's a
    normal client-side disconnect, not a server error, so swallow it."""
    try:
        await websocket.close(code=code, reason=reason)
    except RuntimeError:
        pass


async def _read_auth_token(websocket: WebSocket) -> str | None:
    """Wait for the first message and extract the auth token, or None."""
    try:
        raw = await asyncio.wait_for(
            websocket.receive_text(), timeout=_AUTH_TIMEOUT_SECONDS
        )
        message = json.loads(raw)
        if message.get("type") != "auth":
            return None
        token = message.get("token")
        return token if isinstance(token, str) and token else None
    except (asyncio.TimeoutError, json.JSONDecodeError, WebSocketDisconnect):
        return None


async def _listen_loop(websocket: WebSocket) -> None:
    """Serve heartbeats until the client disconnects."""
    while True:
        raw = await websocket.receive_text()
        try:
            message = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if message.get("type") == "ping":
            await websocket.send_text(json.dumps({"type": "pong"}))


@router.websocket("/ws/app")
async def websocket_app(websocket: WebSocket) -> None:
    """Customer/delivery app connection: catalog events + own order events."""
    await websocket.accept()

    token = await _read_auth_token(websocket)
    if token is None:
        await _safe_close(websocket, 4401, "Auth required")
        return

    user_id: str | None = None
    firebase_uid: str | None = None
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = payload["user_id"]
    except (JWTError, KeyError):
        try:
            # verify_firebase_token is a synchronous call — keep it off the loop
            decoded = await asyncio.to_thread(verify_firebase_token, token)
            firebase_uid = decoded["uid"]
        except Exception:
            firebase_uid = None

    if user_id is None and firebase_uid is None:
        await _safe_close(websocket, 4401, "Invalid token")
        return

    async with AsyncSessionLocal() as db:
        if user_id is not None:
            result = await db.execute(select(User).where(User.id == user_id))
        else:
            result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
        user = result.scalar_one_or_none()

    if user is None or not user.is_active:
        await _safe_close(websocket, 4403, "Account not available")
        return

    channels = ["catalog", f"user:{user.id}"]
    await event_bus.subscribe(websocket, channels)
    await websocket.send_text(json.dumps({"type": "auth_ok", "channels": channels}))
    logger.info("WS app connected user=%s (total=%d)", user.id, event_bus.connection_count())

    try:
        await _listen_loop(websocket)
    except WebSocketDisconnect:
        pass
    finally:
        await event_bus.unsubscribe(websocket)


@router.websocket("/ws/admin")
async def websocket_admin(websocket: WebSocket) -> None:
    """Admin panel connection: sees every event (admin channel + catalog)."""
    await websocket.accept()

    token = await _read_auth_token(websocket)
    if token is None:
        await _safe_close(websocket, 4401, "Auth required")
        return

    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        if payload.get("role") != "admin" or not payload.get("admin_user_id"):
            raise ValueError("Not an admin token")
    except (JWTError, ValueError):
        await _safe_close(websocket, 4401, "Invalid admin token")
        return

    channels = ["admin", "catalog"]
    await event_bus.subscribe(websocket, channels)
    await websocket.send_text(json.dumps({"type": "auth_ok", "channels": channels}))
    logger.info(
        "WS admin connected admin_user=%s (total=%d)",
        payload["admin_user_id"],
        event_bus.connection_count(),
    )

    try:
        await _listen_loop(websocket)
    except WebSocketDisconnect:
        pass
    finally:
        await event_bus.unsubscribe(websocket)
