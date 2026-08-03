import io
from types import SimpleNamespace
from urllib.parse import urlparse

from fastapi.testclient import TestClient
from PIL import Image
from pillow_heif import register_heif_opener

from app.dependencies import get_current_user
from app.routers import upload
from main import app


class _FakeR2:
    def __init__(self):
        self.calls = []

    def upload_fileobj(self, fileobj, bucket, key, ExtraArgs=None):
        self.calls.append(
            {
                "body": fileobj.read(),
                "bucket": bucket,
                "key": key,
                "extra": ExtraArgs,
            }
        )


def _png_bytes() -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (32, 24), (20, 40, 60)).save(output, format="PNG")
    return output.getvalue()


def _heic_bytes() -> bytes:
    register_heif_opener()
    output = io.BytesIO()
    Image.new("RGB", (40, 30), (80, 60, 40)).save(output, format="HEIF", quality=90)
    return output.getvalue()


def test_authenticated_upload_validates_and_stores_a_real_image(monkeypatch):
    fake_r2 = _FakeR2()
    monkeypatch.setattr(upload, "r2_client", lambda: fake_r2)
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id="user-1")
    try:
        with TestClient(app) as client:
            response = client.post(
                "/upload/image",
                files={"file": ("photo.png", _png_bytes(), "image/png")},
            )
            assert response.status_code == 201
            assert response.json()["width"] == 32
            assert response.json()["height"] == 24
            public_url = response.json()["public_url"]
            assert urlparse(public_url).path.endswith(".png")
            assert public_url.startswith(
                "http://testserver/media/customizations/user-1/"
            )
            assert urlparse(public_url).query.startswith("sig=")
            assert len(fake_r2.calls) == 1
            assert fake_r2.calls[0]["key"].startswith("customizations/user-1/")
            assert fake_r2.calls[0]["extra"]["ContentType"] == "image/png"

            heic = client.post(
                "/upload/image",
                files={"file": ("photo.heic", _heic_bytes(), "image/heic")},
            )
            assert heic.status_code == 201
            assert heic.json()["width"] == 40
            assert urlparse(heic.json()["public_url"]).path.endswith(".jpg")
            assert fake_r2.calls[1]["extra"]["ContentType"] == "image/jpeg"
            with Image.open(io.BytesIO(fake_r2.calls[1]["body"])) as normalized:
                assert normalized.format == "JPEG"
                assert normalized.size == (40, 30)
    finally:
        app.dependency_overrides.clear()


def test_upload_rejects_spoofed_corrupt_oversized_and_direct_put_inputs(monkeypatch):
    fake_r2 = _FakeR2()
    monkeypatch.setattr(upload, "r2_client", lambda: fake_r2)
    app.dependency_overrides[get_current_user] = lambda: SimpleNamespace(id="user-1")
    try:
        with TestClient(app) as client:
            unsupported = client.post(
                "/upload/image",
                files={"file": ("photo.gif", b"GIF89a", "image/gif")},
            )
            assert unsupported.status_code == 415

            corrupt = client.post(
                "/upload/image",
                files={"file": ("photo.png", b"not-a-real-image", "image/png")},
            )
            assert corrupt.status_code == 400

            spoofed = client.post(
                "/upload/image",
                files={"file": ("photo.jpg", _png_bytes(), "image/jpeg")},
            )
            assert spoofed.status_code == 400

            monkeypatch.setattr(upload, "MAX_FILE_BYTES", 8)
            oversized = client.post(
                "/upload/image",
                files={"file": ("photo.png", _png_bytes(), "image/png")},
            )
            assert oversized.status_code == 413

            retired = client.get(
                "/upload/presign",
                params={"filename": "photo.png", "content_type": "image/png"},
            )
            assert retired.status_code == 410
            assert fake_r2.calls == []
    finally:
        app.dependency_overrides.clear()
