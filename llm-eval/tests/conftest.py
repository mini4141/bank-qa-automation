import json
import os
from pathlib import Path

import pytest

from harness import golden
from harness.chat_client import ChatClient
from harness.judge import Judge
from harness.report import write_reports

CONFIG = golden.config()


def pytest_addoption(parser):
    parser.addoption("--provider", default=os.environ.get("EVAL_PROVIDER", "mock"), choices=["mock", "bedrock"])
    parser.addoption("--chat-url", default=os.environ.get("CHAT_URL", "http://localhost:3003"))
    parser.addoption("--report-dir", default=os.environ.get("EVAL_REPORT_DIR", "../reports/llm-eval"))
    parser.addoption("--record-baseline", action="store_true", help="store current metrics as the provider baseline")


class Results:
    """Collects metrics and per-item details across the whole run."""

    def __init__(self):
        self.metrics: dict[str, float] = {}
        self.details: dict[str, list] = {}

    def record(self, metric: str, value: float, items: list) -> None:
        self.metrics[metric] = value
        self.details[metric] = items


@pytest.fixture(scope="session")
def provider(request) -> str:
    return request.config.getoption("--provider")


@pytest.fixture(scope="session")
def chat(request) -> ChatClient:
    return ChatClient(request.config.getoption("--chat-url"))


@pytest.fixture(scope="session")
def judge(provider) -> Judge:
    return Judge(provider)


@pytest.fixture(scope="session")
def results(request) -> Results:
    collected = Results()
    request.config._eval_results = collected
    return collected


@pytest.fixture(scope="session")
def thresholds() -> dict:
    return CONFIG["thresholds"]


def pytest_sessionfinish(session, exitstatus):
    results = getattr(session.config, "_eval_results", None)
    if results is None or not results.metrics:
        return
    provider = session.config.getoption("--provider")
    thresholds = dict(CONFIG["thresholds"])
    thresholds["latency_p95_ms"] = CONFIG["latency_p95_ms"][provider]
    write_reports(Path(session.config.getoption("--report-dir")), provider, results.metrics, thresholds, results.details)
    if session.config.getoption("--record-baseline"):
        baseline = Path(__file__).resolve().parent.parent / "baselines" / f"{provider}.json"
        keep = {k: round(results.metrics[k], 4) for k in CONFIG["drift"]["metrics"] if k in results.metrics}
        baseline.write_text(json.dumps(keep, indent=2) + "\n", encoding="utf-8")


@pytest.fixture(scope="session")
def qa_replies(chat) -> list[tuple[dict, "object"]]:
    """The golden Q&A set answered once and shared by the retrieval and faithfulness tests."""
    return [(item, chat.ask(item["question"])) for item in golden.load("qa")]
