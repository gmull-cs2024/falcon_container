#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

# Variables
FALCON_NAMESPACE="falcon-system"
IMAGE_PULL_SECRET="falcon-registry-secret"

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

  if [ -z "$REGISTRY_URL" ]; then
    echo "Error: REGISTRY_URL environment variable is not set."
    echo "Please set it using: export REGISTRY_URL=<your_registry_url>"
    exit 1
  fi

  if [ -z "$REGISTRY_USERNAME" ]; then
    echo "Error: REGISTRY_USERNAME environment variable is not set."
    echo "Please set it using: export REGISTRY_USERNAME=<your_registry_username>"
    exit 1
  fi

  if [ -z "$REGISTRY_PASSWORD" ]; then
    echo "Error: REGISTRY_PASSWORD environment variable is not set."
    echo "Please set it using: export REGISTRY_PASSWORD=<your_registry_password>"
    exit 1
  fi

  if [ -z "$FALCON_SENSOR_REPO" ]; then
    echo "Error: FALCON_SENSOR_REPO environment variable is not set."
    echo "Please set it using: export FALCON_SENSOR_REPO=<registry_repo_path>"
    exit 1
  fi

  if [ -z "$FALCON_SENSOR_TAG_VALUE" ]; then
    echo "Error: FALCON_SENSOR_TAG_VALUE environment variable is not set."
    echo "Please set it using: export FALCON_SENSOR_TAG_VALUE=<image_tag>"
    exit 1
  fi

  # Construct the full image repository path
  FULL_FALCON_IMAGE_REPO="${REGISTRY_URL}/${FALCON_SENSOR_REPO}"
  FALCON_IMAGE_TAG=$FALCON_SENSOR_TAG_VALUE

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  echo "Labeling namespace for privileged access"
  kubectl label namespace $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged --overwrite || exit_on_error "Failed to label namespace"

  echo "Creating image pull secret"
  kubectl create secret docker-registry $IMAGE_PULL_SECRET \
    --docker-server=$REGISTRY_URL \
    --docker-username=$REGISTRY_USERNAME \
    --docker-password=$REGISTRY_PASSWORD \
    --namespace $FALCON_NAMESPACE || echo "Secret already exists"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Deploying Falcon sensor using Helm"
  helm upgrade --install falcon-sensor crowdstrike/falcon-sensor \
    -n $FALCON_NAMESPACE \
    --set falcon.cid=$FALCON_CID \
    --set node.image.repository=$FULL_FALCON_IMAGE_REPO \
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
