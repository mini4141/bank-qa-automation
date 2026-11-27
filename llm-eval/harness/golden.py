import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent


def load(name: str) -> list[dict]:
    path = ROOT / "golden" / f"{name}.jsonl"
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def config() -> dict:
    return yaml.safe_load((ROOT / "config.yaml").read_text(encoding="utf-8"))
