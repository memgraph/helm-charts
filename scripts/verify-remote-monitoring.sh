#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME=""
SAMPLE_POD=""
SAMPLE_NAMESPACE="default"
SAMPLE_CONTAINER="memgraph-vector"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service-name)
      SERVICE_NAME="$2"
      shift 2
      ;;
    --sample-pod)
      SAMPLE_POD="$2"
      shift 2
      ;;
    --sample-namespace)
      SAMPLE_NAMESPACE="$2"
      shift 2
      ;;
    --sample-container)
      SAMPLE_CONTAINER="$2"
      shift 2
      ;;
    -h|--help)
      cat <<'EOF'
Usage: verify-remote-monitoring.sh --service-name <name> --sample-pod <pod> [options]

Verifies remote_write metrics and log push ingestion via the monitoring gateway.

Required:
  --service-name      Label value used for service_name in the metrics query
  --sample-pod        Pod name to print sample vector sidecar logs from

Optional:
  --sample-namespace  Namespace for sample pod logs (default: default)
  --sample-container  Container for sample pod logs (default: memgraph-vector)
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SERVICE_NAME" || -z "$SAMPLE_POD" ]]; then
  echo "Error: --service-name and --sample-pod are required." >&2
  exit 1
fi

# Escape label value for use inside URL query parameters.
SERVICE_NAME_ESCAPED="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$SERVICE_NAME")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

kubectl wait -n remote-monitoring --for=condition=available deployment/monitoring-gateway --timeout=180s

kubectl port-forward -n remote-monitoring svc/monitoring-gateway 18080:80 >/tmp/pf-gateway.log 2>&1 &
PF_GATEWAY_PID=$!
kubectl port-forward -n remote-monitoring svc/victoria-logs 19428:9428 >/tmp/pf-vlogs.log 2>&1 &
PF_VLOGS_PID=$!
trap 'kill "$PF_GATEWAY_PID" "$PF_VLOGS_PID" >/dev/null 2>&1 || true' EXIT
sleep 5

echo -e "${BLUE}Checking remote_write metrics ingestion...${NC}"
for i in $(seq 1 40); do
  resp="$(curl -s -u ci-monitor:ci-monitor-pass "http://127.0.0.1:18080/api/v1/query?query=count(up%7Bjob%3D%22memgraph-exporter%22%2Cservice_name%3D%22${SERVICE_NAME_ESCAPED}%22%7D)")"
  val="$(python3 -c 'import json,sys; r=json.loads(sys.argv[1]).get("data",{}).get("result",[]); print("0" if not r else r[0]["value"][1])' "$resp" 2>/dev/null || echo 0)"
  if python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$val"; then
    echo -e "${GREEN}Metrics are ingested (matching series: ${val}).${NC}"
    break
  fi
  if [[ "$i" -eq 40 ]]; then
    echo -e "${RED}Timed out waiting for remote metrics ingestion.${NC}"
    exit 1
  fi
  echo -e "${YELLOW}Metrics not ingested yet (attempt ${i}/40, value=${val}).${NC}"
  sleep 10
done

echo -e "${BLUE}Checking Loki push traffic on VictoriaLogs...${NC}"
for i in $(seq 1 40); do
  log_push_total="$(curl -s http://127.0.0.1:19428/metrics | awk '/\/insert\/loki\/api\/v1\/push/ { sum += ($NF+0) } END { print sum+0 }')"
  if python3 -c 'import sys; sys.exit(0 if float(sys.argv[1]) > 0 else 1)' "$log_push_total"; then
    echo -e "${GREEN}Logs are ingested (Loki push metric sum: ${log_push_total}).${NC}"
    echo -e "${BLUE}Sample gateway access logs (Loki push path):${NC}"
    kubectl logs -n remote-monitoring deploy/monitoring-gateway --tail=50 | grep '/loki/api/v1/push' || true
    echo -e "${BLUE}Sample Memgraph vector sidecar logs:${NC}"
    kubectl logs -n "$SAMPLE_NAMESPACE" "$SAMPLE_POD" -c "$SAMPLE_CONTAINER" --tail=20 || true
    break
  fi
  if [[ "$i" -eq 40 ]]; then
    echo -e "${RED}Timed out waiting for log ingestion.${NC}"
    exit 1
  fi
  echo -e "${YELLOW}Logs not ingested yet (attempt ${i}/40, push sum=${log_push_total}).${NC}"
  sleep 10
done
