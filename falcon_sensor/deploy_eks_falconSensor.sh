#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

# Variables
FALCON_NAMESPACE="falcon-system"
IMAGE_PULL_SECRET="falcon-ecr-secret"

# Function to uninstall Falcon sensor
uninstall_falcon_sensor() {
  echo "Uninstalling Falcon sensor deployment"

  echo "Deleting Helm release"
  helm uninstall falcon-sensor -n $FALCON_NAMESPACE || echo "Helm release not found or already deleted"

  echo "Deleting namespace: $FALCON_NAMESPACE"
  kubectl delete namespace $FALCON_NAMESPACE || echo "Namespace not found or already deleted"

  echo "Falcon sensor deployment uninstalled successfully!"
  exit 0
}

# Function to install Falcon sensor
install_falcon_sensor() {
  # Check required environment variables
  if [ -z "$FALCON_CID" ]; then
    echo "Error: FALCON_CID environment variable is not set."
    echo "Please set it using: export FALCON_CID=<your-crowdstrike-cid>"
    exit 1
  fi

  if [ -z "$ECR_REPO_FALCON_SENSOR" ]; then
    echo "Error: ECR_REPO_FALCON_SENSOR environment variable is not set."
    echo "Please set it using: export ECR_REPO_FALCON_SENSOR=<your_ecr_resource_plus_falconsensor_path>"
    exit 1
  fi

  if [ -z "$FALCON_SENSOR_TAG_VALUE" ]; then
    echo "Error: FALCON_SENSOR_TAG_VALUE environment variable is not set."
    echo "Please set it using: export FALCON_SENSOR_TAG_VALUE=<your_falcon_sensor_image_tag>"
    exit 1
  fi

  if [ -z "$AWS_REGION_VALUE" ]; then
    echo "Error: AWS_REGION_VALUE environment variable is not set."
    echo "Please set it using: export AWS_REGION_VALUE=<aws_region_value>"
    exit 1
  fi

  # Set other variables
  EKS_REGION=$AWS_REGION_VALUE
  FALCON_IMAGE_REPO=$ECR_REPO_FALCON_SENSOR
  FALCON_IMAGE_TAG=$FALCON_SENSOR_TAG_VALUE

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  echo "Labeling namespace for privileged access"
  kubectl label namespace $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged --overwrite || exit_on_error "Failed to label namespace"

  echo "Creating ECR image pull secret"
  ECR_PASSWORD=$(aws ecr get-login-password --region $EKS_REGION) || exit_on_error "Failed to get ECR login password"
  kubectl create secret docker-registry $IMAGE_PULL_SECRET \
    --docker-server=$FALCON_IMAGE_REPO \
    --docker-username=AWS \
    --docker-password="$ECR_PASSWORD" \
    --namespace $FALCON_NAMESPACE || echo "Secret already exists"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Deploying Falcon sensor using Helm"
  helm upgrade --install falcon-sensor crowdstrike/falcon-sensor \
    -n $FALCON_NAMESPACE \
    --set falcon.cid=$FALCON_CID \
    --set node.image.repository=$FALCON_IMAGE_REPO \
    --set node.image.tag=$FALCON_IMAGE_TAG \
    --set node.image.pullSecrets=$IMAGE_PULL_SECRET || exit_on_error "Failed to deploy Falcon sensor"

  echo "Validating DaemonSet deployment"
  kubectl rollout status daemonset falcon-sensor -n $FALCON_NAMESPACE || exit_on_error "Falcon sensor DaemonSet deployment failed"

  echo "Falcon sensor successfully deployed!"
  kubectl get daemonset falcon-sensor -n $FALCON_NAMESPACE
}

# Main script logic
if [ "$1" == "uninstall" ]; then
  uninstall_falcon_sensor
else
  install_falcon_sensor
fi