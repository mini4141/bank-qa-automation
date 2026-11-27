from pathlib import Path

from fastapi.testclient import TestClient

from app import mock_llm
from app.rag import RagIndex

CORPUS = Path(__file__).resolve().parents[2] / "docs-corpus"


class InProcessLLM:
    """Calls the mock functions directly, so the unit test needs no network."""

    def chat(self, messages):
        return mock_llm.answer_from_context(messages[0]["content"], messages[1]["content"])

    def embed(self, texts):
        return [mock_llm.embed(t) for t in texts]


def test_answer_cites_the_right_document():
    result = RagIndex(InProcessLLM(), CORPUS).answer("How long is a cardless ATM code valid?")
    assert result["citations"][0]["docId"] == "cardless-atm"
    assert "30 minutes" in result["answer"]


def test_out_of_corpus_question_gets_a_refusal():
    result = RagIndex(InProcessLLM(), CORPUS).answer("What is the weather in Paris today?")
    assert result["citations"] == []
    assert "don't know" in result["answer"]


def test_mock_embeddings_endpoint_is_openai_shaped():
    res = TestClient(mock_llm.app).post("/v1/embeddings", json={"model": "m", "input": ["hello", "world"]})
    assert [d["index"] for d in res.json()["data"]] == [0, 1]
    assert len(res.json()["data"][0]["embedding"]) == mock_llm.DIMENSIONS
