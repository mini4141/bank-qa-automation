#!/usr/bin/env bash
# Merge the Allure results of every suite into one HTML report with environment info and run history.
# Usage: scripts/report.sh [local|cloud]     Output: reports/allure-report
set -euo pipefail
cd "$(dirname "$0")/.."

env_name="${1:-local}"
merged=reports/allure-merged
out="${REPORT_OUT:-reports/allure-report}"
[ "$env_name" = "cloud" ] && out=reports/allure-report-cloud

rm -rf "$merged" && mkdir -p "$merged"
for dir in reports/allure-results/*/; do
  cp -r "$dir". "$merged"/
done

cat > "$merged/environment.properties" <<EOF
Environment=$env_name
Git.SHA=$(git rev-parse --short HEAD)
Git.Branch=$(git rev-parse --abbrev-ref HEAD)
Generated=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SUT.Bug.Rounding=${SUT_BUG_ROUNDING:-0}
EOF

# Trend history carried over from the previously published report (CI downloads it into reports/allure-history).
if [ -d reports/allure-history ]; then cp -r reports/allure-history "$merged/history"; fi

python scripts/update-history.py "$merged" reports/history.json
npx --yes allure-commandline@2.32.0 generate "$merged" -o "$out" --clean
cp reports/history.json "$out/history.json"
echo "report ready: $out/index.html"
