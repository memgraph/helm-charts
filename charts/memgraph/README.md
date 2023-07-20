## Memgraph Kubernetes Helm Charts
A Helm Chart for deploying Memgraph database on Kubernetes.

## Installing the Memgraph Helm Chart
To install the Memgraph Helm Chart, follow the steps below:
```
helm install <resource-name> memgraph/memgraph
```
Replace `<resource-name>` with a name of your choice for the release.

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
`image.repository` | Memgraph Docker image repository | `memgraph`
`persistanceVolumeClaim.storageSize` | Size of the persistent volume claim | `1Gi`
`service.type` | Kubernetes service type | `NodePort`
`service.port` | Kubernetes service port | `7687`
`service.targetPort` | Kubernetes service target port | `7687`
