#!/usr/bin/env bash
set -euo pipefail

# Asserts that each chart pins --metrics-format to match the scrape path it
# deploys. The mg-exporter reads Memgraph's JSON endpoint, so a chart that
# leaves the flag unset breaks against Memgraph 3.13 and later, where the
# server default is OpenMetrics.

STANDALONE="charts/memgraph"
HA="charts/memgraph-high-availability"

failures=0

count_flag() {
  local chart="$1" format="$2"
  shift 2
  local rendered
  # grep -c exits non-zero on no match, so the count needs `|| true`. Render into
  # a variable first: with the render inside the pipeline, that `|| true` would
  # also mask a helm failure and every "expect 0" assertion would pass against a
  # chart that does not render. Both charts are rendered once up front (below) so
  # a broken chart fails before any assertion runs.
  rendered="$(helm template test "$chart" "$@" 2>/dev/null)"
  grep -c -- "^[[:space:]]*- \"--metrics-format=${format}\"" <<<"$rendered" || true
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

# Fail loudly if either chart cannot render at all; the assertions below cannot
# distinguish "renders, pins nothing" from "did not render".
for chart in "$STANDALONE" "$HA"; do
  helm template test "$chart" >/dev/null
done

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

# Direct scraping wins when a user enables both. Asserted per chart: the two
# conditionals are separate and can regress independently.
check "standalone direct scraping takes precedence over the exporter" 1 \
  "$(count_flag "$STANDALONE" OpenMetrics --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"
check "standalone does not also pin JSON when both are set" 0 \
  "$(count_flag "$STANDALONE" JSON --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"
check "HA direct scraping takes precedence over the exporter" 5 \
  "$(count_flag "$HA" OpenMetrics --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"
check "HA does not also pin JSON when both are set" 0 \
  "$(count_flag "$HA" JSON --set scrapeMemgraphDirectly=true --set prometheus.enabled=true)"

# A user-set --metrics-format wins in the standalone chart; the HA chart rejects it.
check "standalone yields to a user-set flag" 0 \
  "$(count_flag "$STANDALONE" JSON --set prometheus.enabled=true --set-json 'memgraphConfig=["--metrics-format=OpenMetrics"]')"

if ((failures > 0)); then
  echo "${failures} metrics-format assertion(s) failed." >&2
  exit 1
fi

echo "All metrics-format assertions passed."
