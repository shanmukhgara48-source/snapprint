from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.config import settings
from app.routers.realtime import _safe_close
from main import app


def _admin_token(admin_user_id: str) -> str:
    return jwt.encode(
        {
            "sub": "missing-admin",
            "role": "admin",
            "admin_user_id": admin_user_id,
            "admin_role": "super_admin",
            "exp": datetime.now(timezone.utc) + timedelta(minutes=5),
        },
        settings.secret_key,
        algorithm=settings.algorithm,
    )


def test_admin_websocket_rejects_signed_token_for_missing_admin():
    with TestClient(app) as client:
        with pytest.raises(WebSocketDisconnect) as closed:
            with client.websocket_connect("/ws/admin") as websocket:
                websocket.send_json(
                    {"type": "auth", "token": _admin_token("missing-admin-id")}
                )
                websocket.receive_json()
        assert closed.value.code == 4403


def test_websockets_require_auth_as_first_message():
    with TestClient(app) as client:
        for path in ("/ws/app", "/ws/admin"):
            with pytest.raises(WebSocketDisconnect) as closed:
                with client.websocket_connect(path) as websocket:
                    websocket.send_json({"type": "ping"})
                    websocket.receive_json()
            assert closed.value.code == 4401


def test_safe_close_tolerates_a_client_that_already_disconnected():
    class DisconnectedSocket:
        async def close(self, **kwargs):
            raise AttributeError("protocol already released")

    import asyncio

    asyncio.run(_safe_close(DisconnectedSocket(), 4401, "Auth required"))
