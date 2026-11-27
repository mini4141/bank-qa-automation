import html
import json
from pathlib import Path


def write_reports(out_dir: Path, provider: str, metrics: dict, thresholds: dict, details: dict) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    document = {"provider": provider, "metrics": metrics, "thresholds": thresholds, "details": details}
    (out_dir / "report.json").write_text(json.dumps(document, indent=2), encoding="utf-8")

    rows = []
    for name, value in metrics.items():
        limit = thresholds.get(name)
        if limit is None:
            status, shown = "info", "-"
        else:
            passed = value <= limit if name.startswith("latency") else value >= limit
            status, shown = ("pass" if passed else "fail"), str(limit)
        rows.append(f"<tr class='{status}'><td>{html.escape(name)}</td><td>{value:.3f}</td><td>{shown}</td><td>{status}</td></tr>")
    page = f"""<!doctype html><meta charset="utf-8"><title>LLM evaluation - {html.escape(provider)}</title>
<style>body{{font-family:system-ui;margin:2rem}}table{{border-collapse:collapse}}td,th{{border:1px solid #ccc;padding:6px 12px}}
tr.pass td:last-child{{color:#067647;font-weight:600}}tr.fail td:last-child{{color:#b42318;font-weight:600}}</style>
<h1>LLM evaluation summary</h1><p>Provider: <b>{html.escape(provider)}</b></p>
<table data-testid="metrics"><tr><th>Metric</th><th>Value</th><th>Threshold</th><th>Status</th></tr>{''.join(rows)}</table>
<h2>Items</h2><pre>{html.escape(json.dumps(details, indent=2))}</pre>"""
    (out_dir / "report.html").write_text(page, encoding="utf-8")
