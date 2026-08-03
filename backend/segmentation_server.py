"""Local AI cutout worker — stands in for the private GPU segmentation
service that AI_SEGMENTATION_URL normally points to. Uses rembg (CPU,
u2net) instead of BiRefNet_HR-matting since that's what's easy to run
locally. Matches the contract in
app/services/professional_image_pipeline.py: raw image bytes in,
image/png with alpha out, same width/height as the source.

TODO: swap for the real BiRefNet_HR-matting worker before shipping.
"""

import io
import os
import time

from fastapi import FastAPI, HTTPException, Request, Response
from PIL import Image
from rembg import remove

SEGMENTATION_TOKEN = os.environ["AI_SEGMENTATION_TOKEN"]

app = FastAPI()


@app.post("/segment")
async def segment(request: Request) -> Response:
    auth = request.headers.get("authorization", "")
    if auth != f"Bearer {SEGMENTATION_TOKEN}":
        raise HTTPException(401, "Invalid segmentation token.")

    source_bytes = await request.body()
    with Image.open(io.BytesIO(source_bytes)) as src:
        width, height = src.size

    started = time.perf_counter()
    result_bytes = remove(source_bytes)

    with Image.open(io.BytesIO(result_bytes)) as out:
        if out.size != (width, height):
            out = out.resize((width, height))
            buf = io.BytesIO()
            out.save(buf, format="PNG")
            result_bytes = buf.getvalue()

    elapsed_ms = int((time.perf_counter() - started) * 1000)
    return Response(
        content=result_bytes,
        media_type="image/png",
        headers={"x-processing-ms": str(elapsed_ms), "x-model": "u2net (rembg, local CPU)"},
    )
