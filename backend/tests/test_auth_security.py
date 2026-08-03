import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.routers import auth
from app.schemas.auth import FirebaseAuthRequest
from main import app


def test_firebase_phone_must_match_the_verified_token(monkeypatch):
    monkeypatch.setattr(
        auth,
        "verify_firebase_token",
        lambda token: {
            "uid": "verified-user",
            "phone_number": "+919876543210",
        },
    )
    with TestClient(app) as client:
        response = client.post(
            "/auth/verify",
            json={
                "id_token": "signed-firebase-token-value",
                "phone": "+919111111111",
                "role": "customer",
            },
        )
    assert response.status_code == 400
    assert "does not match" in response.json()["detail"]


def test_auth_schema_rejects_malformed_identity_inputs():
    with pytest.raises(ValidationError):
        FirebaseAuthRequest(id_token="short", phone="9876543210")
    with pytest.raises(ValidationError):
        FirebaseAuthRequest(
            id_token="signed-firebase-token-value",
            phone="+9100000000000000000",
        )
