import asyncio
import json
import logging
import os
import sys
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel

from . import llm
from .rag import RagIndex

CORPUS = Path(os.environ.get("CORPUS_DIR", Path(__file__).resolve().parent.parent / "docs-corpus"))
PREFIX = os.environ.get("ROUTE_PREFIX", "")


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps({"level": record.levelname.lower(), "time": int(time.time() * 1000),
                           "name": record.name, "msg": record.getMessage()})


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=logging.INFO, handlers=[handler], force=True)
log = logging.getLogger("inquiry-chat")


@asynccontextmanager
async def lifespan(app: FastAPI):
    provider = llm.from_env()
    for attempt in range(1, 31):
        try:
            app.state.index = RagIndex(provider, CORPUS)
            break
        except Exception as exc:  # LLM or embeddings endpoint not ready yet
            log.warning("index build attempt %s failed: %s", attempt, type(exc).__name__)
            if attempt == 30:
                raise
            await asyncio.sleep(2)
    log.info("index ready with %s chunks", len(app.state.index.chunks))
    yield


class ChatRequest(BaseModel):
    question: str


app = FastAPI(title="inquiry-chat", lifespan=lifespan)


@app.get("/healthz")
def healthz():
    return {"status": "ok", "service": "inquiry-chat"}


@app.post(f"{PREFIX}/chat")
def chat(req: ChatRequest):
    if not req.question.strip():
        raise HTTPException(400, "question must not be empty")
    started = time.perf_counter()
    result = app.state.index.answer(req.question)
    log.info("chat answered in %.0f ms, citations=%s", (time.perf_counter() - started) * 1000,
             [c["docId"] for c in result["citations"]])
    return result


@app.get(f"{PREFIX}/docs/{{doc_id}}", response_class=PlainTextResponse)
def doc(doc_id: str):
    path = CORPUS / f"{doc_id}.md"
    if not path.is_file() or path.parent != CORPUS:
        raise HTTPException(404, "document not found")
    return path.read_text(encoding="utf-8")
