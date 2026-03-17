#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="$1"
CLUSTER_NAME="$2"

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

nodes=($(kubectl get nodes --no-headers -o custom-columns=":metadata.name" | sort))
for i in "${!nodes[@]}"; do
  if [ "$i" -lt 3 ]; then
    echo "Labeling node '${nodes[$i]}' as coordinator-node"
    kubectl label node "${nodes[$i]}" role=coordinator-node --overwrite
  else
    echo "Labeling node '${nodes[$i]}' as data-node"
    kubectl label node "${nodes[$i]}" role=data-node --overwrite
  fi
done
