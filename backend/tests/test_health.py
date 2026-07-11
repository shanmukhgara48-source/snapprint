from fastapi.testclient import TestClient

from main import app


def test_health_returns_ok():
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok", "service": "snapprint-api"}


def test_categories_list_is_seeded():
    with TestClient(app) as client:
        response = client.get("/categories")
        assert response.status_code == 200
        assert len(response.json()) > 0
