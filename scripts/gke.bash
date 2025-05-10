#!/bin/bash -e

CLUSTER_NAME="${CLUSTER_NAME:-memgraph-standalone}"
ZONE="${ZONE:-europe-west2-a}"
CLUSTER_SIZE="${CLUSTER_SIZE:-1}"
MACHINE_TYPE="${MACHINE_TYPE:-e2-medium}"

# NOTE: Assumes installed gcloud (https://cloud.google.com/sdk/docs/install)
# and init/login done.

create_cluster() {
  gcloud container clusters create "$CLUSTER_NAME" \
    --zone "$ZONE" \
    --num-nodes $CLUSTER_SIZE \
    --machine-type "$MACHINE_TYPE"
  gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE"
}

delete_cluster() {
  gcloud container clusters delete $CLUSTER_NAME --location $ZONE
}

list_clusters() {
  gcloud container clusters list
}

get_nodes() {
  gcloud container node-pools list --cluster "$CLUSTER_NAME" --zone "$ZONE"
}

case $1 in
  create_cluster)
    create_cluster
  ;;
  delete_cluster)
    delete_cluster
  ;;
  list_clusters)
    list_clusters
  ;;
  get_nodes)
    get_nodes
  ;;
  *)
    echo "$0 create_cluster|delete_cluster|list_clusters|get_nodes"
    exit 1
  ;;
esac
