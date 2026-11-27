"""Compare the recorded mock baseline with the Bedrock baseline and print the metric deltas as JSON."""
import json
from pathlib import Path

baselines = Path(__file__).resolve().parent.parent / "llm-eval" / "baselines"
mock = json.loads((baselines / "mock.json").read_text())
bedrock = json.loads((baselines / "bedrock.json").read_text())
print(json.dumps({
    "mock": mock,
    "bedrock": bedrock,
    "delta_bedrock_minus_mock": {k: round(bedrock[k] - mock[k], 4) for k in mock if k in bedrock},
}, indent=2))
