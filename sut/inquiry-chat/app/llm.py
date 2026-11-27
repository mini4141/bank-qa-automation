"""LLM provider interface: an OpenAI-compatible endpoint (mock or real) or Amazon Bedrock."""
import json
import os
from typing import Protocol


class LLM(Protocol):
    def chat(self, messages: list[dict]) -> str: ...

    def embed(self, texts: list[str]) -> list[list[float]]: ...


class OpenAICompatLLM:
    def __init__(self, base_url: str, api_key: str, model: str, embedding_model: str):
        from openai import OpenAI

        self.client = OpenAI(base_url=base_url, api_key=api_key, max_retries=2, timeout=30)
        self.model = model
        self.embedding_model = embedding_model

    def chat(self, messages: list[dict]) -> str:
        res = self.client.chat.completions.create(model=self.model, messages=messages, temperature=0)
        return res.choices[0].message.content or ""

    def embed(self, texts: list[str]) -> list[list[float]]:
        res = self.client.embeddings.create(model=self.embedding_model, input=texts)
        return [d.embedding for d in res.data]


class BedrockLLM:
    """boto3 Converse for chat and Titan Text Embeddings v2 for vectors. Credentials come from the task role."""

    def __init__(self, region: str, model_id: str, embed_model_id: str):
        import boto3

        self.client = boto3.client("bedrock-runtime", region_name=region)
        self.model_id = model_id
        self.embed_model_id = embed_model_id

    def chat(self, messages: list[dict]) -> str:
        system = [{"text": m["content"]} for m in messages if m["role"] == "system"]
        convo = [{"role": m["role"], "content": [{"text": m["content"]}]} for m in messages if m["role"] != "system"]
        res = self.client.converse(
            modelId=self.model_id,
            system=system,
            messages=convo,
            inferenceConfig={"temperature": 0, "maxTokens": 400},
        )
        return res["output"]["message"]["content"][0]["text"]

    def embed(self, texts: list[str]) -> list[list[float]]:
        vectors = []
        for text in texts:
            res = self.client.invoke_model(
                modelId=self.embed_model_id,
                body=json.dumps({"inputText": text, "dimensions": 512, "normalize": True}),
            )
            vectors.append(json.loads(res["body"].read())["embedding"])
        return vectors


def from_env() -> LLM:
    provider = os.environ.get("LLM_PROVIDER", "mock")
    if provider == "bedrock":
        return BedrockLLM(
            os.environ.get("AWS_REGION", "ap-southeast-2"),
            os.environ["BEDROCK_MODEL_ID"],
            os.environ.get("BEDROCK_EMBED_MODEL_ID", "amazon.titan-embed-text-v2:0"),
        )
    return OpenAICompatLLM(
        os.environ.get("LLM_BASE_URL", "http://localhost:3004/v1"),
        os.environ.get("LLM_API_KEY", "mock-key-not-a-secret"),
        os.environ.get("LLM_MODEL", "mock-1"),
        os.environ.get("EMBEDDING_MODEL", "mock-hash-256"),
    )
