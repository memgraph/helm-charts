#!/usr/bin/env bash
set -euo pipefail

# Asserts that each chart pins --metrics-format to match the scrape path it
# deploys. The mg-exporter reads Memgraph's JSON endpoint, so a chart that
# leaves the flag unset breaks against Memgraph >= 3.12, where the server
# default became OpenMetrics.

STANDALONE="charts/memgraph"
HA="charts/memgraph-high-availability"

failures=0

count_flag() {
  local chart="$1" format="$2"
  shift 2
  helm template test "$chart" "$@" \
    | grep -c -- "^[[:space:]]*- \"--metrics-format=${format}\"" \
    || true
}

check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "ok       ${desc} (${actual})"
  else
    echo "NOT OK   ${desc}: expected ${expected}, got ${actual}" >&2
    failures=$((failures + 1))
  fi
}

# Standalone: one Memgraph pod.
check "standalone exporter path pins JSON" 1 \
  "$(count_flag "$STANDALONE" JSON --set prometheus.enabled=true)"
check "standalone direct path pins OpenMetrics" 1 \
  "$(count_flag "$STANDALONE" OpenMetrics --set scrapeMemgraphDirectly=true)"
check "standalone defaults pin nothing" 0 \
  "$(count_flag "$STANDALONE" '[A-Za-z]*')"

# HA: three coordinators plus two data instances.
check "HA exporter path pins JSON" 5 \
  "$(count_flag "$HA" JSON --set prometheus.enabled=true)"
check "HA direct path pins OpenMetrics" 5 \
  "$(count_flag "$HA" OpenMetrics --set scrapeMemgraphDirectly=true)"
check "HA defaults pin nothing" 0 \
  "$(count_flag "$HA" '[A-Za-z]*')"

# Direct scraping wins when a user enables both.
check "HA direct scraping takes precedence over the exporter" 5 \
  "$(count_flag "$HA" OpenMetrics --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"
check "HA does not also pin JSON when both are set" 0 \
  "$(count_flag "$HA" JSON --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"

if ((failures > 0)); then
  echo "${failures} metrics-format assertion(s) failed." >&2
  exit 1
fi

echo "All metrics-format assertions passed."
