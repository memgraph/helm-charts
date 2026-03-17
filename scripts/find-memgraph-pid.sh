#!/bin/bash

# Finds the Memgraph PID for a given pod by exec-ing into a privileged debug pod,
# listing all memgraph processes, and matching against the pod's UID in cgroup info.
#
# Usage: ./find-memgraph-pid.sh <pod-name> [-d <debug-pod>] [-n <namespace>]
# Example: ./find-memgraph-pid.sh memgraph-data-1-0
# Example: ./find-memgraph-pid.sh memgraph-data-1-0 -d my-debug-pod -n memgraph

DEBUG_POD="debug"
NAMESPACE="default"

usage() {
  echo "Usage: $0 <pod-name> [-d <debug-pod>] [-n <namespace>]"
  echo ""
  echo "  <pod-name>       Name of the Memgraph pod to find the PID for"
  echo "  -d <debug-pod>   Name of the privileged debug pod (default: debug)"
  echo "  -n <namespace>   Kubernetes namespace (default: default)"
  exit 1
}

if [ -z "$1" ] || [[ "$1" == -* ]]; then
  usage
fi

POD_NAME="$1"
shift

while getopts "d:n:" opt; do
  case $opt in
    d) DEBUG_POD="$OPTARG" ;;
    n) NAMESPACE="$OPTARG" ;;
    *) usage ;;
  esac
done

# Get pod UID from pod name
POD_UID=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.uid}' 2>/dev/null)

if [ -z "$POD_UID" ]; then
  echo "Could not find pod '$POD_NAME' in namespace '$NAMESPACE'"
  exit 1
fi

# Extract a unique portion of the UID (last segment after last hyphen)
UID_FRAGMENT=$(echo "$POD_UID" | awk -F'-' '{print $NF}')

echo "Pod:          $POD_NAME"
echo "UID:          $POD_UID"
echo "UID fragment: $UID_FRAGMENT"
echo "Debug pod:    $DEBUG_POD"
echo ""

# Get all PIDs matching "memgraph" from inside the debug pod
PIDS=$(kubectl exec "$DEBUG_POD" -n "$NAMESPACE" -- ps -eo pid,comm 2>/dev/null | grep memgraph | grep -v grep | awk '{print $1}')

if [ -z "$PIDS" ]; then
  echo "No memgraph processes found in debug pod '$DEBUG_POD'."
  exit 1
fi

echo "Found memgraph PIDs: $(echo $PIDS | tr '\n' ' ')"

# Match PID to pod UID via cgroup
TARGET_PID=""
for PID in $PIDS; do
  MATCH=$(kubectl exec "$DEBUG_POD" -n "$NAMESPACE" -- grep -H "$UID_FRAGMENT" "/proc/$PID/cgroup" 2>/dev/null)
  if [ -n "$MATCH" ]; then
    TARGET_PID="$PID"
    echo "cgroup match: $MATCH"
    break
  fi
done

if [ -z "$TARGET_PID" ]; then
  echo "Could not match any memgraph process to pod UID $POD_UID"
  exit 1
fi
