#!/bin/bash -e

RESOURCE_GROUP="${RESOURCE_GROUP:-TestingResourceGroup}"
LOCATION="${LOCATION:-northeurope}"
CLUSTER_NAME="${CLUSTER_NAME:-memgraph-standalone}"
CLUSTER_SIZE="${CLUSTER_SIZE:-1}"
NODE_VM_SIZE="${NODE_VM_SIZE:-Standard_A2_v2}"

# NOTE: Assumes installed az and being logged in.

create_cluster() {
  az group create --name $RESOURCE_GROUP --location $LOCATION
  az aks create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME \
    --node-count $CLUSTER_SIZE --node-vm-size $NODE_VM_SIZE --generate-ssh-keys
  az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
}

delete_cluster() {
  az group delete --name $RESOURCE_GROUP --yes
}

case $1 in
  create)
    create_cluster
  ;;
  delete)
    delete_cluster
  ;;
  *)
    echo "$0 create|delete"
    exit 1
  ;;
esac
