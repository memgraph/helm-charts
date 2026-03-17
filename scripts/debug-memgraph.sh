#!/bin/bash
set -euo pipefail

POD=""
CONTAINER=""
NAMESPACE=""
IMAGE="${DEBUG_IMAGE:-ubuntu:22.04}"

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--container) CONTAINER="$2"; shift 2 ;;
        -n|--namespace) NAMESPACE="$2"; shift 2 ;;
        -i|--image)     IMAGE="$2"; shift 2 ;;
        -h|--help)
            cat <<'USAGE'
Usage: debug-memgraph.sh <pod-name> [-c container] [-n namespace] [-i image]

Attach a GDB debug container to a running Memgraph pod using kubectl debug.
The ephemeral container runs as root with SYS_PTRACE to enable GDB attach.

Options:
  -c, --container   Target container name (auto-detected from pod name)
  -n, --namespace   Kubernetes namespace
  -i, --image       Debug image (default: ubuntu:22.04, or DEBUG_IMAGE env var)
  -h, --help        Show this help

Examples:
  debug-memgraph.sh memgraph-data-0-0
  debug-memgraph.sh memgraph-coordinator-1-0 -n my-namespace
  DEBUG_IMAGE=ubuntu:24.04 debug-memgraph.sh memgraph-data-0-0

Requires: kubectl 1.32+, Kubernetes 1.25+
USAGE
            exit 0 ;;
        *) POD="$1"; shift ;;
    esac
done

if [[ -z "$POD" ]]; then
    echo "Error: pod name required. Run with -h for usage." >&2
    exit 1
fi

# Auto-detect container name from pod name
if [[ -z "$CONTAINER" ]]; then
    if [[ "$POD" == *"data"* ]]; then
        CONTAINER="memgraph-data"
    elif [[ "$POD" == *"coordinator"* ]]; then
        CONTAINER="memgraph-coordinator"
    else
        echo "Error: cannot detect container from pod name. Use -c." >&2
        exit 1
    fi
fi

# Create a custom profile to override pod-level securityContext.
# Memgraph pods run as non-root (uid 101), which prevents installing
# packages and using ptrace in the debug container. The custom profile
# sets runAsUser: 0 to run as root in the ephemeral container only.
CUSTOM_PROFILE=$(mktemp /tmp/memgraph-debug-profile.XXXXXX.json)
trap 'rm -f "$CUSTOM_PROFILE"' EXIT
cat > "$CUSTOM_PROFILE" <<'EOF'
{
  "securityContext": {
    "runAsUser": 0,
    "runAsGroup": 0,
    "runAsNonRoot": false
  }
}
EOF

KUBECTL_ARGS=(debug -it "$POD"
    --image="$IMAGE"
    --target="$CONTAINER"
    --profile=sysadmin
    --custom="$CUSTOM_PROFILE"
)
[[ -n "$NAMESPACE" ]] && KUBECTL_ARGS+=(-n "$NAMESPACE")

echo "Attaching debug container to $POD (target: $CONTAINER, image: $IMAGE)..."
kubectl "${KUBECTL_ARGS[@]}" -- bash -c '
    echo "=== GDB Debug Container ==="
    echo "Installing gdb and procps..."
    apt-get update -qq && apt-get install -y -qq gdb procps > /dev/null 2>&1
    MGPID=$(pgrep -x memgraph || true)
    if [ -n "$MGPID" ]; then
        echo "Memgraph PID: $MGPID"
        echo "Attaching GDB (process will continue running)..."
        echo "GDB will stop on crash/signal. Use \"bt\" for backtrace."
        gdb -p "$MGPID" -ex continue
    else
        echo "Warning: memgraph process not found. Use: ps aux"
        exec bash
    fi
'
