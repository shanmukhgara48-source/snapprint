from fastapi.testclient import TestClient

from app.config import settings
from app.routers import contact
from main import app


def _message(**overrides):
    payload = {
        "name": "Test Customer",
        "email": "customer@example.org",
        "subject": "Help with my order",
        "message": "I would like to change the delivery address on my order.",
    }
    payload.update(overrides)
    return payload


def test_contact_accepts_valid_message():
    contact.limiter.reset()
    with TestClient(app) as client:
        response = client.post("/contact", json=_message())
    assert response.status_code == 201
    assert response.json() == {"ok": True}


def test_contact_rejects_invalid_inputs():
    contact.limiter.reset()
    with TestClient(app) as client:
        assert client.post("/contact", json=_message(email="not-an-email")).status_code == 422
        assert client.post("/contact", json=_message(message="too short")).status_code == 422
        assert client.post("/contact", json=_message(name="A")).status_code == 422


def test_contact_is_rate_limited():
    contact.limiter.reset()
    with TestClient(app) as client:
        for _ in range(5):
            assert client.post("/contact", json=_message()).status_code == 201
        limited = client.post("/contact", json=_message())
    assert limited.status_code == 429


def test_account_endpoints_require_authentication():
    with TestClient(app) as client:
        assert client.get("/auth/me").status_code in (401, 403)
        assert client.delete("/auth/me").status_code in (401, 403)
        assert client.get("/admin/contact-messages").status_code in (401, 403)


def test_account_profile_round_trip_via_dev_login(monkeypatch):
    monkeypatch.setattr(settings, "dev_bypass_secret", "test-bypass-secret")
    with TestClient(app) as client:
        login = client.post(
            "/auth/dev-login",
            json={"phone": "+919876543210", "secret": "test-bypass-secret"},
        )
        assert login.status_code == 200
        headers = {"Authorization": f"Bearer {login.json()['dev_token']}"}
        profile = client.get("/auth/me", headers=headers)
        assert profile.status_code == 200
        assert profile.json()["phone"] == "+919876543210"
        # Customer JWTs must not open the admin inbox.
        assert client.get("/admin/contact-messages", headers=headers).status_code in (401, 403)
