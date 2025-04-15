#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

# Function to check for required environment variables
check_env_var() {
  if [ -z "${!1}" ]; then
    echo "Error: $1 environment variable is not set."
    echo "Please set it using: export $1=<value>"
    exit 1
  fi
}

# Function to install Falcon Image Analyzer
install_image_analyzer() {
  echo "Deploying Falcon Image Analyzer..."

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Creating Helm values override file"
  cat <<EOF > config_values.yaml
deployment:
  enabled: true

image:
  repository: "$ACR_LOGIN_SERVER/$FALCON_IMAGE_ANALYZER_REPO"
  tag: "$FALCON_IMAGE_ANALYZER_TAG_VALUE"

crowdstrikeConfig:
  clientID: "$FALCON_CLIENT_ID"
  clientSecret: "$FALCON_CLIENT_SECRET"
  clusterName: "$CLUSTER_NAME"
  agentRegion: "$FALCON_AGENT_REGION"
  cid: "$FALCON_CID"
EOF

  echo "Deploying Falcon Image Analyzer using Helm"
  helm upgrade --install falcon-image-analyzer crowdstrike/falcon-image-analyzer \
    -n $FALCON_NAMESPACE --create-namespace \
    -f config_values.yaml || exit_on_error "Failed to deploy Falcon Image Analyzer"

  echo "Validating Falcon Image Analyzer Deployment rollout"
  kubectl rollout status deployment falcon-image-analyzer -n $FALCON_NAMESPACE || exit_on_error "Falcon Image Analyzer Deployment rollout failed"

  echo "Falcon Image Analyzer successfully deployed!"
  monitor_pods
}

# Function to uninstall Falcon Image Analyzer
uninstall_image_analyzer() {
  echo "Uninstalling Falcon Image Analyzer..."

  echo "Deleting Falcon Image Analyzer Helm release"
  helm uninstall falcon-image-analyzer -n $FALCON_NAMESPACE || exit_on_error "Failed to uninstall Falcon Image Analyzer"

  echo "Deleting namespace: $FALCON_NAMESPACE"
  kubectl delete namespace $FALCON_NAMESPACE || exit_on_error "Failed to delete namespace"

  echo "Falcon Image Analyzer successfully uninstalled!"
}

# Function to monitor pods and deployments for 5 minutes
monitor_pods() {
  echo "Monitoring pods and deployments in namespace $FALCON_NAMESPACE for 5 minutes..."
  END_TIME=$((SECONDS + 300)) # 300 seconds = 5 minutes

  while [ $SECONDS -lt $END_TIME ]; do
    echo "Fetching current deployments and pods..."
    kubectl get deployments,pods -n $FALCON_NAMESPACE
    echo "Waiting for 30 seconds..."
    sleep 30
  done

  echo "Monitoring completed after 5 minutes."
}

# Check required environment variables
check_env_var "FALCON_CLIENT_ID"
check_env_var "FALCON_CLIENT_SECRET"
check_env_var "FALCON_CID"
check_env_var "CLUSTER_NAME"
check_env_var "FALCON_AGENT_REGION"
check_env_var "ACR_NAME"
check_env_var "FALCON_IMAGE_ANALYZER_REPO"
check_env_var "FALCON_IMAGE_ANALYZER_TAG_VALUE"

# Set variables
FALCON_NAMESPACE="falcon-image-analyzer"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

# Check for the operation argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <deploy|uninstall>"
  exit 1
fi

OPERATION=$1

case $OPERATION in
  deploy)
    install_image_analyzer
    ;;
  uninstall)
    uninstall_image_analyzer
    ;;
  *)
    echo "Invalid operation: $OPERATION. Use 'deploy' or 'uninstall'."
    exit 1
    ;;
esac
