import base64
import json
import time
import urllib.error
import urllib.parse
import urllib.request

import firebase_admin
from firebase_admin import auth, credentials, messaging

from ..config import settings

_FIREBASE_PROJECT_ID = settings.firebase_project_id
_FIREBASE_API_KEY = settings.firebase_api_key

_app: firebase_admin.App | None = None


def get_firebase_app() -> firebase_admin.App:
    global _app
    if _app is None:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        _app = firebase_admin.initialize_app(cred)
    return _app


def verify_firebase_token(id_token: str) -> dict:
    """Verify Firebase ID token via Google REST API (project-agnostic)."""
    url = (
        "https://identitytoolkit.googleapis.com/v1/accounts:lookup"
        f"?key={_FIREBASE_API_KEY}"
    )
    body = json.dumps({"idToken": id_token}).encode()
    req = urllib.request.Request(
        url, data=body, headers={"Content-Type": "application/json"}, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err_body = e.read().decode()
        raise ValueError(f"Firebase token lookup failed: {err_body}") from e

    users = data.get("users", [])
    if not users:
        raise ValueError("Token lookup returned no users")

    user = users[0]
    # Check token expiry via local JWT decode (fast, no network)
    try:
        payload_b64 = id_token.split(".")[1]
        payload_b64 += "=" * (4 - len(payload_b64) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_b64))
        if payload.get("exp", 0) < time.time():
            raise ValueError("Token expired")
        if payload.get("aud") != _FIREBASE_PROJECT_ID:
            raise ValueError(f"Wrong audience: {payload.get('aud')}")
    except (IndexError, ValueError, json.JSONDecodeError) as e:
        raise ValueError(f"JWT decode error: {e}") from e

    return {
        "uid": user["localId"],
        "phone_number": user.get("phoneNumber"),
        "email": user.get("email"),
    }


def set_user_role_claim(firebase_uid: str, role: str) -> None:
    """Sets a custom 'role' claim on the Firebase Auth user token.
    This is what Firestore rules check with request.auth.token.role.
    """
    get_firebase_app()
    auth.set_custom_user_claims(firebase_uid, {"role": role})


def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    """Send FCM push notification to a single device."""
    get_firebase_app()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        token=fcm_token,
        android=messaging.AndroidConfig(
            notification=messaging.AndroidNotification(
                channel_id="snapprint_orders",
                priority="high",
            )
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default")
            )
        ),
    )
    messaging.send(message)


# Notification templates
def notify_order_placed(fcm_token: str, order_id: str) -> None:
    send_push_notification(
        fcm_token,
        "Order Placed!",
        f"Your order #{order_id} has been placed successfully.",
        {"type": "order_placed", "order_id": order_id},
    )


def notify_order_confirmed(fcm_token: str, order_id: str) -> None:
    send_push_notification(
        fcm_token,
        "Order Confirmed",
        f"Your order #{order_id} is confirmed and being processed.",
        {"type": "order_confirmed", "order_id": order_id},
    )


def notify_out_for_delivery(fcm_token: str, order_id: str) -> None:
    send_push_notification(
        fcm_token,
        "Out for Delivery",
        f"Your order #{order_id} is out for delivery!",
        {"type": "out_for_delivery", "order_id": order_id},
    )


def notify_delivered(fcm_token: str, order_id: str) -> None:
    send_push_notification(
        fcm_token,
        "Delivered!",
        f"Your order #{order_id} has been delivered.",
        {"type": "delivered", "order_id": order_id},
    )
