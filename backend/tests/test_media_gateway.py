import io

from botocore.exceptions import ClientError
from fastapi.testclient import TestClient

from app.routers import media
from app.services.r2_storage import build_media_url, owned_media_key
from main import app


class _FakeR2:
    def __init__(self, *, missing: bool = False, content_type: str = "image/png"):
        self.missing = missing
        self.content_type = content_type
        self.keys: list[str] = []

    def get_object(self, *, Bucket, Key):
        self.keys.append(Key)
        if self.missing:
            raise ClientError(
                {"Error": {"Code": "NoSuchKey", "Message": "missing"}},
                "GetObject",
            )
        payload = b"image-payload"
        return {
            "Body": io.BytesIO(payload),
            "ContentType": self.content_type,
            "ContentLength": len(payload),
            "ETag": '"test-etag"',
        }


def test_media_gateway_streams_only_supported_owned_namespaces(monkeypatch):
    fake = _FakeR2()
    monkeypatch.setattr(media, "r2_client", lambda: fake)
    with TestClient(app) as client:
        response = client.get(
            build_media_url(
                "http://testserver",
                "customizations/user-1/photo.png",
            )
        )
        invalid_namespace = client.get("/media/private/user-1/photo.png")
        traversal = client.get("/media/customizations/user-1/%2E%2E")

    assert response.status_code == 200
    assert response.content == b"image-payload"
    assert response.headers["content-type"] == "image/png"
    assert response.headers["cache-control"].endswith("immutable")
    assert fake.keys == ["customizations/user-1/photo.png"]
    assert invalid_namespace.status_code == 404
    assert traversal.status_code == 404


def test_media_gateway_hides_missing_and_non_image_objects(monkeypatch):
    with TestClient(app) as client:
        monkeypatch.setattr(media, "r2_client", lambda: _FakeR2(missing=True))
        assert client.get(build_media_url(
            "http://testserver", "ai-edits/user-1/missing.png"
        )).status_code == 404

        monkeypatch.setattr(
            media,
            "r2_client",
            lambda: _FakeR2(content_type="text/html"),
        )
        assert client.get(build_media_url(
            "http://testserver", "ai-edits/user-1/not-image.png"
        )).status_code == 404


def test_owned_media_urls_reject_cross_user_and_foreign_hosts():
    assert owned_media_key(
        build_media_url("http://testserver", "customizations/user-1/photo.png"),
        "user-1",
    ) == "customizations/user-1/photo.png"
    assert owned_media_key(
        build_media_url("http://testserver", "customizations/user-2/photo.png"),
        "user-1",
    ) is None
    assert owned_media_key(
        "https://attacker.test/media/customizations/user-1/photo.png",
        "user-1",
    ) is None


def test_all_customer_media_requires_a_valid_capability_signature(monkeypatch):
    fake = _FakeR2()
    monkeypatch.setattr(media, "r2_client", lambda: fake)
    key = "delivery-proofs/order-1/proof.png"
    signed_url = build_media_url("http://testserver", key, signed=True)
    with TestClient(app) as client:
        assert client.get(f"/media/{key}").status_code == 404
        response = client.get(signed_url)
        assert response.status_code == 200

        customer_key = "customizations/user-1/photo.png"
        assert client.get(f"/media/{customer_key}").status_code == 404
        customer_url = build_media_url("http://testserver", customer_key)
        assert client.get(customer_url).status_code == 200
    assert response.headers["cache-control"].startswith("private")
