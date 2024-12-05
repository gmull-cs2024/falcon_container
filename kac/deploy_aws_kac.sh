#!/bin/bash

# Check if FALCON_CID is provided
if [ -z "$FALCON_CID" ]; then
  echo "Error: FALCON_CID environment variable is not set."
  echo "Please set it using: export FALCON_CID=<your-crowdstrike-cid>"
  exit 1
fi

# Check if AWS ECR is provided
if [ -z "$ECR_REPO_KAC" ]; then
  echo "Error: ECR_REPO_KAC environment variable is not set."
  echo "Please set it using: export ECR_REPO_KAC=<your_ecr_resource_plus_kac_path>"
  exit 1
fi

# Check if AWS ECR is provided
if [ -z "$KAC_IMAGE_TAG_VALUE" ]; then
  echo "Error: KAC_IMAGE_TAG_VALUE environment variable is not set."
  echo "Please set it using: export ECR_RC_IMAGE_TAG_VALUE=<your_kac_image_tag>"
  exit 1
fi

# Check if AWS REGION is provided
if [ -z "$AWS_REGION_VALUE" ]; then
  echo "Error: AWS_REGION_VALUE environment variable is not set."
  echo "Please set it using: export AWS_REGION_VALUE=<aws_region_value>"
  exit 1
fi

# Set other variables
EKS_REGION=$AWS_REGION_VALUE # Example: us-east-2
FALCON_NAMESPACE="falcon-kac"
IMAGE_PULL_SECRET="falcon-ecr-secret"
KAC_IMAGE_REPO=$ECR_REPO_KAC # Example: 123456789012.dkr.ecr.us-east-2.amazonaws.com/falcon-kac/us-1/release/falcon-kac
KAC_IMAGE_TAG=$KAC_IMAGE_TAG_VALUE # Example: 
# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

echo "Creating namespace: $FALCON_NAMESPACE"
kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

echo "Labeling namespace for privileged access"
kubectl label namespace $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged --overwrite || exit_on_error "Failed to label namespace"

echo "Adding CrowdStrike Helm repo"
helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
helm repo update || exit_on_error "Failed to update Helm repo"

echo "Deploying Falcon KAC sensor using Helm"
helm upgrade --install falcon-kac crowdstrike/falcon-kac \
  -n $FALCON_NAMESPACE --create-namespace \
  --set falcon.cid=$FALCON_CID \
  --set image.repository=$KAC_IMAGE_REPO \
  --set image.tag=$KAC_IMAGE_TAG || exit_on_error "Failed to deploy Falcon KAC sensor"

echo "Validating KAC DaemonSet deployment"
kubectl rollout status daemonset falcon-kac -n $FALCON_NAMESPACE || exit_on_error "Falcon KAC DaemonSet deployment failed"

echo "Falcon KAC sensor successfully deployed!"
kubectl get deployments,pods -n $FALCON_NAMESPACE

echo "Falcon KAC has the following AID:"
kubectl exec deployment/falcon-kac -n falcon-kac -c falcon-ac -- falconctl -g --aid