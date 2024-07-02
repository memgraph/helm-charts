## Memgraph Standalone Kubernetes Helm Chart
A Helm Chart for deploying standalone Memgraph database on Kubernetes.

## Installing the Memgraph Helm Chart
To install the Memgraph Helm Chart, follow the steps below:
```
helm install <release-name> memgraph/memgraph
```
Replace `<release-name>` with a name of your choice for the release.

## Changing the default chart values
To change the default chart values, run the command with the specified set of flags:
```
helm install <resource-name> memgraph/memgraph --set <flag1>=<value1>,<flag2>=<value2>,...
```
Or you can modify a `values.yaml` file and override the desired values:
```
helm install <resource-name> memgraph/memgraph -f values.yaml
```

## Configuration Options

The following table lists the configurable parameters of the Memgraph chart and their default values.

| Parameter                                   | Description                                                                                         | Default                                 |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------|-----------------------------------------|
| `image.repository`                          | Memgraph Docker image repository                                                                    | `memgraph/memgraph`                     |
| `image.tag`                                 | Specific tag for the Memgraph Docker image. Overrides the image tag whose default is chart version. | `""` (Defaults to chart's app version)  |
| `image.pullPolicy`                          | Image pull policy                                                                                   | `IfNotPresent`                          |
| `replicaCount`                              | Number of Memgraph instances to run. Note: no replication or HA support.                            | `1`                                     |
| `service.type`                              | Kubernetes service type                                                                             | `NodePort`                              |
| `service.port`                              | Kubernetes service port                                                                             | `7687`                                  |
| `service.targetPort`                         | Kubernetes service target port                                                                     | `7687`                                  |
| `service.protocol`                          | Protocol used by the service                                                                        | `TCP`                                   |
| `service.annotations`                       | Annotations to add to the service                                                                   | `{}`                                    |
| `persistentVolumeClaim.storagePVC`          | Enable persistent volume claim for storage                                                          | `true`                                  |
| `persistentVolumeClaim.storagePVCClassName` | Storage class name for the persistent volume claim for storage. If not specified, default used.     | `""`                                    |
| `persistentVolumeClaim.storagePVCSize`      | Size of the persistent volume claim for storage                                                     | `1Gi`                                   |
| `persistentVolumeClaim.logPVC`              | Enable persistent volume claim for logs                                                             | `true`                                  |
| `persistentVolumeClaim.logPVCClassName`     | Storage class name for the persistent volume claim for logs. If not specified, default used.        | `""`                                    |
| `persistentVolumeClaim.logPVCSize`          | Size of the persistent volume claim for logs                                                        | `256Mi`                                 |
| `memgraphConfig`                            | List of strings defining Memgraph configuration settings                                            | `["--also-log-to-stderr=true"]`         |
| `statefulSetAnnotations`                    | Annotations to add to the stateful set                                                              | `{}`                                    |
| `podAnnotations`                            | Annotations to add to the pod                                                                       | `{}`                                    |
| `resources`                                 | CPU/Memory resource requests/limits. Left empty by default.                                         | `{}` (See note on uncommenting)         |
| `serviceAccount.create`                     | Specifies whether a service account should be created                                               | `true`                                  |
| `serviceAccount.annotations`                | Annotations to add to the service account                                                           | `{}`                                    |
| `serviceAccount.name`                       | The name of the service account to use. If not set and create is true, a name is generated.         | `""`                                    |

**Note:** It's often recommended not to specify default resources and leave it as a conscious choice for the user. If you want to specify resources, uncomment the following lines in your `values.yaml`, adjust them as necessary:

```yaml
resources:
  limits:
    cpu: "100m"
    memory: "128Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"

```

The `memgraphConfig` parameter should be a list of strings defining the values of Memgraph configuration settings. For example, this is how you can define `memgraphConfig` parameter in your `values.yaml`:

```yaml
memgraphConfig:
  - "--also-log-to-stderr=true"
  - "--log-level=TRACE"
  - "--log-file=''"

```
For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).
