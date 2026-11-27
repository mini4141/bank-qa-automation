"""Deterministic OpenAI-compatible mock: hash embeddings plus an extractive answerer and judge.

Run with: uvicorn app.mock_llm:app --port 3004
"""
import hashlib
import json
import math
import re
import time

from fastapi import FastAPI, Request

from .textutil import fuzzy_match, split_sentences, tokens

DIMENSIONS = 256
IDK = "I don't know based on our documents. Please contact support."
INJECTION = re.compile(r"ignore|disregard|forget|reveal|system prompt|instructions|pwned", re.IGNORECASE)

app = FastAPI(title="mock-llm")


def _bucket(feature: str) -> tuple[int, float]:
    digest = hashlib.md5(feature.encode()).digest()
    return int.from_bytes(digest[:4], "big") % DIMENSIONS, 1.0 if digest[4] % 2 else -1.0


def embed(text: str) -> list[float]:
    """Hashed bag of words plus character trigrams, so typos still land near the right chunk."""
    vec = [0.0] * DIMENSIONS
    for word in tokens(text):
        index, sign = _bucket("w:" + word)
        vec[index] += 2.0 * sign
        padded = f"^{word}$"
        for i in range(len(padded) - 2):
            index, sign = _bucket("c:" + padded[i : i + 3])
            vec[index] += sign
    norm = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [v / norm for v in vec]


def _coverage(question_tokens: list[str], sentence_tokens: list[str]) -> int:
    return sum(1 for q in question_tokens if any(fuzzy_match(q, s) for s in sentence_tokens))


def answer_from_context(system: str, question: str) -> str:
    safe_question = " ".join(s for s in split_sentences(question) if not INJECTION.search(s))
    q_tokens = tokens(safe_question)
    context = system.split("CONTEXT:", 1)[-1]
    best: tuple[float, int, str, str] = (0.0, 0, "", "")
    for doc_id, header, body in re.findall(r"^\[([a-z0-9-]+)\] (.*?)\n(.*?)(?=^\[[a-z0-9-]+\] |\Z)", context, re.MULTILINE | re.DOTALL):
        header_tokens = tokens(header)
        for sentence in split_sentences(body):
            matched = _coverage(q_tokens, tokens(sentence) + header_tokens)
            score = matched / len(q_tokens) if q_tokens else 0.0
            if (score, matched) > best[:2]:
                best = (score, matched, doc_id, sentence)
    score, matched, doc_id, sentence = best
    if matched < 2 or score < 0.4:
        return IDK
    return f"{sentence} [{doc_id}]"


def judge(user: str) -> str:
    """Faithfulness judge: every answer sentence must be mostly covered by the context."""
    context, _, answer = user.partition("ANSWER:")
    context_tokens = tokens(context)
    sentences = [s for s in split_sentences(re.sub(r"\[[a-z0-9-]+\]", "", answer)) if tokens(s)]
    supported = bool(sentences) and all(
        _coverage(tokens(s), context_tokens) / len(tokens(s)) >= 0.6 for s in sentences
    )
    return json.dumps({"supported": supported})


@app.get("/healthz")
def healthz():
    return {"status": "ok", "service": "mock-llm"}


@app.post("/v1/embeddings")
async def embeddings(request: Request):
    body = await request.json()
    texts = body["input"] if isinstance(body["input"], list) else [body["input"]]
    return {
        "object": "list",
        "model": body.get("model", "mock-hash-256"),
        "data": [{"object": "embedding", "index": i, "embedding": embed(t)} for i, t in enumerate(texts)],
        "usage": {"prompt_tokens": 0, "total_tokens": 0},
    }


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body = await request.json()
    system = next((m["content"] for m in body["messages"] if m["role"] == "system"), "")
    user = next((m["content"] for m in reversed(body["messages"]) if m["role"] == "user"), "")
    content = judge(user) if "faithfulness judge" in system else answer_from_context(system, user)
    return {
        "id": "chatcmpl-mock",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": body.get("model", "mock-1"),
        "choices": [{"index": 0, "finish_reason": "stop", "message": {"role": "assistant", "content": content}}],
        "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    }
