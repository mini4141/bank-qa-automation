import json
from pathlib import Path

import allure
import pytest

from harness import golden

BASELINES = Path(__file__).resolve().parent.parent / "baselines"


@allure.feature("Drift")
def test_metrics_stay_within_tolerance_of_the_baseline(provider, results, request):
    """Compare each metric with baselines/<provider>.json; --record-baseline writes it instead."""
    if request.config.getoption("--record-baseline"):
        pytest.skip(f"recording a new baseline for {provider}")
    path = BASELINES / f"{provider}.json"
    assert path.exists(), f"no baseline for {provider}: run once with --record-baseline"
    baseline = json.loads(path.read_text())
    tolerance = golden.config()["drift"]["tolerance"]
    drift = {m: round(results.metrics[m] - v, 4) for m, v in baseline.items()}
    allure.attach(json.dumps(drift, indent=2), "metric delta vs baseline")
    results.record("max_abs_drift", max(abs(d) for d in drift.values()), [drift])
    assert all(abs(d) <= tolerance for d in drift.values()), drift
