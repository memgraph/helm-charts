## Memgraph Lab Standalone Kubernetes Helm Chart
A Helm Chart for deploying standalone Memgraph Lab on Kubernetes.

## Installing the Memgraph Lab Helm Chart
To install the Memgraph Lab Helm Chart, follow the steps below:
```
helm install <release-name> memgraph/memgraph-lab
```
Replace `<release-name>` with a name of your choice for the release.

## Changing the default chart values
To change the default chart values, run the command with the specified set of flags:
```
helm install <resource-name> memgraph/memgraph --set <flag1>=<value1>,<flag2>=<value2>,...
```
Or you can modify a `values.yaml` file and override the desired values:
```
helm install <resource-name> memgraph/memgraph-lab -f values.yaml
```

## Configuration Options

The following table lists the configurable parameters of the Memgraph Lab chart and their default values.

| Parameter                    | Description                                                                                             | Default                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `image.repository`           | Memgraph Lab Docker image repository                                                                    | `memgraph/memgraph-lab`                |
| `image.tag`                  | Specific tag for the Memgraph Lab Docker image. Overrides the image tag whose default is chart version. | `""` (Defaults to chart's app version) |
| `image.pullPolicy`           | Image pull policy                                                                                       | `IfNotPresent`                         |
| `replicaCount`               | Number of Memgraph Lab instances to run.                                                                | `1`                                    |
| `service.type`               | Kubernetes service type                                                                                 | `ClusterIP`                            |
| `service.port`               | Kubernetes service port                                                                                 | `3000`                                 |
| `service.targetPort`         | Kubernetes service target port                                                                          | `3000`                                 |
| `service.protocol`           | Protocol used by the service                                                                            | `TCP`                                  |
| `service.annotations`        | Annotations to add to the service                                                                       | `{}`                                   |
| `podAnnotations`             | Annotations to add to the pod                                                                           | `{}`                                   |
| `resources`                  | CPU/Memory resource requests/limits. Left empty by default.                                             | `{}` (See note on uncommenting)        |
| `serviceAccount.create`      | Specifies whether a service account should be created                                                   | `true`                                 |
| `serviceAccount.annotations` | Annotations to add to the service account                                                               | `{}`                                   |
| `serviceAccount.name`        | The name of the service account to use. If not set and create is true, a name is generated.             | `""`                                   |

Memgraph Lab can be further configured with environment variables in your `values.yaml` file.

```yaml
env:
  - name: QUICK_CONNECT_MG_HOST
    value: memgraph
  - name: QUICK_CONNECT_MG_PORT
    value: "7687"
```
Check all supported environemnt variables from the Memgraph website, [Data Visualization Section](https://memgraph.com/docs/data-visualization/install-and-connect#environment-variables)
