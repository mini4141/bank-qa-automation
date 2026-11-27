import statistics

import allure

from harness import golden


@allure.feature("Performance")
def test_chat_latency_p95(chat, provider, results):
    """p95 of every chat call made so far in this run stays within the provider budget."""
    ordered = sorted(chat.latencies)
    p95 = ordered[min(len(ordered) - 1, int(len(ordered) * 0.95))]
    results.record("latency_p95_ms", p95, [{"calls": len(ordered), "median_ms": round(statistics.median(ordered), 1)}])
    assert p95 <= golden.config()["latency_p95_ms"][provider]
