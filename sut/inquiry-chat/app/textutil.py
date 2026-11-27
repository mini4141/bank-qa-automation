"""Tiny text helpers shared by the RAG service and the deterministic mock LLM."""
import re
from difflib import SequenceMatcher

STOPWORDS = frozenset(
    ["a", "an", "and", "are", "as", "at", "be", "by", "can", "do", "does", "for", "from", "how", "i", "if", "in", "is", "it", "me", "my", "of", "on", "or", "so", "the", "then", "there", "this", "to", "up", "was", "we", "what", "when", "where", "which", "who", "why", "will", "with", "you", "your", "please", "tell", "about", "get"]
)


def stem(word: str) -> str:
    return word[:-1] if len(word) > 3 and word.endswith("s") and not word.endswith("ss") else word


def tokens(text: str) -> list[str]:
    return [stem(w) for w in re.findall(r"[a-z0-9]+", text.lower()) if w not in STOPWORDS]


def fuzzy_match(a: str, b: str) -> bool:
    """True when two tokens are equal or close enough to be a typo of each other."""
    return a == b or (len(a) > 4 and len(b) > 4 and SequenceMatcher(None, a, b).ratio() >= 0.8)


def split_sentences(text: str) -> list[str]:
    parts = re.split(r"(?<=[.!?])\s+", " ".join(text.split()))
    return [p for p in parts if p]
