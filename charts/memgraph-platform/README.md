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
When working with Memgraph Platform Docker image, you should pass configuration flags inside of environment variables.

For example, you can start the memgraph Docker image with docker run memgraph/memgraph --bolt-port=7687 --log-level=TRACE, but you should start memgraph-platform Docker image with docker run -p 7687:7687 -p 7444:7444 -p 3000:3000 -e MEMGRAPH="--bolt-port=7687 --log-level=TRACE" memgraph/memgraph-platform.

Each configuration setting is in the form: --setting-name=value.

For all available database settings, refer to the [Configuration settings reference guide](https://memgraph.com/docs/memgraph/reference-guide/configuration).

The following table lists the configurable parameters of the Memgraph Platform chart and their default values.

| Parameter                                    | Description                                                 | Default                     |
| -------------------------------------------- | ----------------------------------------------------------- | --------------------------- |
| `replicaCount`                               | Number of replicas                                          | `1`                         |
| `image.repository`                           | Memgraph Platform Docker image repository                   | `memgraph-platform`         |
| `image.pullPolicy`                           | Image pull policy                                           | `IfNotPresent`              |
| `image.tag`                                  | Image tag (overrides chart appVersion)                      | `""`                        |
| `imagePullSecrets`                           | Image pull secrets                                          | `[]`                        |
| `nameOverride`                               | Override chart name                                         | `""`                        |
| `fullnameOverride`                           | Override full chart name                                    | `""`                        |
| `serviceAccount.create`                      | Create service account                                      | `true`                      |
| `serviceAccount.automount`                   | Automatically mount service account API credentials         | `true`                      |
| `serviceAccount.annotations`                 | Service account annotations                                 | `{}`                        |
| `serviceAccount.name`                        | Service account name                                        | (auto-generated if not set) |
| `podAnnotations`                             | Annotations to add to the pods                              | `{}`                        |
| `podLabels`                                  | Labels to add to the pods                                   | `{}`                        |
| `podSecurityContext`                         | Pod-level security context                                  | `{}`                        |
| `securityContext`                            | Container security context                                  | `{}`                        |
| `service.type`                               | Kubernetes service type                                     | `ClusterIP`                 |
| `service.portBolt`                           | Service port for Bolt protocol                              | `7687`                      |
| `service.portLab`                            | Service port for Lab UI                                     | `3000`                      |
| `service.portLog`                            | Service port for logs                                       | `7444`                      |
| `env.MEMGRAPH`                               | Memgraph environment variable                               | `{}`                        |
| `persistentVolumeClaim.storagePVC`           | Enable persistent volume claim for storage                  | `true`                      |
| `persistentVolumeClaim.storagePVCSize`       | Size of the persistent volume claim for storage             | `1Gi`                       |
| `persistentVolumeClaim.logPVC`               | Enable persistent volume claim for logs                     | `true`                      |
| `persistentVolumeClaim.logPVCSize`           | Size of the persistent volume claim for logs                | `256Mi`                     |
| `ingress.enabled`                            | Enable Ingress                                              | `false`                     |
| `ingress.className`                          | Ingress class name                                          | `""`                        |
| `ingress.annotations`                        | Ingress annotations                                         | `{}`                        |
| `ingress.hosts`                              | Ingress hosts                                               | `[]`                        |
| `resources`                                  | Resource requests and limits                                | `{}`                        |
| `livenessProbe`                              | Liveness probe settings                                     | `{}`                        |
| `readinessProbe`                             | Readiness probe settings                                    | `{}`                        |
| `autoscaling.enabled`                        | Enable Horizontal Pod Autoscaler                            | `false`                     |
| `autoscaling.minReplicas`                    | Minimum number of replicas for autoscaling                  | `1`                         |
| `autoscaling.maxReplicas`                    | Maximum number of replicas for autoscaling                  | `100`                       |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization percentage for autoscaling           | `80`                        |
| `volumes`                                    | Additional volumes on the output Deployment definition      | `[]`                        |
| `volumeMounts`                               | Additional volumeMounts on the output Deployment definition | `[]`                        |
| `nodeSelector`                               | Node selector for pods                                      | `{}`                        |
| `tolerations`                                | Tolerations for pods                                        | `[]`                        |
| `affinity`                                   | Affinity settings for pods                                  | `{}`                        |



