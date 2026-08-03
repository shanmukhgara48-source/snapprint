from argparse import Namespace

import numpy as np

from ai_worker.evaluate import _boundary_f1, _metrics, _release_gate


def test_perfect_alpha_prediction_scores_perfectly():
    target = np.zeros((16, 16), dtype=np.float32)
    target[4:12, 4:12] = 1

    metrics = _metrics(target.copy(), target)

    assert metrics == {"mae": 0.0, "mse": 0.0, "iou": 1.0, "boundary_f1": 1.0}


def test_alpha_metrics_detect_a_shifted_subject_boundary():
    target = np.zeros((32, 32), dtype=np.float32)
    prediction = np.zeros_like(target)
    target[8:24, 8:24] = 1
    prediction[8:24, 13:29] = 1

    metrics = _metrics(prediction, target)

    assert 0 < metrics["iou"] < 1
    assert metrics["mae"] > 0
    assert metrics["mse"] > 0
    assert _boundary_f1(prediction, target, tolerance=0) < 1


def test_release_gate_fails_a_weak_category_even_when_overall_passes():
    passing = {
        "mae": 0.01,
        "iou": 0.98,
        "boundary_f1": 0.95,
        "full_resolution_rate": 1,
        "latency_p95_ms": 1000,
    }
    weak = {**passing, "boundary_f1": 0.7}
    gate = _release_gate(
        {"overall": passing, "categories": {"portrait": passing, "pets": weak}},
        Namespace(max_mae=0.03, min_iou=0.95, min_boundary_f1=0.9, max_p95_ms=5000),
    )

    assert gate["passed"] is False
    assert gate["failures"] == [
        {
            "scope": "pets",
            "metric": "boundary_f1",
            "actual": 0.7,
            "threshold": 0.9,
        }
    ]
