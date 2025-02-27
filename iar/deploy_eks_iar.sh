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

# Function to deploy Falcon Image Analyzer (IAR)
deploy_iar() {
  echo "Deploying Falcon Image Analyzer..."

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  echo "Setting Pod Security Standards for the namespace"
  kubectl label --overwrite ns $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged || exit_on_error "Failed to label namespace"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Deploying Falcon Image Analyzer using Helm"
  helm upgrade --install falcon-iar crowdstrike/falcon-image-analyzer \
    -n $FALCON_NAMESPACE --create-namespace \
    --set deployment.enabled=$DEPLOYMENT_MODE \
    --set daemonset.enabled=$DAEMONSET_MODE \
    --set image.repository=$IMAGE_REPO \
    --set image.tag=$IMAGE_TAG \
    --set crowdstrikeConfig.clusterName=$CLUSTER_NAME \
    --set crowdstrikeConfig.cid=$FALCON_CID \
    --set crowdstrikeConfig.clientID=$CLIENT_ID \
    --set crowdstrikeConfig.clientSecret=$CLIENT_SECRET \
    --set crowdstrikeConfig.agentRegion=$AGENT_REGION \
    --set crowdstrikeConfig.enableKlogs=$ENABLE_KLOGS \
    --set volumes[0].name=tmp-volume \
    --set volumes[0].emptyDir.sizeLimit=$TMP_VOLUME_SIZE || exit_on_error "Failed to deploy Falcon Image Analyzer"

  echo "Validating deployment"
  kubectl rollout status deployment falcon-iar -n $FALCON_NAMESPACE || exit_on_error "Falcon Image Analyzer deployment failed"

  echo "Falcon Image Analyzer successfully deployed!"
  kubectl get deployments,pods -n $FALCON_NAMESPACE
}

# Function to uninstall Falcon Image Analyzer
uninstall_iar() {
  echo "Uninstalling Falcon Image Analyzer..."

  echo "Deleting Falcon Image Analyzer Helm release"
  helm uninstall falcon-iar -n $FALCON_NAMESPACE || exit_on_error "Failed to uninstall Falcon Image Analyzer"

  echo "Deleting namespace: $FALCON_NAMESPACE"
  kubectl delete namespace $FALCON_NAMESPACE || exit_on_error "Failed to delete namespace"

  echo "Falcon Image Analyzer successfully uninstalled!"
}

# Check required environment variables
check_env_var "FALCON_CID"
check_env_var "CLIENT_ID"
check_env_var "CLIENT_SECRET"
check_env_var "IMAGE_REPO"
check_env_var "IMAGE_TAG"
check_env_var "AGENT_REGION"
check_env_var "CLUSTER_NAME"
check_env_var "FALCON_IAR_NAMESPACE"

# Set variables
FALCON_NAMESPACE=$FALCON_IAR_NAMESPACE
DEPLOYMENT_MODE=${DEPLOYMENT_MODE:-true} # Default to deployment mode
DAEMONSET_MODE=${DAEMONSET_MODE:-false}  # Default to daemonset disabled
ENABLE_KLOGS=${ENABLE_KLOGS:-false}      # Default klogs disabled
TMP_VOLUME_SIZE=${TMP_VOLUME_SIZE:-20Gi} # Default temp volume size

# Check for the operation argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <deploy|uninstall>"
  exit 1
fi

OPERATION=$1

case $OPERATION in
  deploy)
    deploy_iar
    ;;
  uninstall)
    uninstall_iar
    ;;
  *)
    echo "Invalid operation: $OPERATION. Use 'deploy' or 'uninstall'."
    exit 1
    ;;
esac
