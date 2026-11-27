"""LLM-as-judge for faithfulness, plus a citation-grounding fallback that needs no model."""
import json
import os
import re

JUDGE_SYSTEM = (
    "You are a strict faithfulness judge. You receive a CONTEXT and an ANSWER. "
    'Reply with JSON only: {"supported": true} if every claim in the ANSWER is supported by the CONTEXT, '
    'otherwise {"supported": false}.'
)

STOPWORDS = frozenset(
    "a an and are as at be by can do does for from how i if in is it me my of on or so the then there this "
    "to up was we what when where which who why will with you your please".split()
)


def content_words(text: str) -> set[str]:
    return {w.rstrip("s") for w in re.findall(r"[a-z0-9]+", text.lower()) if w not in STOPWORDS}


def citation_overlap(answer: str, cited_text: str) -> float:
    """Share of the answer's content words that appear in the cited documents."""
    words = content_words(re.sub(r"\[[a-z0-9-]+\]", "", answer))
    return len(words & content_words(cited_text)) / len(words) if words else 0.0


class Judge:
    def __init__(self, provider: str):
        self.provider = provider
        if provider == "bedrock":
            import boto3

            self.client = boto3.Session(profile_name=os.environ.get("AWS_PROFILE")).client(
                "bedrock-runtime", region_name=os.environ.get("AWS_REGION", "ap-southeast-2")
            )
            self.model = os.environ["BEDROCK_MODEL_ID"]
        else:
            from openai import OpenAI

            self.client = OpenAI(
                base_url=os.environ.get("LLM_BASE_URL", "http://localhost:3004/v1"),
                api_key=os.environ.get("LLM_API_KEY", "mock-key-not-a-secret"),
            )
            self.model = os.environ.get("LLM_MODEL", "mock-1")

    def supported(self, context: str, answer: str) -> bool | None:
        """True/False verdict, or None when the judge reply cannot be parsed."""
        user = f"CONTEXT:\n{context}\n\nANSWER:\n{answer}"
        if self.provider == "bedrock":
            res = self.client.converse(
                modelId=self.model,
                system=[{"text": JUDGE_SYSTEM}],
                messages=[{"role": "user", "content": [{"text": user}]}],
                inferenceConfig={"temperature": 0, "maxTokens": 100},
            )
            text = res["output"]["message"]["content"][0]["text"]
        else:
            res = self.client.chat.completions.create(
                model=self.model,
                temperature=0,
                messages=[{"role": "system", "content": JUDGE_SYSTEM}, {"role": "user", "content": user}],
            )
            text = res.choices[0].message.content or ""
        match = re.search(r"\{.*?\}", text, re.S)
        try:
            return bool(json.loads(match.group(0))["supported"]) if match else None
        except (ValueError, KeyError):
            return None
