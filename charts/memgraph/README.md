## Memgraph Kubernetes Helm Charts
A Helm Chart for deploying Memgraph database on Kubernetes.

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
`persistanceVolumeClaim.storagePVCSize` | Size of the persistent volume claim for storage | `1Gi`
`persistentVolumeClaim.logPVC` | Enable persistent volume claim for logs | `true`
`persistanceVolumeClaim.logPVCSize` | Size of the persistent volume claim for logs | `256Mi`
`service.type` | Kubernetes service type | `NodePort`
`service.port` | Kubernetes service port | `7687`
`service.targetPort` | Kubernetes service target port | `7687`
