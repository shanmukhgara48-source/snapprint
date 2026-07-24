import json

import firebase_admin
from firebase_admin import auth, credentials, messaging

from ..config import settings

_app: firebase_admin.App | None = None


def get_firebase_app() -> firebase_admin.App:
    global _app
    if _app is None:
        if settings.firebase_credentials_json:
            cred = credentials.Certificate(json.loads(settings.firebase_credentials_json))
        else:
            cred = credentials.Certificate(settings.firebase_credentials_path)
        _app = firebase_admin.initialize_app(cred)
    return _app


def verify_firebase_token(id_token: str) -> dict:
    """Verify a Firebase ID token locally via the Admin SDK (cached Google
    public keys — signature, expiry, issuer, and audience are all checked,
    with no per-call network round trip)."""
    get_firebase_app()
    decoded = auth.verify_id_token(id_token)
    return {
        "uid": decoded["uid"],
        "phone_number": decoded.get("phone_number"),
        "email": decoded.get("email"),
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


def send_broadcast_notification(
    title: str,
    body: str,
    data: dict | None = None,
) -> None:
    """Send FCM push to every device subscribed to the 'all_users' topic."""
    get_firebase_app()
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data=data or {},
        topic="all_users",
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
