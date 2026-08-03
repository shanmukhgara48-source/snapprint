import json
from pathlib import Path

from app.config import settings
from app.services import firebase_service


def test_backend_token_audience_matches_android_firebase_project():
    google_services = Path(__file__).parents[2] / "snap_print/android/app/google-services.json"
    mobile_project = json.loads(google_services.read_text())["project_info"]["project_id"]

    assert settings.firebase_project_id == mobile_project


def test_firebase_initializer_explicitly_uses_configured_project(monkeypatch):
    captured = {}
    sentinel = object()

    monkeypatch.setattr(firebase_service, "_app", None)
    monkeypatch.setattr(
        firebase_service.credentials,
        "Certificate",
        lambda value: f"credential:{value}",
    )

    def initialize_app(credential, options=None):
        captured["credential"] = credential
        captured["options"] = options
        return sentinel

    monkeypatch.setattr(firebase_service.firebase_admin, "initialize_app", initialize_app)

    assert firebase_service.get_firebase_app() is sentinel
    assert captured["options"]["projectId"] == settings.firebase_project_id
    assert captured["options"]["storageBucket"] == settings.firebase_storage_bucket

    monkeypatch.setattr(firebase_service, "_app", None)
