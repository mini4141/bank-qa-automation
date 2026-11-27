"""Turn the Gatling assertion lines in a Maven log into Allure results (one test per assertion)."""
import json
import re
import sys
import time
import uuid
from pathlib import Path

log_path, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
out_dir.mkdir(parents=True, exist_ok=True)
pattern = re.compile(r"^(?P<name>.+?) : (?P<outcome>true|false) \(actual : (?P<actual>[\d.]+)\)\s*$", re.M)
now = int(time.time() * 1000)

for match in pattern.finditer(log_path.read_text(encoding="utf-8", errors="replace")):
    passed = match["outcome"] == "true"
    result = {
        "uuid": str(uuid.uuid4()),
        "name": f"Gatling assertion: {match['name']}",
        "fullName": f"perf.TransferSimulation.{match['name']}",
        "status": "passed" if passed else "failed",
        "statusDetails": {"message": f"actual value {match['actual']}"},
        "start": now,
        "stop": now,
        "labels": [{"name": "suite", "value": "performance"}, {"name": "feature", "value": "Gatling"}],
    }
    (out_dir / f"{result['uuid']}-result.json").write_text(json.dumps(result), encoding="utf-8")
    print(f"allure: {result['status']} {result['name']}")
