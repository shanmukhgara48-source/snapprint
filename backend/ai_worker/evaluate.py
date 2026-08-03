"""Evaluate the running segmentation worker against labeled alpha mattes."""

import argparse
import io
import json
import statistics
import sys
import time
from collections import defaultdict
from pathlib import Path
from urllib.request import Request, urlopen

import numpy as np
from PIL import Image, ImageOps


def _load_alpha(path: Path) -> np.ndarray:
    with Image.open(path) as opened:
        image = ImageOps.exif_transpose(opened)
        channel = image.getchannel("A") if "A" in image.getbands() else image.convert("L")
        return np.asarray(channel, dtype=np.float32) / 255.0


def _boundary_f1(prediction: np.ndarray, target: np.ndarray, tolerance: int = 2) -> float:
    pred = (prediction >= 0.5).astype(np.uint8)
    truth = (target >= 0.5).astype(np.uint8)
    pred_edge = _binary_edge(pred)
    truth_edge = _binary_edge(truth)
    pred_near = _dilate(pred_edge, tolerance)
    truth_near = _dilate(truth_edge, tolerance)
    pred_count = int(pred_edge.sum())
    truth_count = int(truth_edge.sum())
    if pred_count == 0 and truth_count == 0:
        return 1.0
    precision = float((pred_edge * truth_near).sum()) / max(1, pred_count)
    recall = float((truth_edge * pred_near).sum()) / max(1, truth_count)
    return 2 * precision * recall / max(1e-8, precision + recall)


def _binary_edge(mask: np.ndarray) -> np.ndarray:
    padded = np.pad(mask, 1, mode="edge")
    center = padded[1:-1, 1:-1]
    edge = np.zeros_like(mask)
    for y in range(3):
        for x in range(3):
            edge |= center != padded[y : y + mask.shape[0], x : x + mask.shape[1]]
    return edge.astype(np.uint8)


def _dilate(mask: np.ndarray, tolerance: int) -> np.ndarray:
    if tolerance <= 0:
        return mask
    padded = np.pad(mask, tolerance, mode="constant")
    dilated = np.zeros_like(mask)
    for y in range(tolerance * 2 + 1):
        for x in range(tolerance * 2 + 1):
            dilated |= padded[
                y : y + mask.shape[0], x : x + mask.shape[1]
            ]
    return dilated


def _metrics(prediction: np.ndarray, target: np.ndarray) -> dict[str, float]:
    if prediction.shape != target.shape:
        raise ValueError(
            f"Worker changed dimensions: predicted {prediction.shape}, expected {target.shape}."
        )
    pred_binary = prediction >= 0.5
    target_binary = target >= 0.5
    intersection = np.logical_and(pred_binary, target_binary).sum()
    union = np.logical_or(pred_binary, target_binary).sum()
    difference = prediction - target
    return {
        "mae": float(np.abs(difference).mean()),
        "mse": float(np.square(difference).mean()),
        "iou": float(intersection / union) if union else 1.0,
        "boundary_f1": _boundary_f1(prediction, target),
    }


def _segment(url: str, token: str, source: Path) -> tuple[bytes, float]:
    request = Request(
        url,
        data=source.read_bytes(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": _mime_type(source),
            "Accept": "image/png",
            "X-SnapPrint-Quality": "high",
            "X-SnapPrint-Refine-Foreground": "true",
            "X-SnapPrint-Preserve-Alpha": "true",
        },
        method="POST",
    )
    started = time.perf_counter()
    with urlopen(request, timeout=180) as response:
        output = response.read()
    return output, (time.perf_counter() - started) * 1000


def _mime_type(path: Path) -> str:
    return {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(path.suffix.lower(), "application/octet-stream")


def _summary(rows: list[dict]) -> dict:
    by_category: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        by_category[row["category"]].append(row)

    def aggregate(items: list[dict]) -> dict:
        latencies = sorted(item["latency_ms"] for item in items)
        p95_index = min(len(latencies) - 1, round((len(latencies) - 1) * 0.95))
        return {
            "count": len(items),
            "mae": round(statistics.fmean(item["mae"] for item in items), 6),
            "mse": round(statistics.fmean(item["mse"] for item in items), 6),
            "iou": round(statistics.fmean(item["iou"] for item in items), 6),
            "boundary_f1": round(
                statistics.fmean(item["boundary_f1"] for item in items), 6
            ),
            "latency_p50_ms": round(statistics.median(latencies), 1),
            "latency_p95_ms": round(latencies[p95_index], 1),
            "full_resolution_rate": round(
                statistics.fmean(item["full_resolution"] for item in items), 6
            ),
        }

    return {
        "overall": aggregate(rows),
        "categories": {
            category: aggregate(items) for category, items in sorted(by_category.items())
        },
        "samples": rows,
    }


def _release_gate(report: dict, args: argparse.Namespace) -> dict:
    failures = []
    scopes = {"overall": report["overall"], **report["categories"]}
    for name, metrics in scopes.items():
        checks = (
            ("mae", metrics["mae"] <= args.max_mae, args.max_mae),
            ("iou", metrics["iou"] >= args.min_iou, args.min_iou),
            (
                "boundary_f1",
                metrics["boundary_f1"] >= args.min_boundary_f1,
                args.min_boundary_f1,
            ),
            (
                "full_resolution_rate",
                metrics["full_resolution_rate"] == 1,
                1,
            ),
            (
                "latency_p95_ms",
                metrics["latency_p95_ms"] <= args.max_p95_ms,
                args.max_p95_ms,
            ),
        )
        for metric, passed, threshold in checks:
            if not passed:
                failures.append(
                    {
                        "scope": name,
                        "metric": metric,
                        "actual": metrics[metric],
                        "threshold": threshold,
                    }
                )
    return {
        "passed": not failures,
        "thresholds": {
            "max_mae": args.max_mae,
            "min_iou": args.min_iou,
            "min_boundary_f1": args.min_boundary_f1,
            "full_resolution_rate": 1,
            "max_p95_ms": args.max_p95_ms,
        },
        "failures": failures,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--url", default="http://127.0.0.1:8090/v1/segment")
    parser.add_argument("--token", required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--max-mae", type=float, default=0.03)
    parser.add_argument("--min-iou", type=float, default=0.95)
    parser.add_argument("--min-boundary-f1", type=float, default=0.90)
    parser.add_argument("--max-p95-ms", type=float, default=5000)
    args = parser.parse_args()

    root = args.manifest.parent
    samples = json.loads(args.manifest.read_text())
    rows = []
    for sample in samples:
        image_path = root / sample["image"]
        mask_path = root / sample["mask"]
        with Image.open(image_path) as source:
            source_size = ImageOps.exif_transpose(source).size
        output, latency_ms = _segment(args.url, args.token, image_path)
        with Image.open(io.BytesIO(output)) as predicted:
            output_size = predicted.size
            alpha = np.asarray(predicted.getchannel("A"), dtype=np.float32) / 255.0
        row = {
            "name": sample.get("name", image_path.stem),
            "category": sample["category"],
            "latency_ms": round(latency_ms, 1),
            "full_resolution": int(output_size == source_size),
            **_metrics(alpha, _load_alpha(mask_path)),
        }
        rows.append(row)

    summary = _summary(rows)
    summary["release_gate"] = _release_gate(summary, args)
    report = json.dumps(summary, indent=2)
    if args.output:
        args.output.write_text(report + "\n")
    print(report)
    if not summary["release_gate"]["passed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
