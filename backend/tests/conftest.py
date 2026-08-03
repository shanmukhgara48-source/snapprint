import pytest

from app.config import settings
from app.routers import ai_editor, auth, coupons, delivery, payments, upload
from main import limiter as app_limiter


@pytest.fixture(autouse=True)
def isolate_test_configuration(monkeypatch):
    # Never let a developer or CI machine's .env change URL/signature
    # assertions. Production still requires PUBLIC_API_URL and a strong key.
    monkeypatch.setattr(settings, "public_api_url", "")
    monkeypatch.setattr(settings, "secret_key", "snapprint-test-signing-key-32-bytes")
    for limiter in (
        app_limiter,
        ai_editor.limiter,
        auth.limiter,
        coupons.limiter,
        delivery.limiter,
        payments.limiter,
        upload.limiter,
    ):
        limiter.reset()
    yield
