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

## Running the Memgraph HA Helm Chart locally

To run Memgraph HA Helm Chart locally, affinity needs to be disabled because the cluster will be running on a single node.

To disable the affinity, run the following command with the specified set of flags:

```
helm install <release-name> memgraph/memgraph-high-availability --set memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE=<your-license>,memgraph.env.MEMGRAPH_ORGANIZATION_NAME=<your-organization-name>,memgraph.affinity.enabled=false
```

The affinity is disabled either by running the command above, or by modifying the `values.yaml` file.


## Configuration Options

The following table lists the configurable parameters of the Memgraph chart and their default values.


| Parameter                                   | Description                                                                                         | Default                                 |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------|-----------------------------------------|
| `memgraph.image.repository`                 | Memgraph Docker image repository                                                                    | `memgraph/memgraph`                     |
| `memgraph.image.tag`                        | Specific tag for the Memgraph Docker image. Overrides the image tag whose default is chart version. | `2.22.0`                                |
| `memgraph.image.pullPolicy`                 | Image pull policy                                                                                   | `IfNotPresent`                          |
| `memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE`  | Memgraph enterprise license                                                                         | `<your-license>`                        |
| `memgraph.env.MEMGRAPH_ORGANIZATION_NAME`   | Organization name                                                                                   | `<your-organization-name>`              |
| `memgraph.probes.startup.failureThreshold`  | Startup probe failure threshold                                                                     | `30`                                    |
| `memgraph.probes.startup.periodSeconds`     | Startup probe period in seconds                                                                     | `10`                                    |
| `memgraph.probes.readiness.initialDelaySeconds` | Readiness probe initial delay in seconds                                                         | `5`                                     |
| `memgraph.probes.readiness.periodSeconds`   | Readiness probe period in seconds                                                                   | `5`                                     |
| `memgraph.probes.liveness.initialDelaySeconds` | Liveness probe initial delay in seconds                                                           | `30`                                    |
| `memgraph.probes.liveness.periodSeconds`    | Liveness probe period in seconds                                                                    | `10`                                    |
| `memgraph.data.volumeClaim.storagePVC`      | Enable storage PVC                                                                                  | `true`                                 |
| `memgraph.data.volumeClaim.storagePVCSize`  | Size of the storage PVC                                                                             | `1Gi`                                   |
| `memgraph.data.volumeClaim.logPVC`          | Enable log PVC                                                                                      | `false`                                 |
| `memgraph.data.volumeClaim.logPVCSize`      | Size of the log PVC                                                                                 | `256Mi`                                 |
| `memgraph.coordinators.volumeClaim.storagePVC` | Enable storage PVC for coordinators                                                               | `true`                                 |
| `memgraph.coordinators.volumeClaim.storagePVCSize` | Size of the storage PVC for coordinators                                                         | `1Gi`                                   |
| `memgraph.coordinators.volumeClaim.logPVC`  | Enable log PVC for coordinators                                                                     | `false`                                 |
| `memgraph.coordinators.volumeClaim.logPVCSize` | Size of the log PVC for coordinators                                                              | `256Mi`                                 |
| `memgraph.affinity.enabled`                 | Enables affinity so each instance is deployed to unique node                                        | `true`                                 |
| `memgraph.externalAccess.serviceType`       | NodePort or LoadBalancer. Use LoadBalancer for Cloud production deployment and NodePort for local testing | `LoadBalancer`                    |
| `memgraph.ports.boltPort`                   | Bolt port used on coordinator and data instances.                                                   | `7687`                                  |
| `memgraph.ports.managementPort`             | Management port used on coordinator and data instances.                                             | `10000`                                 |
| `memgraph.ports.replicationPort`            | Replication port used on data instances.                                                            | `20000`                                 |
| `memgraph.ports.coordinatorPort`            | Coordinator port used on coordinators.                                                              | `12000`                                 |
| `data`                                      | Configuration for data instances                                                                    | See `data` section                      |
| `coordinators`                              | Configuration for coordinator instances                                                             | See `coordinators` section              |
| `sysctlInitContainer.enabled`                      | Enable the init container to set sysctl parameters                                                  | `true`                     |
| `sysctlInitContainer.maxMapCount`                  | Value for `vm.max_map_count` to be set by the init container                                        | `262144`                   |

For the `data` and `coordinators` sections, each item in the list has the following parameters:

| Parameter                                   | Description                                                                                         | Default                                 |
|---------------------------------------------|-----------------------------------------------------------------------------------------------------|-----------------------------------------|
| `id`                                        | ID of the instance                                                                                  | `0` for data, `1` for coordinators      |
| `args`                                      | List of arguments for the instance                                                                  | See `args` section                      |


The `args` section contains a list of arguments for the instance. The default values are the same for all instances:

```markdown
- "--also-log-to-stderr"
- "--log-level=TRACE"
- "--replication-restore-state-on-startup=true"
```

For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).
