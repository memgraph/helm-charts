## Description

This guide instructs users on how to deploy Memgraph HA to AWS EKS. It serves only as a starting point and there are many ways possible to extend what is currently here. In this setup
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
the AWS context and you can verify this by running `kubectl context current-context`. My is pointing to `andi.skrgat@test-cluster-ha.eu-west-1.eksctl.io`.

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
aws iam list-attached-role-policies --role-name eksctl-test-cluster-ha-nodegroup-s-NodeInstanceRole-<ROLE_ID_FROM_PREVIOUS_OUTPUT>
```

It is also important to create Inbound Rule in the Security Group attached to the eksctl cluster which will allow TCP traffic
on ports 30000-32767. We find it easiest to modify this by going to the EC2 Dashboard.


## Deploy Memgraph cluster

The only step left is to deploy the cluster using

```
helm install mem-ha-test ./charts/memgraph-high-availability --set \
memgraph.env.MEMGRAPH_ENTERPRISE_LICENSE=<YOUR_LICENSE>, \
memgraph.env.MEMGRAPH_ORGANIZATION_NAME=<YOUR_ORGANIZATION_NAME>, \
memgraph.data.volumeClaim.storagePVCClassName=gp2, \
memgraph.coordinators.volumeClaim.storagePVCClassName=gp2, \
memgraph.data.volumeClaim.logPVCClassName=gp2, \
memgraph.coordinators.volumeClaim.logPVCClassName=gp2, \
memgraph.affinity.enabled=true
```

You can check the state of the cluster with `kubectl get pods -o wide`.
