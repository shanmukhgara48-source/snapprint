# SnapPrint segmentation worker

Private GPU service for print-quality background removal. It runs the official
MIT-licensed `ZhengPeng7/BiRefNet_HR-matting` weights at 2048px, resizes the
continuous alpha matte back to the source dimensions, applies foreground color
estimation to reduce edge spill, and returns a full-resolution PNG.

## Deployment

Build the pinned PyTorch 2.13/CUDA 12.6 Docker image on an NVIDIA runtime with
at least 8 GB VRAM. Set:

- `AI_WORKER_TOKEN`: random service-to-service secret.
- `AI_MODEL_REVISION`: a reviewed 40-character Hugging Face commit SHA for
  reproducible and supply-chain-safe deploys. The bundled default pins the
  model snapshot reviewed on 2026-08-02; update it deliberately after running
  the release evaluation.
- `AI_WORKER_CONCURRENCY=1`: keep one inference in flight per GPU unless the
  selected hardware has been load-tested.

Point the main API's `AI_SEGMENTATION_URL` at `/v1/segment` and use the same
token in `AI_SEGMENTATION_TOKEN`. Keep the worker on a private network; only the
main FastAPI service should reach it.

The first request downloads and warms the model. Production images should bake
the pinned Hugging Face snapshot into the container or attach a persistent model
cache so cold starts do not depend on a public network.

## Release evaluation

Run `evaluate.py` against a private, consented validation set before deploying a
new model revision. The manifest is a JSON array:

```json
[
  {
    "name": "portrait-curly-hair-01",
    "category": "portrait",
    "image": "images/portrait-curly-hair-01.jpg",
    "mask": "masks/portrait-curly-hair-01.png"
  }
]
```

Ground-truth masks may be grayscale images or PNG alpha channels. Include
portraits, groups, pets, transparent objects, dark and white backgrounds,
complex scenes, high- and low-resolution inputs, and every supported source
format. The report includes alpha MAE/MSE, binary IoU, boundary F1,
full-resolution preservation, and p50/p95 end-to-end latency by category. The
command exits non-zero if the overall set or any category exceeds 0.03 MAE,
falls below 0.95 IoU or 0.90 boundary F1, changes source dimensions, or exceeds
5 seconds p95. Thresholds can be overridden explicitly for a measured hardware
target, but production changes should never silently relax them.

```bash
python evaluate.py validation/manifest.json \
  --url http://127.0.0.1:8090/v1/segment \
  --token "$AI_WORKER_TOKEN" \
  --output validation/report.json
```
