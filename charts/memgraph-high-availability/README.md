# Helm chart for Memgraph high availability (HA) cluster (Enterprise)
A Helm Chart for deploying Memgraph in [high availability setup](https://memgraph.com/docs/clustering/high-availability). This Helm Chart requires an [Enterprise version of Memgraph](https://memgraph.com/docs/database-management/enabling-memgraph-enterprise).

Memgraph HA cluster includes 3 coordinators, 2 data instances by default. The cluster setup is performed via the cluster-setup job.

## Installing the Memgraph HA Helm Chart
To install the Memgraph HA Helm Chart, follow the steps below:
```
helm install <release-name> memgraph/memgraph-high-availability --set memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE=<your-license>,memgraph.env.MEMGRAPH_ORGANIZATION_NAME=<your-organization-name>
```
Replace `<release-name>` with a name of your choice for the release and set the enterprise license.

## Changing the default chart values
To change the default chart values, run the command with the specified set of flags:
```
helm install <release-name> memgraph/memgraph-high-availability --set <flag1>=<value1>,<flag2>=<value2>,...
```
Or you can modify a `values.yaml` file and override the desired values:
```
helm install <release-name> memgraph/memgraph-high-availability -f values.yaml
```

## Upgrading the Memgraph HA Helm Chart

If you used `values.yaml` file for installing Helm Chart, use:
```
helm upgrade <release-name> memgraph/memgraph-high-availability -f values.yaml
```

If you used `--set`, use:
```
helm upgrade <release-name> memgraph/memgraph-high-availability --set <all flags from installation>,image.tag=<new image tag>
```

## Configuration Options

The following table lists the configurable parameters of the Memgraph chart and their default values.

| Parameter                                          | Description                                                                                                                                                                                                                                                                                                                                                                                          | Default                    |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `image.repository`                        | Memgraph Docker image repository                                                                                                                                                                                                                                                                                                                                                                     | `memgraph/memgraph`        |
| `image.tag`                               | Specific tag for the Memgraph Docker image. Overrides the image tag whose default is chart version.                                                                                                                                                                                                                                                                                                  | `2.22.0`                   |
| `image.pullPolicy`                        | Image pull policy                                                                                                                                                                                                                                                                                                                                                                                    | `IfNotPresent`             |
| `env.MEMGRAPH_ENTERPRISE_LICENSE`         | Memgraph enterprise license                                                                                                                                                                                                                                                                                                                                                                          | `<your-license>`           |
| `env.MEMGRAPH_ORGANIZATION_NAME`          | Organization name                                                                                                                                                                                                                                                                                                                                                                                    | `<your-organization-name>` |
| `storage.libPVCSize`                      | Size of the storage PVC                                                                                                                                                                                                                                                                                                                                                                              | `1Gi`                      |
| `storage.libStorageClassName`             | The name of the storage class used for storing data.                                                                                                                                                                                                                                                                                                                                                 | ``                         |
| `storage.libStorageAccessMode`            | Access mode used for lib storage.                                                                                                                                                                                                                                                                                                                                                                    | `ReadWriteOnce`            |
| `storage.logPVCSize`                      | Size of the log PVC                                                                                                                                                                                                                                                                                                                                                                                  | `1Gi`                      |
| `storage.logStorageClassName`             | The name of the storage class used for storing logs.                                                                                                                                                                                                                                                                                                                                                 | ``                         |
| `storage.logStorageAccessMode`            | Access mode used for log storage.                                                                                                                                                                                                                                                                                                                                                                    | `ReadWriteOnce`            |
| `externalAccess.coordinator.serviceType`  | IngressNginx, NodePort, CommonLoadBalancer or LoadBalancer. Use LoadBalancer for Cloud production deployment and NodePort for local testing. 'CommonLoadBalancer' will open one load balancer for all coordinators while 'LoadBalancer' will open one load balancer for each coordinators. IngressNginx will create ingress controller that will allow TCP connections towards coordinator services. | `NodePort`                 |
| `externalAccess.dataInstance.serviceType` | IngressNginx, NodePort or LoadBalancer. Use LoadBalancer for Cloud production deployment and NodePort for local testing. IngressNginx will create ingress controller that will allow TCP connections towards data instances' services.                                                                                                                                                               | `NodePort`                 |
| `ports.boltPort`                          | Bolt port used on coordinator and data instances.                                                                                                                                                                                                                                                                                                                                                    | `7687`                     |
| `ports.managementPort`                    | Management port used on coordinator and data instances.                                                                                                                                                                                                                                                                                                                                              | `10000`                    |
| `ports.replicationPort`                   | Replication port used on data instances.                                                                                                                                                                                                                                                                                                                                                             | `20000`                    |
| `ports.coordinatorPort`                   | Coordinator port used on coordinators.                                                                                                                                                                                                                                                                                                                                                               | `12000`                    |
| `affinity.unique`                         | Schedule pods on different nodes in the cluster                                                                                                                                                                                                                                                                                                                                                      | `false`                    |
| `affinity.parity`                         | Schedule pods on the same node with maximum one coordinator and one data node                                                                                                                                                                                                                                                                                                                        | `false`                    |
| `affinity.nodeSelection`                  | Schedule pods on nodes with specific labels                                                                                                                                                                                                                                                                                                                                                          | `false`                    |
| `affinity.roleLabelKey`                   | Label key for node selection                                                                                                                                                                                                                                                                                                                                                                         | `role`                     |
| `affinity.dataNodeLabelValue`             | Label value for data nodes                                                                                                                                                                                                                                                                                                                                                                           | `data-node`                |
| `affinity.coordinatorNodeLabelValue`      | Label value for coordinator nodes                                                                                                                                                                                                                                                                                                                                                                    | `coordinator-node`         |
| `data`                                             | Configuration for data instances                                                                                                                                                                                                                                                                                                                                                                     | See `data` section         |
| `coordinators`                                     | Configuration for coordinator instances                                                                                                                                                                                                                                                                                                                                                              | See `coordinators` section |
| `sysctlInitContainer.enabled`                      | Enable the init container to set sysctl parameters                                                                                                                                                                                                                                                                                                                                                   | `true`                     |
| `sysctlInitContainer.maxMapCount`                  | Value for `vm.max_map_count` to be set by the init container                                                                                                                                                                                                                                                                                                                                         | `262144`                   |
| `secrets.enabled`                                  | Enable the use of Kubernetes secrets for Memgraph credentials                                                                                                                                                                                                                                                                                                                                        | `false`                    |
| `secrets.name`                                     | The name of the Kubernetes secret containing Memgraph credentials                                                                                                                                                                                                                                                                                                                                    | `memgraph-secrets`         |
| `secrets.userKey`                                  | The key in the Kubernetes secret for the Memgraph user, the value is passed to the `MEMGRAPH_USER` env                                                                                                                                                                                                                                                                                               | `USER`                     |
| `secrets.passwordKey`                              | The key in the Kubernetes secret for the Memgraph password, the value is passed to the `MEMGRAPH_PASSWORD`                                                                                                                                                                                                                                                                                           | `PASSWORD`                 |

For the `data` and `coordinators` sections, each item in the list has the following parameters:

| Parameter | Description                        | Default                            |
| --------- | ---------------------------------- | ---------------------------------- |
| `id`      | ID of the instance                 | `0` for data, `1` for coordinators |
| `args`    | List of arguments for the instance | See `args` section                 |



The `args` section contains a list of arguments for starting the Memgraph instance.

For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).

## Retain policy

The default policy of PVs is Delete which means that when PVCs are deleted, corresponding PVs will be deleted to. This is not the best practice
in when deploying a database inside K8s so we advise users to either create a custom storage class with policy Retain or that they use the following
script to patch PVs:

```
#!/bin/bash

# Get all Persistent Volume names
PVS=$(kubectl get pv --no-headers -o custom-columns=":metadata.name")

# Loop through each PV and patch it
for pv in $PVS; do
  echo "Patching PV: $pv"
  kubectl patch pv $pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
done

echo "All PVs have been patched."
```
