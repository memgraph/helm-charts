# Deploying Memgraph under GCP's GKE

To deploy cluster follow https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster.

To install `gcloud` follow https://cloud.google.com/sdk/docs/install-sdk.

```
gcloud container clusters create "memgraph-ha" \
    --zone "europe-west2-a" \
    --num-nodes 5 \
    --machine-type "e2-medium"
```

```
gcloud container node-pools list --cluster "memgraph-ha" --zone "europe-west2-a"
```

```
gcloud container clusters get-credentials "memgraph" --zone europe-central
```

```
gcloud container clusters list
```

```
gcloud compute ssh <node-name>
```
