## Description

This guide instructs users on how to deploy Memgraph HA to Azure AKS. It serves only as a starting point and there are many ways possible to extend
what is currently here. In this setup each Memgraph database is deployed to separate, `Standard_A2_v2`.

## Installing tools

You will need:
- [azure-cli](https://learn.microsoft.com/en-us/cli/azure/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh/docs/intro/install/)

We used `azure-cli 2.67.0, kubectl v1.30.0 and helm 3.14.4`.

## Login with Azure-CLI

Use `az login` and enter your authentication details.

## Create resource group

The next step involves creating resource group which will later be attached to Kubernetes cluster. Example:
```
az group create --name ResourceGroup2 --location northeurope
```

## Provision K8 nodes

After creating resource group, K8 nodes can be created and attached to the previously created resource group. There are many other options
you can use but we will cover here the simplest deployment scenario in which will we use 5 'Standard_A2_v2' instances where each instance will
host its own Memgraph database.

```
az aks create --resource-group ResourceGroup2 --name memgraph-ha --node-count 5 --node-vm-size Standard_A2_v2 --generate-ssh-keys
```

## Configure kubectl

To get remote context from Azure AKS into your local kubectl, use:
```
az aks get-credentials --resource-group ResourceGroup2 --name memgraph-ha
```

## Label nodes

By running `kubectl get nodes -o=wide`, you should be able to see your nodes. Example:

| NAME                              | STATUS | ROLES | AGE | VERSION | INTERNAL-IP | EXTERNAL-IP | OS-IMAGE           | KERNEL-VERSION       | CONTAINER-RUNTIME      |
|-----------------------------------|--------|-------|-----|---------|-------------|-------------|--------------------|----------------------|------------------------|
| aks-nodepool1-65392319-vmss000000 | Ready  | <none>| 11m | v1.29.9 | 10.224.0.4   | <none>      | Ubuntu 22.04.5 LTS | 5.15.0-1074-azure    | containerd://1.7.23-1 |
| aks-nodepool1-65392319-vmss000001 | Ready  | <none>| 12m | v1.29.9 | 10.224.0.8   | <none>      | Ubuntu 22.04.5 LTS | 5.15.0-1074-azure    | containerd://1.7.23-1 |
| aks-nodepool1-65392319-vmss000002 | Ready  | <none>| 12m | v1.29.9 | 10.224.0.6   | <none>      | Ubuntu 22.04.5 LTS | 5.15.0-1074-azure    | containerd://1.7.23-1 |
| aks-nodepool1-65392319-vmss000003 | Ready  | <none>| 11m | v1.29.9 | 10.224.0.5   | <none>      | Ubuntu 22.04.5 LTS | 5.15.0-1074-azure    | containerd://1.7.23-1 |
| aks-nodepool1-65392319-vmss000004 | Ready  | <none>| 11m | v1.29.9 | 10.224.0.7   | <none>      | Ubuntu 22.04.5 LTS | 5.15.0-1074-azure    | containerd://1.7.23-1 |

Most often users will use smaller nodes for 3 coordinators and bigger nodes for data instances. To be able to do that, we will label first
3 nodes with `role=coordinator-node` and the last 2 with `role=data-node`.

```
kubectl label nodes aks-nodepool1-65392319-vmss000000 role=coordinator-node
kubectl label nodes aks-nodepool1-65392319-vmss000001 role=coordinator-node
kubectl label nodes aks-nodepool1-65392319-vmss000002 role=coordinator-node
kubectl label nodes aks-nodepool1-65392319-vmss000003 role=data-node
kubectl label nodes aks-nodepool1-65392319-vmss000004 role=data-node
```

In the following chapters, we will go over several most common deployment types:

## Service type = IngressNginx

The most cost-friendly way to manage a Memgraph HA cluster in K8s is using a IngressNginx contoller. This controller is capable of routing TCP messages on Bolt level
protocol to the K8s Memgraph services. To achieve this, it uses only a single LoadBalancer which means there is only a single external IP for connecting to the cluster.
Users can connect to any coordinator or data instance by distinguishing bolt ports. The 1st step is to install Memgraph HA:

```
helm install mem-ha-test ./charts/memgraph-high-availability --set \
memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE=<licence>,\
memgraph.env.MEMGRAPH_ORGANIZATION_NAME=<organization>,memgraph.affinity.nodeSelection=true,\
memgraph.externalAccessConfig.dataInstance.serviceType=IngressNginx,memgraph.externalAccessConfig.coordinator.serviceType=IngressNginx
```

Next, install `IngressNginx` resource:

```
helm upgrade --install ingress-nginx ingress-nginx \
--repo https://kubernetes.github.io/ingress-nginx \
--namespace ingress-nginx --create-namespace \
--set controller.tcp.services.configMapNamespace=ingress-nginx \
--set controller.tcp.services.configMapName=tcp-services
```

After installing Memgraph HA Chart and IngressNginx resource, we need to customize a configuration of the newly created Controller and Deployment
K8s object. Open the `ingress-nginx-controller` service for editing by running:
```
kubectl edit svc ingress-nginx-controller -n ingress-nginx
```

Locate the `spec.ports` section and append the following services configuration:
```
- name: data-0
  port: 9000
  targetPort: 9000
  protocol: TCP
- name: data-1
  port: 9001
  targetPort: 9001
  protocol: TCP
- name: coord-1
  port: 9011
  targetPort: 9011
  protocol: TCP
- name: coord-2
  port: 9012
  targetPort: 9012
  protocol: TCP
- name: coord-3
  port: 9013
  targetPort: 9013
  protocol: TCP
```

After you are done, save and close the file. Next, open the `ingress-nginx-controller` deployment by running:
```
kubectl edit deployment ingress-nginx-controller -n ingress-nginx
```

Locate the `args` section and append the following configuration option:
```
- --tcp-services-configmap=ingress-nginx/tcp-services
```

If you get stuck, more info can be found [here](https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/). Save and close the file.
The only remaining step is to connect Memgraph instances. For that, we need to find out which external IP will a LoadBalancer use. You can find that out
by running `kubectl get svc -o=wide -A`.

```
ADD COORDINATOR 1 WITH CONFIG {"bolt_server": "<external-ip>:9011", "management_server":  "memgraph-coordinator-1.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-1.default.svc.cluster.local:12000"};
ADD COORDINATOR 2 WITH CONFIG {"bolt_server": "<external-ip>:9012", "management_server":  "memgraph-coordinator-2.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-2.default.svc.cluster.local:12000"};
ADD COORDINATOR 3 WITH CONFIG {"bolt_server": "<external-ip>:9013", "management_server":  "memgraph-coordinator-3.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-3.default.svc.cluster.local:12000"};
REGISTER INSTANCE instance_0 WITH CONFIG {"bolt_server": "<external-ip>:9000", "management_server": "memgraph-data-0.default.svc.cluster.local:10000", "replication_server": "memgraph-data-0.default.svc.cluster.local:20000"};
REGISTER INSTANCE instance_1 WITH CONFIG {"bolt_server": "<external-ip>:9001", "management_server": "memgraph-data-1.default.svc.cluster.local:10000", "replication_server": "memgraph-data-1.default.svc.cluster.local:20000"};
SET INSTANCE instance_1 TO MAIN;
```

## ServiceType = LoadBalancer

After preparing nodes, we can deploy Memgraph HA cluster by using `helm install` command. We will specify affinity options so that node labels
are used and so that each data and coordinator instance is exposed through LoadBalancer.

```
helm install mem-ha-test ./charts/memgraph-high-availability --set \
memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE=<licence>,\
memgraph.env.MEMGRAPH_ORGANIZATION_NAME=<organization>,memgraph.affinity.nodeSelection=true,\
memgraph.externalAccessConfig.dataInstance.serviceType=LoadBalancer,memgraph.externalAccessConfig.coordinator.serviceType=LoadBalancer
```

By running `kubectl get svc -o=wide` and `kubectl get pods -o=wide` we can verify that deployment finished successfully. Example:

| NAME                            | TYPE         | CLUSTER-IP   | EXTERNAL-IP     | PORT(S)                          | AGE | SELECTOR                   |
|---------------------------------|--------------|--------------|-----------------|----------------------------------|-----|----------------------------|
| kubernetes                      | ClusterIP    | 10.0.0.1     | `<none>`        | 443/TCP                          | 21m | `<none>`                   |
| memgraph-coordinator-1          | ClusterIP    | 10.0.65.178  | `<none>`        | 7687/TCP,12000/TCP,10000/TCP     | 63s | app=memgraph-coordinator-1 |
| memgraph-coordinator-1-external | LoadBalancer | 10.0.28.222  | 172.205.93.228  | 7687:30402/TCP                   | 63s | app=memgraph-coordinator-1 |
| memgraph-coordinator-2          | ClusterIP    | 10.0.129.252 | `<none>`        | 7687/TCP,12000/TCP,10000/TCP     | 63s | app=memgraph-coordinator-2 |
| memgraph-coordinator-2-external | LoadBalancer | 10.0.102.4   | 4.209.216.240   | 7687:32569/TCP                   | 63s | app=memgraph-coordinator-2 |
| memgraph-coordinator-3          | ClusterIP    | 10.0.42.32   | `<none>`        | 7687/TCP,12000/TCP,10000/TCP     | 63s | app=memgraph-coordinator-3 |
| memgraph-coordinator-3-external | LoadBalancer | 10.0.208.244 | 68.219.15.104   | 7687:30874/TCP                   | 63s | app=memgraph-coordinator-3 |
| memgraph-data-0                 | ClusterIP    | 10.0.227.204 | `<none>`        | 7687/TCP,10000/TCP,20000/TCP     | 63s | app=memgraph-data-0        |
| memgraph-data-0-external        | LoadBalancer | 10.0.78.197  | 68.219.11.242   | 7687:31823/TCP                   | 63s | app=memgraph-data-0        |
| memgraph-data-1                 | ClusterIP    | 10.0.251.227 | `<none>`        | 7687/TCP,10000/TCP,20000/TCP     | 63s | app=memgraph-data-1        |
| memgraph-data-1-external        | LoadBalancer | 10.0.147.131 | 68.219.13.145   | 7687:30733/TCP                   | 63s | app=memgraph-data-1        |


| NAME                        | READY | STATUS  | RESTARTS | AGE | IP         | NODE                               | NOMINATED NODE | READINESS GATES |
|-----------------------------|-------|---------|----------|-----|------------|------------------------------------|----------------|-----------------|
| memgraph-coordinator-1-0    | 1/1   | Running | 0        | 80s | 10.244.0.3 | aks-nodepool1-65392319-vmss000001  | `<none>`       | `<none>`        |
| memgraph-coordinator-2-0    | 1/1   | Running | 0        | 80s | 10.244.3.3 | aks-nodepool1-65392319-vmss000000  | `<none>`       | `<none>`        |
| memgraph-coordinator-3-0    | 1/1   | Running | 0        | 80s | 10.244.1.8 | aks-nodepool1-65392319-vmss000002  | `<none>`       | `<none>`        |
| memgraph-data-0-0           | 1/1   | Running | 0        | 80s | 10.244.4.3 | aks-nodepool1-65392319-vmss000004  | `<none>`       | `<none>`        |
| memgraph-data-1-0           | 1/1   | Running | 0        | 80s | 10.244.2.2 | aks-nodepool1-65392319-vmss000003  | `<none>`       | `<none>`        |

## Connect cluster

The only remaining step left is to connect instances. For this we will use Memgraph Lab. Open Lab and use Memgraph instance type of connection.
For the host enter external ip of `memgraph-coordinator-1-external` and port is 7687. Both for adding coordinators and registering instances,
we only need to change 'bolt\_server' part to use LoadBalancers' external IP.

```
ADD COORDINATOR 1 WITH CONFIG {"bolt_server": "172.205.93.228:7687", "management_server":  "memgraph-coordinator-1.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-1.default.svc.cluster.local:12000"};
ADD COORDINATOR 2 WITH CONFIG {"bolt_server": "4.209.216.240:7687", "management_server":  "memgraph-coordinator-2.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-2.default.svc.cluster.local:12000"};
ADD COORDINATOR 3 WITH CONFIG {"bolt_server": "68.219.15.104:7687", "management_server":  "memgraph-coordinator-3.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-3.default.svc.cluster.local:12000"};
REGISTER INSTANCE instance_1 WITH CONFIG {"bolt_server": "68.219.11.242:7687", "management_server": "memgraph-data-0.default.svc.cluster.local:10000", "replication_server": "memgraph-data-0.default.svc.cluster.local:20000"};
REGISTER INSTANCE instance_2 WITH CONFIG {"bolt_server": "68.219.13.145:7687", "management_server": "memgraph-data-1.default.svc.cluster.local:10000", "replication_server": "memgraph-data-1.default.svc.cluster.local:20000"};
SET INSTANCE instance_1 TO MAIN;
```

The output of `SHOW INSTANCES` should then look similar to:

```
| name            | bolt_server                                             | coordinator_server                                       | management_server                                        | health  | role      | last_succ_resp_ms |
|-----------------|---------------------------------------------------------|----------------------------------------------------------|----------------------------------------------------------|---------|-----------|-------------------|
| "coordinator_1" | "172.205.93.228:7687"                                   | "memgraph-coordinator-1.default.svc.cluster.local:12000" | "memgraph-coordinator-1.default.svc.cluster.local:10000" | "up"    | "leader"  | 0                 |
| "coordinator_2" | "4.209.216.240:7687"                                    | "memgraph-coordinator-2.default.svc.cluster.local:12000" | "memgraph-coordinator-2.default.svc.cluster.local:10000" | "up"    | "follower"| 550               |
| "coordinator_3" | "68.219.15.104:7687"                                    | "memgraph-coordinator-3.default.svc.cluster.local:12000" | "memgraph-coordinator-3.default.svc.cluster.local:10000" | "up"    | "follower"| 26                |
| "instance_1"    | "68.219.11.242:7687"                                    | ""                                                       | "memgraph-data-0.default.svc.cluster.local:10000"        | "up"    | "main"    | 917               |
| "instance_2"    | "68.219.13.145:7687"                                    | ""                                                       | "memgraph-data-1.default.svc.cluster.local:10000"        | "up"    | "replica" | 266               |
```

## Using CommonLoadBalancer

When using 'CommonLoadBalancer', all three coordinators will be behind a single LoadBalancer while each data instance has their own load balancer. To connect the cluster, open Lab and use Memgraph
instance type of connection. For the host enter external IP of `memgraph-coordinator-1-external` and port is 7687. Again, we only need to change
'bolt\_server' part to use LoadBalancers' external IP. When connecting to CommonLoadBalancer, K8 will automatically route you to one of coordinators.
To see on which coordinator did you end routed, run `SHOW INSTANCE`. If for example, the output of the query says you are connected to
coordinator 2, we need to add coordinators 1 and 3. Registering data instances stays exactly the same.

```
ADD COORDINATOR 2 WITH CONFIG {"bolt_server": "<CommonLoadBalancer-IP>:7687", "management_server":  "memgraph-coordinator-2.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-2.default.svc.cluster.local:12000"};
ADD COORDINATOR 1 WITH CONFIG {"bolt_server": "<CommonLoadBalancer-IP>:7687", "management_server":  "memgraph-coordinator-1.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-1.default.svc.cluster.local:12000"};
ADD COORDINATOR 3 WITH CONFIG {"bolt_server": "<CommonLoadBalancer-IP>:7687", "management_server":  "memgraph-coordinator-3.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-3.default.svc.cluster.local:12000"};
REGISTER INSTANCE instance_1 WITH CONFIG {"bolt_server": "68.219.11.242:7687", "management_server": "memgraph-data-0.default.svc.cluster.local:10000", "replication_server": "memgraph-data-0.default.svc.cluster.local:20000"};
REGISTER INSTANCE instance_2 WITH CONFIG {"bolt_server": "68.219.13.145:7687", "management_server": "memgraph-data-1.default.svc.cluster.local:10000", "replication_server": "memgraph-data-1.default.svc.cluster.local:20000"};
SET INSTANCE instance_1 TO MAIN;
```
