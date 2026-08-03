import hashlib
import hmac
from pathlib import PurePosixPath
from urllib.parse import parse_qs, quote, unquote, urlparse

import boto3

from ..config import settings


MEDIA_NAMESPACES = {"customizations", "ai-edits", "delivery-proofs"}
EDITABLE_MEDIA_NAMESPACES = {"customizations", "ai-edits"}


def r2_client():
    return boto3.client(
        "s3",
        endpoint_url=f"https://{settings.r2_account_id}.r2.cloudflarestorage.com",
        aws_access_key_id=settings.r2_access_key_id,
        aws_secret_access_key=settings.r2_secret_access_key,
        region_name="auto",
    )


def delete_prefixes(prefixes: list[str]) -> None:
    client = r2_client()
    for prefix in prefixes:
        continuation_token = None
        while True:
            kwargs = {"Bucket": settings.r2_bucket_name, "Prefix": prefix}
            if continuation_token:
                kwargs["ContinuationToken"] = continuation_token
            page = client.list_objects_v2(**kwargs)
            objects = [{"Key": item["Key"]} for item in page.get("Contents", [])]
            if objects:
                client.delete_objects(
                    Bucket=settings.r2_bucket_name,
                    Delete={"Objects": objects, "Quiet": True},
                )
            if not page.get("IsTruncated"):
                break
            continuation_token = page.get("NextContinuationToken")


def media_base_url(request_base_url: str) -> str:
    return (settings.public_api_url or request_base_url).rstrip("/")


def sign_media_key(key: str) -> str:
    return hmac.new(
        settings.secret_key.encode(),
        key.encode(),
        hashlib.sha256,
    ).hexdigest()


def build_media_url(public_base_url: str, key: str, *, signed: bool = True) -> str:
    url = f"{public_base_url.rstrip('/')}/media/{key.lstrip('/')}"
    return f"{url}?sig={quote(sign_media_key(key))}" if signed else url


def key_belongs_to_user(key: str, user_id: str) -> bool:
    parts = PurePosixPath(unquote(key)).parts
    return (
        len(parts) == 3
        and ".." not in parts
        and parts[0] in EDITABLE_MEDIA_NAMESPACES
        and parts[1] == user_id
        and bool(parts[2])
    )


def hosted_media_key(image_url: str) -> str | None:
    parsed = urlparse(image_url)
    if (
        parsed.scheme not in {"http", "https"}
        or parsed.username
        or parsed.password
        or parsed.fragment
    ):
        return None

    path = unquote(parsed.path)
    if path.startswith("/media/"):
        configured_host = urlparse(settings.public_api_url).netloc
        allowed_hosts = {configured_host} if configured_host else set()
        if not settings.is_production:
            allowed_hosts.update({"localhost", "localhost:8000", "localhost:8001", "127.0.0.1", "127.0.0.1:8000", "127.0.0.1:8001", "testserver"})
        if parsed.netloc not in allowed_hosts:
            return None
        key = path.removeprefix("/media/")
    else:
        legacy_host = urlparse(settings.r2_public_url).netloc
        if not legacy_host or parsed.netloc != legacy_host:
            return None
        key = path.lstrip("/")

    parts = PurePosixPath(key).parts
    if (
        len(parts) != 3
        or ".." in parts
        or parts[0] not in MEDIA_NAMESPACES
        or not parts[1]
        or not parts[2]
    ):
        return None
    if parsed.path.startswith("/media/"):
        signature = parse_qs(parsed.query).get("sig", [])
        if len(signature) != 1 or not hmac.compare_digest(
            signature[0], sign_media_key(key)
        ):
            return None
    elif parsed.query:
        return None
    return key


def owned_media_key(image_url: str, user_id: str) -> str | None:
    key = hosted_media_key(image_url)
    return key if key is not None and key_belongs_to_user(key, user_id) else None
