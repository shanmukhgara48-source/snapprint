import asyncio
import hmac
import io
import os
import re
import time

import cv2
import numpy as np
import torch
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.responses import Response
from PIL import Image, ImageOps
from torchvision import transforms
from transformers import AutoModelForImageSegmentation


MODEL_ID = os.getenv("AI_MODEL_ID", "ZhengPeng7/BiRefNet_HR-matting")
MODEL_REVISION = os.getenv(
    "AI_MODEL_REVISION",
    "5d6b6f8adcb5b417c871b1d84ceaae9871355b7f",
)
SERVICE_TOKEN = os.getenv("AI_WORKER_TOKEN", "")
MAX_SOURCE_BYTES = int(os.getenv("AI_MAX_SOURCE_BYTES", str(50 * 1024 * 1024)))
MAX_SOURCE_PIXELS = int(os.getenv("AI_MAX_SOURCE_PIXELS", "50000000"))
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

if re.fullmatch(r"[0-9a-f]{40}", MODEL_REVISION) is None:
    raise RuntimeError("AI_MODEL_REVISION must be an immutable 40-character commit SHA.")

app = FastAPI(title="SnapPrint segmentation worker", docs_url=None, redoc_url=None)
_model = None
_model_lock = asyncio.Lock()
_inference_slots = asyncio.Semaphore(int(os.getenv("AI_WORKER_CONCURRENCY", "1")))


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "model": MODEL_ID,
        "device": DEVICE,
        "loaded": _model is not None,
    }


@app.post("/v1/segment")
async def segment(
    request: Request,
    authorization: str = Header(default=""),
    x_snapprint_quality: str = Header(default="high"),
    x_snapprint_refine_foreground: str = Header(default="true"),
    x_snapprint_preserve_alpha: str = Header(default="true"),
) -> Response:
    _authorize(authorization)
    data = await request.body()
    if not data or len(data) > MAX_SOURCE_BYTES:
        raise HTTPException(413, "Source image exceeds the worker limit.")
    started = time.perf_counter()
    async with _inference_slots:
        model = await _get_model()
        try:
            png, bounds = await asyncio.to_thread(
                _segment_sync,
                model,
                data,
                x_snapprint_quality == "high",
                x_snapprint_refine_foreground == "true",
                x_snapprint_preserve_alpha == "true",
            )
        except (OSError, ValueError) as exc:
            raise HTTPException(400, "Unsupported or corrupt image.") from exc
    elapsed = int((time.perf_counter() - started) * 1000)
    return Response(
        content=png,
        media_type="image/png",
        headers={
            "X-Model": MODEL_ID,
            "X-Processing-Ms": str(elapsed),
            "X-Subject-Bounds": ",".join(f"{value:.6f}" for value in bounds),
            "Cache-Control": "no-store",
        },
    )


def _authorize(value: str) -> None:
    expected = f"Bearer {SERVICE_TOKEN}"
    if not SERVICE_TOKEN or not hmac.compare_digest(value, expected):
        raise HTTPException(401, "Invalid service token.")


async def _get_model():
    global _model
    if _model is not None:
        return _model
    async with _model_lock:
        if _model is None:
            model = await asyncio.to_thread(
                AutoModelForImageSegmentation.from_pretrained,
                MODEL_ID,
                revision=MODEL_REVISION,
                trust_remote_code=True,
            )
            model.eval().to(DEVICE)
            if DEVICE == "cuda":
                model.half()
                torch.set_float32_matmul_precision("high")
            else:
                # Some checkpoints ship a fp16 torch_dtype in config.json, which
                # from_pretrained honors by default — CPU has no fp16 kernels for
                # conv2d, so force fp32 weights when not running on CUDA.
                model.float()
            _model = model
    return _model


def _segment_sync(
    model,
    data: bytes,
    high_quality: bool,
    refine_foreground: bool,
    preserve_alpha: bool,
) -> tuple[bytes, tuple[float, float, float, float]]:
    with Image.open(io.BytesIO(data)) as opened:
        dpi = opened.info.get("dpi")
        icc_profile = opened.info.get("icc_profile")
        oriented = ImageOps.exif_transpose(opened)
        existing_alpha = oriented.getchannel("A") if "A" in oriented.getbands() else None
        source = oriented.convert("RGB")
    if source.width * source.height > MAX_SOURCE_PIXELS:
        raise HTTPException(413, "Source dimensions exceed the worker limit.")

    input_size = 2048 if high_quality else 1024
    preprocess = transforms.Compose(
        [
            transforms.Resize((input_size, input_size)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
        ]
    )
    tensor = preprocess(source).unsqueeze(0).to(DEVICE)
    if DEVICE == "cuda":
        tensor = tensor.half()
    with torch.inference_mode():
        output = model(tensor)[-1].sigmoid()[0, 0]
    matte = (output.float().cpu().numpy() * 255).clip(0, 255).astype(np.uint8)
    matte_image = Image.fromarray(matte, "L").resize(source.size, Image.Resampling.LANCZOS)
    if preserve_alpha and existing_alpha is not None:
        matte_array = np.asarray(matte_image, dtype=np.uint16)
        existing = np.asarray(existing_alpha.resize(source.size), dtype=np.uint16)
        matte_image = Image.fromarray(((matte_array * existing) // 255).astype(np.uint8), "L")

    if refine_foreground:
        foreground = _estimate_foreground(source, matte_image)
    else:
        foreground = source
    result = foreground.convert("RGBA")
    result.putalpha(matte_image)
    bounds = _normalized_bounds(matte_image)

    buffer = io.BytesIO()
    kwargs = {"compress_level": 6}
    if isinstance(dpi, tuple) and len(dpi) == 2:
        kwargs["dpi"] = dpi
    if icc_profile:
        kwargs["icc_profile"] = icc_profile
    result.save(buffer, format="PNG", **kwargs)
    return buffer.getvalue(), bounds


def _estimate_foreground(image: Image.Image, matte: Image.Image) -> Image.Image:
    rgb = np.asarray(image, dtype=np.float32) / 255.0
    alpha_2d = np.asarray(matte, dtype=np.float32) / 255.0
    alpha = alpha_2d[:, :, None]

    def blur(value, radius):
        return cv2.blur(value, (radius, radius))

    foreground = rgb.copy()
    background = rgb.copy()
    for radius in (90, 6):
        blurred_alpha = blur(alpha_2d, radius)[:, :, None]
        foreground = blur(foreground * alpha, radius) / (blurred_alpha + 1e-5)
        background = blur(background * (1 - alpha), radius) / (1 - blurred_alpha + 1e-5)
        foreground = foreground + alpha * (
            rgb - alpha * foreground - (1 - alpha) * background
        )
        foreground = np.clip(foreground, 0, 1)
    return Image.fromarray((foreground * 255).astype(np.uint8), "RGB")


def _normalized_bounds(matte: Image.Image) -> tuple[float, float, float, float]:
    bounds = matte.point(lambda value: 255 if value > 8 else 0).getbbox()
    if not bounds:
        return (0, 0, 1, 1)
    left, top, right, bottom = bounds
    return (
        left / matte.width,
        top / matte.height,
        (right - left) / matte.width,
        (bottom - top) / matte.height,
    )
