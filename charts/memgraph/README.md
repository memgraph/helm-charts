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
helm install <release-name> memgraph/memgraph --set <flag1>=<value1>,<flag2>=<value2>,...
```
Or you can modify a `values.yaml` file and override the desired values:
```
helm install <release-name> memgraph/memgraph -f values.yaml
```

## Configuration Options

The following table lists the configurable parameters of the Memgraph chart and their default values.

| Parameter                                    | Description                                                                                                                      | Default                                |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `image.repository`                           | Memgraph Docker image repository                                                                                                 | `memgraph/memgraph`                    |
| `image.tag`                                  | Specific tag for the Memgraph Docker image. Overrides the image tag whose default is chart version.                              | `""` (Defaults to chart's app version) |
| `image.pullPolicy`                           | Image pull policy                                                                                                                | `IfNotPresent`                         |
| `memgraphUserId`                             | The user id that is hardcoded in Memgraph and Mage images                                                                        | `101`                                  |
| `memgraphGroupId`                            | The group id that is hardcoded in Memgraph and Mage images                                                                       | `103`                                  |
| `useImagePullSecrets`                        | Override the default imagePullSecrets                                                                                            | `false`                                |
| `imagePullSecrets`                           | Specify image pull secrets                                                                                                       | `- name: regcred`                      |
| `replicaCount`                               | Number of Memgraph instances to run. Note: no replication or HA support.                                                         | `1`                                    |
| `affinity.nodeKey`                           | Key for node affinity (Preferred)                                                                                                | `""`                                   |
| `affinity.nodeValue`                         | Value for node affinity (Preferred)                                                                                              | `""`                                   |
| `nodeSelector`                               | Constrain which nodes your Memgraph pod is eligible to be scheduled on, based on the labels on the nodes. Left empty by default. | `{}`                                   |
| `service.type`                               | Kubernetes service type                                                                                                          | `ClusterIP`                            |
| `service.enableBolt`                         | Enable Bolt protocol                                                                                                             | `true`                                 |
| `service.boltPort`                           | Bolt protocol port                                                                                                               | `7687`                                 |
| `service.enableWebsocketMonitoring`          | Enable WebSocket monitoring                                                                                                      | `false`                                |
| `service.websocketPortMonitoring`            | WebSocket monitoring port                                                                                                        | `7444`                                 |
| `service.enableHttpMonitoring`               | Enable HTTP monitoring                                                                                                           | `false`                                |
| `service.httpPortMonitoring`                 | HTTP monitoring port                                                                                                             | `9091`                                 |
| `service.annotations`                        | Annotations to add to the service                                                                                                | `{}`                                   |
| `service.labels`                             | Labels to add to the service                                                                                                     | `{}`                                   |
| `persistentVolumeClaim.createStorageClaim`   | Enable creation of a Persistent Volume Claim for storage                                                                         | `true`                                 |
| `persistentVolumeClaim.storageClassName`     | Storage class name for the persistent volume claim                                                                               | `""`                                   |
| `persistentVolumeClaim.storageSize`          | Size of the persistent volume claim for storage                                                                                  | `10Gi`                                 |
| `persistentVolumeClaim.existingClaim`        | Use an existing Persistent Volume Claim                                                                                          | `memgraph-0`                           |
| `persistentVolumeClaim.storageVolumeName`    | Name of an existing Volume to create a PVC for                                                                                   | `""`                                   |
| `persistentVolumeClaim.createLogStorage`     | Enable creation of a Persistent Volume Claim for logs                                                                            | `true`                                 |
| `persistentVolumeClaim.logStorageClassName`  | Storage class name for the persistent volume claim for logs                                                                      | `""`                                   |
| `persistentVolumeClaim.logStorageSize`       | Size of the persistent volume claim for logs                                                                                     | `1Gi`                                  |
| `persistentVolumeClaim.createUserClaim`      | Create a Dynamic Persistant Volume Claim for Configs, Certificates (e.g. Bolt cert ) and rest of User related files              | `false`                                |
| `persistentVolumeClaim.userStorageClassName` | Storage class name for the persistent volume claim for user storage                                                              | `""`                                   |
| `persistentVolumeClaim.userStorageSize`      | Size of the persistent volume claim for user storage                                                                             | `1Gi`                                  |
| `persistentVolumeClaim.userStorageAccessMode`| Storage Class Access Mode. If you need a different pod to add data into Memgraph (e.g. CSV files) set this to "ReadWriteMany"    | `ReadWriteOnce`                        |
| `persistentVolumeClaim.userMountPath`        | Where to mount the `userStorageClass` you should set this variable if you are enabling the `UserClaim`                           | `""`                                   |
| `memgraphConfig`                             | List of strings defining Memgraph configuration settings                                                                         | `["--also-log-to-stderr=true"]`        |
| `secrets.enabled`                            | Enable the use of Kubernetes secrets for Memgraph credentials                                                                    | `false`                                |
| `secrets.name`                               | The name of the Kubernetes secret containing Memgraph credentials                                                                | `memgraph-secrets`                     |
| `secrets.userKey`                            | The key in the Kubernetes secret for the Memgraph user, the value is passed to the `MEMGRAPH_USER` env                           | `USER`                                 |
| `secrets.passwordKey`                        | The key in the Kubernetes secret for the Memgraph password, the value is passed to the `MEMGRAPH_PASSWORD`                       | `PASSWORD`                             |
| `memgraphEnterpriseLicense`                  | Memgraph Enterprise License                                                                                                      | `""`                                   |
| `memgraphOrganizationName`                   | Organization name for Memgraph Enterprise License                                                                                | `""`                                   |
| `statefulSetAnnotations`                     | Annotations to add to the stateful set                                                                                           | `{}`                                   |
| `podAnnotations`                             | Annotations to add to the pod                                                                                                    | `{}`                                   |
| `resources`                                  | CPU/Memory resource requests/limits. Left empty by default.                                                                      | `{}`                                   |
| `tolerations`                                | A toleration is applied to a pod and allows the pod to be scheduled on nodes with matching taints. Left empty by default.        | `[]`                                   |
| `serviceAccount.create`                      | Specifies whether a service account should be created                                                                            | `true`                                 |
| `serviceAccount.annotations`                 | Annotations to add to the service account                                                                                        | `{}`                                   |
| `serviceAccount.name`                        | The name of the service account to use. If not set and create is true, a name is generated.                                      | `""`                                   |
| `container.terminationGracePeriodSeconds`    | Grace period for pod termination                                                                                                 | `1800`                                 |
| `container.livenessProbe.exec`               | If defined, will be used instead of a default K8s's probe.                                                                       | `""`                                   |
| `container.livenessProbe.tcpSocket.port`     | Port used for TCP connection. Should be the same as bolt port.                                                                   | `7687`                                 |
| `container.livenessProbe.failureThreshold`   | Failure threshold for liveness probe                                                                                             | `20`                                   |
| `container.livenessProbe.timeoutSeconds`     | Initial delay for readiness probe                                                                                                | `10`                                   |
| `container.livenessProbe.periodSeconds`      | Period seconds for readiness probe                                                                                               | `5`                                    |
| `container.readinessProbe.exec`               | If defined, will be used instead of a default K8s's probe.                                                                       | `""`                                   |
| `container.readinessProbe.tcpSocket.port`    | Port used for TCP connection. Should be the same as bolt port.                                                                   | `7687`                                 |
| `container.readinessProbe.failureThreshold`  | Failure threshold for readiness probe                                                                                            | `20`                                   |
| `container.readinessProbe.timeoutSeconds`    | Initial delay for readiness probe                                                                                                | `10`                                   |
| `container.readinessProbe.periodSeconds`     | Period seconds for readiness probe                                                                                               | `5`                                    |
| `container.startupProbe.exec`               | If defined, will be used instead of a default K8s's probe.                                                                       | `""`                                   |
| `container.startupProbe.tcpSocket.port`      | Port used for TCP connection. Should be the same as bolt port.                                                                   | `7687`                                 |
| `container.startupProbe.failureThreshold`    | Failure threshold for startup probe                                                                                              | `1440`                                 |
| `container.startupProbe.periodSeconds`       | Period seconds for startup probe                                                                                                 | `10`                                   |
| `nodeSelectors`                              | Node selectors for pod. Left empty by default.                                                                                   | `{}`                                   |
| `customQueryModules`                         | List of custom Query modules that should be mounted to Memgraph Pod                                                              | `[]`                                   |
| `storageClass.create`                        | If set to true, new StorageClass will be created.                                                                                | `false`                                |
| `storageClass.name`                          | Name of the StorageClass                                                                                                         | `"memgraph-generic-storage-class"`     |
| `storageClass.provisioner`                   | Provisioner for the StorageClass                                                                                                 | `""`                                   |
| `storageClass.storageType`                   | Type of storage for the StorageClass                                                                                             | `""`                                   |
| `storageClass.fsType`                        | Filesystem type for the StorageClass                                                                                             | `""`                                   |
| `storageClass.reclaimPolicy`                 | Reclaim policy for the StorageClass                                                                                              | `Retain`                               |
| `storageClass.volumeBindingMode`             | Volume binding mode for the StorageClass                                                                                         | `Immediate`                            |
| `lifecycleHooks`                             | For the memgraph container(s) to automate configuration before or after startup                                                  | `{}`                                   |
| `extraVolumes`                               | Optionally specify extra list of additional volumes                                                                              | `[]`                                   |
| `extraVolumeMounts`                          | Optionally specify extra list of additional volumeMounts                                                                         | `[]`                                   |
| `sysctlInitContainer.enabled`                | Enable the init container to set sysctl parameters                                                                               | `true`                                 |
| `sysctlInitContainer.maxMapCount`            | Value for `vm.max_map_count` to be set by the init container                                                                     | `262144`                               |
| `sysctlInitContainer.image.repository`       | Busybox image repository                                                                                                         | `library/busybox`                      |
| `sysctlInitContainer.image.tag`              | Specific tag for the Busybox Docker image                                                                                        | `latest`                               |
| `sysctlInitContainer.image.pullPolicy`       | Image pull policy for busybox                                                                                                    | `IfNotPresent`                         |
| `initContainers`                             | User specific init containers                                                                                                    | `[]`                                   |
| `extraEnv`                                   | Env variables that users can define                                                                                              | `[]`                                   |

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


If you are using the Memgraph user, make sure you have secrets set:

```
kubectl create secret generic memgraph-secrets --from-literal=USER=myuser --from-literal=PASSWORD=mypassword
```

For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).
