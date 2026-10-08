# memgraph-operator

Installs the Memgraph Kubernetes operator: the `MemgraphCluster` CustomResourceDefinition, a
least-privilege RBAC set, and the controller Deployment. Declaring a cluster is then a single
resource — see the [repository README](../../README.md) and its
[`docs/`](../../docs).

The chart lives in the operator repository next to the generated manifests: the CRDs under
`crds/` and the manager's RBAC rules under `rbac/` are generated from the Go types and the
`+kubebuilder:rbac` markers (`make chart-sync`), and CI fails if they drift from the controller
they ship with.

## Install

```sh
helm repo add memgraph https://memgraph.github.io/helm-charts
helm repo update
helm install memgraph-operator memgraph/memgraph-operator \
  --namespace memgraph-operator-system --create-namespace --wait
```

The operator watches every namespace, so one release per cluster is enough.

The chart is maintained in `memgraph/kubernetes-operator` and published to that index. `helm search
repo memgraph/memgraph-operator --versions` lists what is available, and the chart's `appVersion`
is the operator version an install runs by default. The two version numbers move independently —
see [`docs/releasing.md`](../../docs/releasing.md).

Installing from a checkout works the same way:

```sh
helm install memgraph-operator ./charts/memgraph-operator \
  --namespace memgraph-operator-system --create-namespace --wait
```

## Uninstall

```sh
helm uninstall memgraph-operator --namespace memgraph-operator-system
```

Helm never deletes CRDs it installed, so the `MemgraphCluster` CRD — and with it your clusters
and their PersistentVolumeClaims — survive the uninstall. Remove it explicitly when no cluster
needs it any more:

```sh
kubectl delete crd memgraphclusters.memgraph.com
```

For the same reason, `helm upgrade` does not update the CRD. Apply the new one before upgrading
to a chart version that changes the API:

```sh
kubectl apply -f charts/memgraph-operator/crds/
```

## Permissions

The manager's ClusterRole is generated from the controller's own RBAC markers, so it grants
exactly what the reconciler issues: read MemgraphClusters, patch their status, and create and
patch (server-side apply) the StatefulSets, Services, Gateways, TCPRoutes, ServiceMonitors,
ConfigMaps and the vmagent Deployment it provisions. It deletes exactly two kinds of thing: Pods,
one at a time, to roll a changed pod template through the cluster, and the objects a removed spec
block leaves behind — the external Services, Gateways and TCPRoutes of a removed `externalAccess`
block or a retired data instance, and the ServiceMonitor, ConfigMaps and vmagent Deployment of a
removed `monitoring` block. The ConfigMap and Deployment rules reach every object of those kinds,
but the operator's cache holds only the ones it labelled as its own. It cannot delete a
StatefulSet or a headless Service — deleting a `MemgraphCluster` removes them through garbage
collection of the owner references. The Gateway API and `monitoring.coreos.com` rules are granted
whether or not the cluster serves those groups; a cluster without them simply never exercises
the rules. Leader election adds a Lease and
Events in the operator's own namespace, and the
metrics endpoint adds the TokenReview/SubjectAccessReview permissions it authorizes scrapes
with. Secrets are read-only and only for the license and the AWS credentials: `list`/`watch`
feed a metadata-only informer that notices a changed license or AWS credentials Secret, and `get`
reads that one Secret uncached, so a renewal or rotation reaches running pods with
`SET DATABASE SETTING`. No Secret data is cached, and no Secret is ever written.

## Values

| Key | Default | Description |
| --- | --- | --- |
| `image.repository` | `docker.io/memgraph/kubernetes-operator` | Operator image repository |
| `image.tag` | `""` | Operator image tag; defaults to the chart's `appVersion` |
| `image.pullPolicy` | `IfNotPresent` | Operator image pull policy |
| `imagePullSecrets` | `[]` | Secrets used to pull the operator image |
| `replicaCount` | `1` | Controller replicas |
| `leaderElection.enabled` | `true` | Elect a leader, so a second replica can stand by |
| `resources` | 10m/64Mi requests, 500m/128Mi limits | Controller container resources |
| `metrics.enabled` | `true` | Serve the controller-runtime metrics endpoint and create its Service |
| `metrics.port` | `8443` | Port the metrics endpoint binds to |
| `metrics.secure` | `true` | Serve metrics over HTTPS with authenticated, authorized scrapes |
| `rbac.create` | `true` | Create the operator's Roles and bindings |
| `serviceAccount.create` | `true` | Create the operator's ServiceAccount |
| `serviceAccount.name` | `""` | ServiceAccount name; required when `create` is false |
| `serviceAccount.annotations` | `{}` | Annotations for the ServiceAccount |
| `namespaceOverride` | `""` | Install the namespaced objects outside the release namespace |
| `nameOverride` / `fullnameOverride` | `""` | Override the generated object names |
| `podAnnotations` / `podLabels` | `{}` | Extra metadata on the controller pod |
| `nodeSelector` / `tolerations` / `affinity` | `{}` / `[]` / `{}` | Scheduling of the controller pod |
| `priorityClassName` | `""` | PriorityClass of the controller pod |
| `terminationGracePeriodSeconds` | `10` | Grace period of the controller pod |
| `podSecurityContext` | non-root uid/gid 65532, seccomp `RuntimeDefault` | Pod security context |
| `securityContext` | no privilege escalation, read-only root, all capabilities dropped | Container security context |
| `extraArgs` | `[]` | Additional controller command-line arguments |
| `extraEnv` | `[]` | Additional controller environment variables |
