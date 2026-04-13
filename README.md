# Memgraph Helm Charts
[![License: Apache-2.0](https://img.shields.io/github/license/memgraph/helm-charts)](https://github.com/memgraph/helm-charts/blob/main/LICENSE)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/memgraph)](https://artifacthub.io/packages/search?repo=memgraph)
[![Docs](https://img.shields.io/badge/documentation-Memgraph-orange)](https://memgraph.com/docs/)


Welcome to the Memgraph Helm Charts repository. This repository provides Helm charts for deploying Memgraph, an open-source in-memory graph database.

## Available charts
- [**Memgraph standalone**](#memgraph-standalone)
- [**Memgraph Lab**](#memgraph-lab)
- [**Memgraph high availability**](#memgraph-high-availability)

## Prerequisites
Helm version 3 or above installed.

## Add the Helm repository
Add the Memgraph Helm chart repository to your local Helm setup by running the following command:

```
helm repo add memgraph https://memgraph.github.io/helm-charts
```

## Update the repository
Make sure to update the repository to fetch the latest Helm charts available:

```
helm repo update
```

## Memgraph standalone
Deploys standalone Memgraph.
For detailed information and usage instructions, please refer to the [chart's individual README file](./charts/memgraph/README.md).

To install the Memgraph standalone chart, run the following command:

```
helm install my-release memgraph/memgraph
```
Replace `my-release` with a name of your choice for the release.


Once Memgraph is installed, you can access it using the provided services and endpoints. Refer to the [Memgraph documentation](https://memgraph.com/docs/memgraph/connect-to-memgraph) for details on how to connect to and interact with Memgraph.

To upgrade or uninstall a deployed Memgraph release, you can use the `helm upgrade` or `helm uninstall` commands, respectively. Refer to the [Helm documentation](https://helm.sh/docs/) for more details on these commands.

## Memgraph lab
Deploys Memgraph Lab.
For detailed information and usage instructions, please refer to the [chart's individual README file](./charts/memgraph-lab/README.md).

To install Memgraph Lab, run the following command:

```
helm install my-release memgraph/memgraph-lab
```
Replace `my-release` with a name of your choice for the release.


Refer to the [Data visualization in Memgraph Lab](https://memgraph.com/docs/data-visualization) for details on how to connect to and interact with Memgraph.

To upgrade or uninstall a deployed Memgraph release, you can use the `helm upgrade` or `helm uninstall` commands, respectively. Refer to the [Helm documentation](https://helm.sh/docs/) for more details on these commands.


## Memgraph high availability
Deploys high available Memgraph cluster, that includes two data instances and three coordinators.

For detailed information and usage instructions, please refer to the [chart's individual README file](./charts/memgraph-high-availability/README.md).

To install the chart, run the following command:

```
helm install my-release memgraph/memgraph-high-availability --set env.MEMGRAPH_ENTERPRISE_LICENSE=<your-license>,env.MEMGRAPH_ORGANIZATION_NAME=<your-organization-name>
```
Replace `my-release` with a name of your choice for the release.

There are a few additional steps to make the cluster fully operational. Please take a look under the [Setting up the cluster](https://memgraph.com/docs/getting-started/install-memgraph/kubernetes#setting-up-the-cluster) docs section.

Once Memgraph cluster is up and running, you can access it using the provided services and endpoints. Refer to the [Memgraph documentation](https://memgraph.com/docs/memgraph/connect-to-memgraph) for details on how to connect to and interact with Memgraph.

To upgrade or uninstall a deployed Memgraph release, you can use the `helm upgrade` or `helm uninstall` commands, respectively. Refer to the [Helm documentation](https://helm.sh/docs/) for more details on these commands.

## Remote Metrics and Logging
Both Memgraph charts support optional remote observability:

- **Remote metrics** via `vmagentRemote` using Prometheus `remote_write`.
- **Remote logs** via `vectorRemote` using Loki-compatible push API.

This works with VictoriaMetrics/VictoriaLogs, and with other backends that expose compatible Prometheus remote-write and Loki endpoints.

### Prerequisites
- Enable chart-level Prometheus exporter (`prometheus.enabled=true`).
- Use a secret containing credentials for your remote endpoints (required for `vmagentRemote`; optional for `vectorRemote`).
- For standalone chart, enable Memgraph monitoring ports:
  - `service.enableHttpMonitoring=true`
  - `service.enableWebsocketMonitoring=true`
- If `vectorRemote.enabled=true`, add Memgraph monitoring flags:
  - standalone chart: add `--monitoring-port=<service.websocketPortMonitoring>` and `--monitoring-address=0.0.0.0` to `memgraphConfig`
  - HA chart: add `--monitoring-port=<vectorRemote.websocketPort>` and `--monitoring-address=0.0.0.0` to each instance's `args`
- If `vmagentRemote.enabled=true` and you only need remote_write, set `prometheus.serviceMonitor.enabled=false` to avoid duplicate scraping of `mg-exporter` by both vmagent and kube-prometheus.

### Standalone chart example
```yaml
prometheus:
  enabled: true
  namespace: monitoring
  serviceMonitor:
    enabled: false

service:
  enableHttpMonitoring: true
  enableWebsocketMonitoring: true

memgraphConfig:
  - "--data-directory=/var/lib/memgraph/mg_data"
  - "--also-log-to-stderr=true"
  - "--monitoring-port=7444"
  - "--monitoring-address=0.0.0.0"

vmagentRemote:
  enabled: true
  namespace: monitoring
  remoteWrite:
    url: "https://<prom-remote-write>/api/v1/write"
    basicAuth:
      secretName: monitoring-basic-auth
      usernameKey: username
      passwordKey: password
  externalLabels:
    cluster_id: "memgraph-standalone"
    service_name: "memgraph"
    cluster_env: "dev"

vectorRemote:
  enabled: true
  logsEndpoint: "https://<loki-endpoint>"
  # Optional: only set auth when endpoint requires basic auth.
  auth:
    secretName: monitoring-basic-auth
    usernameKey: username
    passwordKey: password
  extraLabels:
    cluster_id: "memgraph-standalone"
    service_name: "memgraph"
    cluster_env: "dev"
    role: "standalone"
```

### High availability chart example
```yaml
prometheus:
  enabled: true
  namespace: monitoring
  serviceMonitor:
    enabled: false

vmagentRemote:
  enabled: true
  namespace: monitoring
  remoteWrite:
    url: "https://<prom-remote-write>/api/v1/write"
    basicAuth:
      secretName: monitoring-basic-auth
      usernameKey: username
      passwordKey: password
  externalLabels:
    cluster_id: "memgraph-testing-cluster-53"
    service_name: "Memgraph HA"
    cluster_env: "self-hosted-large-01"

vectorRemote:
  enabled: true
  data: true
  coordinators: true
  websocketPort: 7444
  logsEndpoint: "https://<loki-endpoint>"
  # Optional: only set auth when endpoint requires basic auth.
  auth:
    secretName: monitoring-basic-auth
    usernameKey: username
    passwordKey: password
  extraLabels:
    cluster_id: "memgraph-testing-cluster-53"
    service_name: "Memgraph HA"
    cluster_env: "self-hosted-large-01"

data:
  - id: "0"
    args:
      - "--management-port=10000"
      - "--bolt-port=7687"
      - "--monitoring-port=7444"
      - "--monitoring-address=0.0.0.0"
  - id: "1"
    args:
      - "--management-port=10000"
      - "--bolt-port=7687"
      - "--monitoring-port=7444"
      - "--monitoring-address=0.0.0.0"

coordinators:
  - id: "1"
    args:
      - "--coordinator-id=1"
      - "--coordinator-port=12000"
      - "--management-port=10000"
      - "--bolt-port=7687"
      - "--monitoring-port=7444"
      - "--monitoring-address=0.0.0.0"
  - id: "2"
    args:
      - "--coordinator-id=2"
      - "--coordinator-port=12000"
      - "--management-port=10000"
      - "--bolt-port=7687"
      - "--monitoring-port=7444"
      - "--monitoring-address=0.0.0.0"
  - id: "3"
    args:
      - "--coordinator-id=3"
      - "--coordinator-port=12000"
      - "--management-port=10000"
      - "--bolt-port=7687"
      - "--monitoring-port=7444"
      - "--monitoring-address=0.0.0.0"
```

### Optional auth secrets for remote endpoints
Create the same secret in all namespaces where the components run:

```bash
kubectl create secret generic monitoring-basic-auth -n monitoring \
  --from-literal=username='<username>' \
  --from-literal=password='<password>'
```

For HA and standalone vector sidecars, also create the same secret in the Memgraph release namespace (for example `default` or `memgraph`):

```bash
kubectl create secret generic monitoring-basic-auth -n <memgraph-namespace> \
  --from-literal=username='<username>' \
  --from-literal=password='<password>'
```

### Export Kubernetes infrastructure metrics with `vmagentRemote`

`vmagentRemote` can also scrape Kubernetes infrastructure metrics required by
`kube-prometheus-stack` Kubernetes/Node dashboards, and remote-write them to
your centralized monitoring cluster.

Enable Kubernetes scraping in values:

```yaml
vmagentRemote:
  enabled: true
  namespace: monitoring
  remoteWrite:
    url: "https://<prom-remote-write>/insert/0/prometheus/api/v1/write"
    basicAuth:
      secretName: monitoring-basic-auth
      usernameKey: username
      passwordKey: password
  externalLabels:
    cluster: "my-k8s-cluster"
    cluster_id: "my-k8s-cluster"
    service_name: "memgraph"
    cluster_env: "dev"
  kubernetes:
    enabled: true
    kubeStateMetrics:
      enabled: true
      jobName: kube-state-metrics
      targets:
        - kube-prometheus-stack-kube-state-metrics.monitoring.svc.cluster.local:8080
    nodeExporter:
      enabled: true
      jobName: node-exporter
      targets:
        - kube-prometheus-stack-prometheus-node-exporter.monitoring.svc.cluster.local:9100
    kubelet:
      enabled: true
      jobName: kubelet
      metricsPath: /metrics/cadvisor
      apiServerAddress: kubernetes.default.svc:443
      insecureSkipVerify: true
```

Notes:

- This creates RBAC for vmagent to discover/scrape kubelet metrics via the API server node proxy.
- Keep `jobName` values aligned with dashboard/rule expectations unless you also update dashboard queries.
- Dashboards that depend on precomputed recording-rule series still require rule evaluation in your monitoring stack.

Ready-to-use example values:

- Standalone: `examples/remote-monitoring/values-standalone-k8s-metrics.yaml`
- HA: `examples/remote-monitoring/values-ha-k8s-metrics.yaml`

Install examples:

```bash
# Standalone
helm upgrade --install memgraph memgraph/memgraph \
  -n memgraph \
  --create-namespace \
  -f ./examples/remote-monitoring/values-standalone-k8s-metrics.yaml

# High availability
helm upgrade --install memgraph-ha memgraph/memgraph-high-availability \
  -n memgraph \
  --create-namespace \
  -f ./examples/remote-monitoring/values-ha-k8s-metrics.yaml \
  --set env.MEMGRAPH_ENTERPRISE_LICENSE=<your-license> \
  --set env.MEMGRAPH_ORGANIZATION_NAME=<your-org>
```

## Docker Compose

Creates HA Memgraph cluster with one command. The only thing you need to do is add your license details. Used bridged docker network for
communication.


## Contributing
Contributions are welcome! If you have any improvements, bug fixes, or new charts to add, please follow the contribution guidelines outlined in the [`CONTRIBUTING.md`](https://github.com/memgraph/helm-charts/blob/main/CONTRIBUTING.md) file. If you have questions and are unsure of how to contribute, please join our Discord server to get in touch with us.

<p align="center">
  <a href="https://memgr.ph/join-discord">
    <img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
</p>

## Debugging Memgraph Pods

Find more details under [Debugging Running
Pods](https://memgraph.com/docs/database-management/debugging#debugging-running-pods)
documentation section.

## License
This repository is licensed under the [Apache 2.0 License](https://github.com/memgraph/helm-charts/blob/main/LICENSE).
