"""Live R2 upload/read verification with automatic object and user cleanup."""

import asyncio
import io
import json
import time
import uuid
from urllib.parse import unquote, urlparse

import boto3
import httpx
from PIL import Image

from app.config import settings


def _r2_client():
    return boto3.client(
        "s3",
        endpoint_url=f"https://{settings.r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
        region_name="auto",
    )


def _test_png() -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (320, 240), (32, 96, 160)).save(output, format="PNG")
    return output.getvalue()


async def main() -> None:
    if not settings.dev_bypass_secret:
        raise RuntimeError("DEV_BYPASS_SECRET is required for live upload verification")

    api_url = "http://127.0.0.1:8001"
    phone = f"+919{uuid.uuid4().int % 10**9:09d}"
    public_url = None
    object_key = None
    headers = None
    async with httpx.AsyncClient(timeout=60) as client:
        login = await client.post(
            f"{api_url}/auth/dev-login",
            json={"phone": phone, "secret": settings.dev_bypass_secret},
        )
        login.raise_for_status()
        headers = {"Authorization": f"Bearer {login.json()['dev_token']}"}
        try:
            started = time.perf_counter()
            uploaded = await client.post(
                f"{api_url}/upload/image",
                headers=headers,
                files={"file": ("release-check.png", _test_png(), "image/png")},
            )
            uploaded.raise_for_status()
            upload_ms = (time.perf_counter() - started) * 1000
            payload = uploaded.json()
            public_url = payload["public_url"]
            object_path = unquote(urlparse(public_url).path)
            object_key = object_path.removeprefix("/media/").lstrip("/")
            head = await asyncio.to_thread(
                _r2_client().head_object,
                Bucket=settings.r2_bucket_name,
                Key=object_key,
            )

            started = time.perf_counter()
            downloaded = await client.get(public_url)
            if downloaded.status_code >= 400:
                raise RuntimeError(
                    "R2 object exists but public read failed: "
                    f"object_bytes={head['ContentLength']} status={downloaded.status_code}"
                )
            download_ms = (time.perf_counter() - started) * 1000
            with Image.open(io.BytesIO(downloaded.content)) as image:
                image.verify()
                dimensions = image.size
            if dimensions != (320, 240):
                raise RuntimeError(f"Unexpected downloaded dimensions: {dimensions}")

            print(
                json.dumps(
                    {
                        "status": "ok",
                        "upload_status": uploaded.status_code,
                        "download_status": downloaded.status_code,
                        "dimensions": dimensions,
                        "upload_ms": round(upload_ms, 1),
                        "download_ms": round(download_ms, 1),
                        "content_type": downloaded.headers.get("content-type"),
                    }
                )
            )
        finally:
            if object_key:
                await asyncio.to_thread(
                    _r2_client().delete_object,
                    Bucket=settings.r2_bucket_name,
                    Key=object_key,
                )
            if headers:
                await client.delete(f"{api_url}/auth/me", headers=headers)


if __name__ == "__main__":
    asyncio.run(main())
