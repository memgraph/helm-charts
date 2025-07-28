#!/bin/bash -e

POLICY_ARN="arn:aws:iam::aws:policy/AmazonEC2FullAccess"
CLUSTER_NAME="mg-ha"
NODEGROUP_NAME="standard-workers"

print_help() {
  echo "Usage: $0 [command]"
  echo
  echo "The script assumes you already installed eksctl and that you've run aws configure to login. The script will configure a cluster of 6 nodes which you can use to install Memgraph HA chart."
  echo "Commands:"
  echo "  create_cluster   Create the EKS cluster using aws_cluster.yaml"
  echo "  delete_cluster   Delete the EKS cluster (not yet implemented)"
  echo "  help, --help     Show this help message"
}

create_cluster() {
  eksctl create cluster -f aws_cluster.yaml
  kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.25"
  ROLE_ARN=$(aws eks describe-nodegroup \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name "$NODEGROUP_NAME" \
  --query "nodegroup.nodeRole" \
  --output text)
  ROLE_NAME=$(basename "$ROLE_ARN")
  echo "Attaching policy $POLICY_ARN to role $ROLE_NAME"
  aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "$POLICY_ARN"
}

delete_cluster() {
  eksctl delete cluster -f aws_cluster.yaml
}


case $1 in
  create_cluster)
    create_cluster
  ;;
  delete_cluster)
    delete_cluster
  ;;
  help|--help|-h)
    print_help
  ;;
  *)
    echo "Unknown command: $1"
    print_help
    exit 1
  ;;
esac
