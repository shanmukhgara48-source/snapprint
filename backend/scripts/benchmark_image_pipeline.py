"""Reproducible CPU benchmark for SnapPrint's final full-resolution render."""

import io
import json
import resource
import sys
import time

import numpy as np
from PIL import Image

from app.schemas.ai_editor import (
    AiExportRequest,
    EditorAdjustments,
    EditorBackground,
    EditorTransform,
    NormalizedRect,
)
from app.services.professional_image_pipeline import ImageAsset, _render_export


def main() -> None:
    width, height = 4000, 3000
    x = np.linspace(0, 255, width, dtype=np.uint8)
    y = np.linspace(0, 255, height, dtype=np.uint8)[:, None]
    rgb = np.empty((height, width, 3), dtype=np.uint8)
    rgb[..., 0] = x
    rgb[..., 1] = y
    rgb[..., 2] = ((x[None, :] // 2) + (y // 2)).astype(np.uint8)
    source_buffer = io.BytesIO()
    Image.fromarray(rgb, "RGB").save(
        source_buffer,
        format="JPEG",
        quality=95,
        subsampling=0,
        dpi=(300, 300),
    )
    source = ImageAsset(
        data=source_buffer.getvalue(),
        mime_type="image/jpeg",
        width=width,
        height=height,
        dpi=(300, 300),
        icc_profile=None,
    )
    request = AiExportRequest(
        image_url="https://benchmark.invalid/source.jpg",
        background=EditorBackground(kind="solid", color="#FFFFFF"),
        adjustments=EditorAdjustments(
            exposure=0.15,
            temperature=0.08,
            shadows=0.12,
            highlights=-0.08,
            vibrance=0.12,
            sharpness=0.25,
        ),
        transform=EditorTransform(
            crop=NormalizedRect(left=0.05, top=0.05, width=0.9, height=0.9),
            straighten_degrees=1.25,
        ),
    )

    started = time.perf_counter()
    rendered, mime_type, _ = _render_export(source, request, None)
    elapsed = time.perf_counter() - started
    with Image.open(io.BytesIO(rendered)) as output:
        output_size = output.size
    peak_rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    peak_rss_bytes = peak_rss if sys.platform == "darwin" else peak_rss * 1024
    print(
        json.dumps(
            {
                "input_megapixels": width * height / 1_000_000,
                "input_bytes": len(source.data),
                "output_dimensions": output_size,
                "output_bytes": len(rendered),
                "mime_type": mime_type,
                "elapsed_ms": round(elapsed * 1000, 1),
                "process_peak_rss_mb": round(peak_rss_bytes / 1024 / 1024, 1),
                "throughput_megapixels_per_second": round(
                    (width * height / 1_000_000) / elapsed,
                    2,
                ),
            }
        )
    )


if __name__ == "__main__":
    main()
