from fastapi.testclient import TestClient

from main import app


def test_auth_rate_limit_blocks_repeated_bypass_attempts():
    with TestClient(app) as client:
        statuses = [
            client.post(
                "/auth/dev-login",
                json={"phone": "+919876543210", "secret": "wrong-secret"},
            ).status_code
            for _ in range(4)
        ]

    assert statuses[:3] == [403, 403, 403]
    assert statuses[3] == 429


def test_global_body_limit_rejects_declared_oversized_requests():
    with TestClient(app) as client:
        response = client.post(
            "/auth/dev-login",
            headers={"Content-Length": str(21 * 1024 * 1024)},
            content=b"{}",
        )

    assert response.status_code == 413
