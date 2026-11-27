"""Append this run to reports/history.json (used by the MCP list_flaky_tests tool). Keeps the last 30 runs."""
import json
import os
import sys
import time
from pathlib import Path

merged = Path(sys.argv[1])
history_file = Path(sys.argv[2])
runs = json.loads(history_file.read_text()) if history_file.exists() else []

results = {}
for file in merged.glob("*-result.json"):
    data = json.loads(file.read_text(encoding="utf-8"))
    results[data.get("fullName") or data["name"]] = data["status"]

runs.append({
    "runId": os.environ.get("GITHUB_RUN_ID", str(int(time.time()))),
    "sha": os.environ.get("GITHUB_SHA", "local")[:7],
    "results": results,
})
history_file.write_text(json.dumps(runs[-30:], indent=1), encoding="utf-8")
print(f"history: {len(results)} results recorded, {len(runs[-30:])} runs kept")
