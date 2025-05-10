# Deploying Memgraph under GCP's GKE

In general, to deploy GKE cluster follow the [offical
documentation](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster).
For a specific example, take a look below.

To install `gcloud` follow [install SDK
instructions](https://cloud.google.com/sdk/docs/install-sdk). In addition,
`gke-gcloud-auth-plugin` is required, to install it run:
```
gcloud components install kubectl
```

Check out our [gke.bash](../../scripts/gke.bash) script for basic management of
the GKE k8s cluster.
