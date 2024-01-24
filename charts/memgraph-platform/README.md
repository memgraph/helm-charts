## Memgraph Platform Kubernetes Helm Chart
A Helm Chart for deploying Memgraph platform (including the database, lab and mage) on Kubernetes.

## Installing the Memgraph Platform Helm Chart
To install the Memgraph Platform Helm Chart, follow the steps below:
```
helm install <release-name> memgraph/memgraph-platform
```
Replace `<release-name>` with a name of your choice for the release.

## Changing the default chart values
To change the default chart values, run the command with the specified set of flags:
```
helm install <resource-name> memgraph/memgraph-platform --set <flag1>=<value1>,<flag2>=<value2>,...
```
Or you can modify a `values.yaml` file and override the desired values:
```
helm install <resource-name> memgraph/memgraph-platform -f values.yaml
```

## Configuration options
The following table lists the configurable parameters of the Memgraph chart and their default values.

| parameter                               | description                                     | default                         |
| --------------------------------------- | ----------------------------------------------- | ------------------------------- |
| `image`                                 | Memgraph Docker image repository                | `memgraph`                      |
| `persistentVolumeClaim.storagePVC`      | Enable persistent volume claim for storage      | `true`                          |
| `persistanceVolumeClaim.storagePVCSize` | Size of the persistent volume claim for storage | `1Gi`                           |
| `persistentVolumeClaim.logPVC`          | Enable persistent volume claim for logs         | `true`                          |
| `persistanceVolumeClaim.logPVCSize`     | Size of the persistent volume claim for logs    | `256Mi`                         |
| `service.type`                          | Kubernetes service type                         | `NodePort`                      |
| `service.port`                          | Kubernetes service port                         | `7687`                          |
| `service.targetPort`                    | Kubernetes service target port                  | `7687`                          |
| `memgraphConfig`                        | Memgraph configuration settings                 | `["--also-log-to-stderr=true"]` |



For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).
