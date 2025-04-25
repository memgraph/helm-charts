## Description

This guide instructs users on how to deploy Memgraph HA to AWS EKS using `NodePort` services. It serves only as a starting point and there are many ways possible to extend what is currently here. In this setup
each Memgraph database is deployed to separate, `t3.small` node in the `eu-west-1` AWS region.

## Installation

You will need:
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/setting-up.html)
- [helm](https://helm.sh/docs/intro/install/)

We used `kubectl 1.30.0, aws 2.17.29, eksctl 0.188.0 and helm 3.14.4`.

## Configure AWS CLI

Use `aws configure` and enter your `AWS Access Key ID, Secret Access Key, Region and output format`.

## Create EKS Cluster

We provide you with the sample configuration file for AWS in this folder. Running

```
eksctl create cluster -f cluster.yaml`
```

should be sufficient. Make sure to change the path to the public SSH key if you want to have SSH access to EC2 instances. After creating the cluster, `kubectl` should pick up
the AWS context and you can verify this by running `kubectl config current-context`. My is pointing to `andi.skrgat@test-cluster-ha.eu-west-1.eksctl.io`.

## Add Helm Charts repository

If you don't have installed Memgraph Helm repo, please make sure you by running:

```
helm repo add memgraph https://memgraph.github.io/helm-charts
helm repo list
helm repo update
```

## Install the AWS CSI driver

Once EKS nodes are started, you need to install AWS Elastic Block Store CSI driver so the cluster can auto-manage EBS resources from AWS. Run the following:

```
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.25"
```

## Authentication and authorization

Before deploying the cluster, you need to provide access to the NodeInstanceRole. First find the name of the role with

```
aws eks describe-nodegroup --cluster-name test-cluster-ha --nodegroup-name standard-workers
```

and then provide full access to it:

```
aws iam attach-role-policy --role-name eksctl-test-cluster-ha-nodegroup-s-NodeInstanceRole-<ROLE-ID> --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam list-attached-role-policies --role-name eksctl-test-cluster-ha-nodegroup-s-NodeInstanceRole-<ROLE-ID>
```

When using `NodePort` services, it is important to create Inbound Rule in the Security Group attached to the eksctl cluster which will allow TCP traffic
on ports 30000-32767. We find it easiest to modify this by going to the EC2 Dashboard.

## Label nodes

This guide uses a `nodeSelection` affinity option. Make sure to label nodes where you want to have deployed coordinators with role `coordinator-node`
and nodes where you want to have deployed data instances with role `data-node`.

Example:
```
kubectl label nodes node-000000 role=coordinator-node
kubectl label nodes node-000001 role=coordinator-node
kubectl label nodes node-000002 role=coordinator-node
kubectl label nodes node-000003 role=data-node
kubectl label nodes node-000004 role=data-node
```

## Deploy Memgraph cluster

We can now install Memgraph HA chart using the following command:

```
helm install mem-ha-test ./charts/memgraph-high-availability --set \
env.MEMGRAPH_ENTERPRISE_LICENSE=<YOUR_LICENSE>, \
env.MEMGRAPH_ORGANIZATION_NAME=<YOUR_ORGANIZATION_NAME>, \
storage.coordinators.libStorageClassName=gp2, \
storage.data.libStorageClassName=gp2, \
storage.coordinators.logStorageClassName=gp2, \
storage.data.logStorageClassName=gp2, \
affinity.nodeSelection=true, \
externalAccessConfig.dataInstance.serviceType=NodePort, \
externalAccessConfig.coordinator.serviceType=NodePort
```

The only remaining step is to connect instances to form a cluster:
```
ADD COORDINATOR 1 WITH CONFIG {"bolt_server": "<node1-ip>:7687", "management_server":  "memgraph-coordinator-1.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-1.default.svc.cluster.local:12000"};
ADD COORDINATOR 2 WITH CONFIG {"bolt_server": "<node2-ip>:7687", "management_server":  "memgraph-coordinator-2.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-2.default.svc.cluster.local:12000"};
ADD COORDINATOR 3 WITH CONFIG {"bolt_server": "<node3-ip>:7687", "management_server":  "memgraph-coordinator-3.default.svc.cluster.local:10000", "coordinator_server":  "memgraph-coordinator-3.default.svc.cluster.local:12000"};
REGISTER INSTANCE instance_1 WITH CONFIG {"bolt_server": "<node4-ip>:7687", "management_server": "memgraph-data-0.default.svc.cluster.local:10000", "replication_server": "memgraph-data-0.default.svc.cluster.local:20000"};
REGISTER INSTANCE instance_2 WITH CONFIG {"bolt_server": "<node5-ip>:7687", "management_server": "memgraph-data-1.default.svc.cluster.local:10000", "replication_server": "memgraph-data-1.default.svc.cluster.local:20000"};
SET INSTANCE instance_1 TO MAIN;

```


You can check the state of the cluster with `kubectl get pods -o wide`.
