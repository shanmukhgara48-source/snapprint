"""In-process event bus + WebSocket fan-out.

Channel model
-------------
- "catalog"     : public data every app client cares about (products, categories,
                  banners, coupons, delivery settings, app settings).
- "user:{id}"   : private events for one customer (their order status changes).
- "admin"       : every event, mirrored to connected admin-panel sessions.

Mutating endpoints call ``emit_event(...)`` after commit; the bus fans the JSON
payload out to every WebSocket subscribed to the resolved channels.

Scaling seam: ``EventBus.publish`` is the single choke point. To scale
horizontally, replace the direct ``_fanout`` call with a Redis Pub/Sub publish
and have each instance run a subscriber task that calls ``_fanout`` locally.
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Any

from fastapi import WebSocket

logger = logging.getLogger(__name__)

# Topics whose events are safe for (and relevant to) every customer device.
CATALOG_TOPICS = {
    "product",
    "category",
    "banner",
    "coupon",
    "delivery_setting",
    "setting",
}

_SEND_TIMEOUT_SECONDS = 5  # slow/dead clients are dropped, they reconnect + refetch


class EventBus:
    """Tracks WebSocket subscriptions per channel and broadcasts events."""

    def __init__(self) -> None:
        self._channels: dict[str, set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def subscribe(self, websocket: WebSocket, channels: list[str]) -> None:
        async with self._lock:
            for channel in channels:
                self._channels.setdefault(channel, set()).add(websocket)

    async def unsubscribe(self, websocket: WebSocket) -> None:
        async with self._lock:
            for subscribers in self._channels.values():
                subscribers.discard(websocket)
            self._channels = {c: s for c, s in self._channels.items() if s}

    def connection_count(self, channel: str | None = None) -> int:
        if channel is not None:
            return len(self._channels.get(channel, ()))
        return len({ws for subs in self._channels.values() for ws in subs})

    async def publish(self, channels: list[str], event: dict[str, Any]) -> None:
        await self._fanout(channels, event)

    async def _fanout(self, channels: list[str], event: dict[str, Any]) -> None:
        async with self._lock:
            targets = {
                ws
                for channel in channels
                for ws in self._channels.get(channel, ())
            }
        if not targets:
            return

        message = json.dumps(event)
        results = await asyncio.gather(
            *(self._send(ws, message) for ws in targets), return_exceptions=True
        )
        dead = [ws for ws, ok in zip(targets, results) if ok is not True]
        for ws in dead:
            await self.unsubscribe(ws)

    @staticmethod
    async def _send(websocket: WebSocket, message: str) -> bool:
        try:
            await asyncio.wait_for(
                websocket.send_text(message), timeout=_SEND_TIMEOUT_SECONDS
            )
            return True
        except Exception:
            return False


event_bus = EventBus()


def _resolve_channels(
    topic: str, *, user_id: str | None, admin_only: bool
) -> list[str]:
    channels = ["admin"]
    if admin_only:
        return channels
    if user_id:
        channels.append(f"user:{user_id}")
    if topic in CATALOG_TOPICS:
        channels.append("catalog")
    return channels


async def emit_event(
    topic: str,
    action: str,
    entity_id: str | None = None,
    data: dict[str, Any] | None = None,
    *,
    user_id: str | None = None,
    admin_only: bool = False,
) -> None:
    """Publish a domain event to all relevant connected clients.

    Never raises — realtime delivery is best-effort and must not fail the
    HTTP request that triggered it (clients re-sync on reconnect anyway).
    """
    event = {
        "type": "event",
        "topic": topic,
        "action": action,
        "entity_id": entity_id,
        "data": data,
        "ts": datetime.now(timezone.utc).isoformat(),
        "v": 1,
    }
    try:
        channels = _resolve_channels(topic, user_id=user_id, admin_only=admin_only)
        await event_bus.publish(channels, event)
    except Exception:
        logger.exception("Failed to publish event %s.%s", topic, action)
