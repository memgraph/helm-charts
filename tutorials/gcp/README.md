# Deploying Memgraph under GCP's GKE

To deploy cluster follow
https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster.

To install `gcloud` follow https://cloud.google.com/sdk/docs/install-sdk. In
addition, `gke-gcloud-auth-plugin` is required, to install it run:
```
gcloud components install kubectl
```

Check out our [gke.bash](../../scripts/gke.bash) script for basic management of
the GKE k8s cluster.
