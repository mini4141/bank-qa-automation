import time
from dataclasses import dataclass, field

import httpx

REFUSAL_MARKERS = ("don't know", "do not know", "cannot find", "can't find", "not covered", "contact support")


@dataclass
class Reply:
    question: str
    answer: str
    cited_docs: list[str]
    retrieved: list[str]
    latency_ms: float
    sources: dict[str, str] = field(default_factory=dict)

    @property
    def refused(self) -> bool:
        return any(marker in self.answer.lower() for marker in REFUSAL_MARKERS)


class ChatClient:
    """Calls the deployed inquiry-chat service exactly as the web app does."""

    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip("/")
        self.http = httpx.Client(timeout=60)
        self.latencies: list[float] = []

    def ask(self, question: str) -> Reply:
        started = time.perf_counter()
        res = self.http.post(f"{self.base_url}/chat", json={"question": question})
        latency = (time.perf_counter() - started) * 1000
        res.raise_for_status()
        body = res.json()
        self.latencies.append(latency)
        return Reply(
            question=question,
            answer=body["answer"],
            cited_docs=[c["docId"] for c in body["citations"]],
            retrieved=body["retrieved"],
            latency_ms=latency,
        )

    def document(self, doc_id: str) -> str:
        res = self.http.get(f"{self.base_url}/docs/{doc_id}")
        res.raise_for_status()
        return res.text
