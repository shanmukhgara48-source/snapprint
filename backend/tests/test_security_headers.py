import importlib

import pytest
from fastapi.testclient import TestClient

from main import app


def test_api_responses_carry_security_headers():
    with TestClient(app) as client:
        response = client.get("/health")
    assert response.status_code in (200, 503)
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "strict-origin-when-cross-origin"
    assert "frame-ancestors 'none'" in response.headers["Content-Security-Policy"]


def test_interactive_docs_are_enabled_outside_production():
    assert app.docs_url == "/docs"
    assert app.openapi_url == "/openapi.json"


def test_production_startup_refuses_incomplete_configuration(monkeypatch):
    """Importing the app with ENV=production but without the full production
    env must fail fast instead of booting insecurely."""
    import app.config as config_module

    monkeypatch.setattr(config_module.settings, "env", "production")
    import main as main_module

    with pytest.raises(RuntimeError, match="production env vars"):
        importlib.reload(main_module)
    # Restore a fully-initialised dev app module for the rest of the suite.
    monkeypatch.setattr(config_module.settings, "env", "development")
    importlib.reload(main_module)
