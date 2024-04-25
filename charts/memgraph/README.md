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

## Configuration options
The following table lists the configurable parameters of the Memgraph chart and their default values.

parameter | description | default
--- | --- | ---
`image` | Memgraph Docker image repository | `memgraph`
`persistentVolumeClaim.storagePVC` | Enable persistent volume claim for storage | `true`
`persistanceVolumeClaim.storagePVCClassName` | Storage class name for the persistent volume claim for storage. If not specified, default will be used | `""`
`persistanceVolumeClaim.storagePVCSize` | Size of the persistent volume claim for storage | `1Gi`
`persistentVolumeClaim.logPVC` | Enable persistent volume claim for logs | `true`
`persistanceVolumeClaim.logPVCClassName` | Storage class name for the persistent volume claim for logs. If not specified, default will be used | `""`
`persistanceVolumeClaim.logPVCSize` | Size of the persistent volume claim for logs | `256Mi`
`service.type` | Kubernetes service type | `NodePort`
`service.port` | Kubernetes service port | `7687`
`service.targetPort` | Kubernetes service target port | `7687`
`memgraphConfig` | Memgraph configuration settings | `["--also-log-to-stderr=true"]`

The `memgraphConfig` parameter should be a list of strings defining the values of Memgraph configuration settings. For example, this is how you can define `memgraphConfig` parameter in your `values.yaml`:
```
memgraphConfig:
  - "--also-log-to-stderr=true"
  - "--log-level=TRACE"
```
For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).
