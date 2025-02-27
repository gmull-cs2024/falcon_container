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

# Function to install Falcon KAC
install_kac() {
  echo "Deploying Falcon KAC sensor..."

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  echo "Labeling namespace for privileged access"
  kubectl label namespace $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged --overwrite || exit_on_error "Failed to label namespace"

  echo "Retrieving ACR access token"
  ACR_ACCESS_TOKEN=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken) || exit_on_error "Failed to retrieve ACR access token"

  echo "Creating ACR image pull secret"
  kubectl create secret docker-registry $IMAGE_PULL_SECRET \
    --docker-server=$ACR_LOGIN_SERVER \
    --docker-username="00000000-0000-0000-0000-000000000000" \
    --docker-password="$ACR_ACCESS_TOKEN" \
    --namespace $FALCON_NAMESPACE || echo "Secret already exists"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Deploying Falcon KAC sensor using Helm"
  helm upgrade --install falcon-kac crowdstrike/falcon-kac \
    -n $FALCON_NAMESPACE --create-namespace \
    --set falcon.cid=$FALCON_CID \
    --set image.repository=$FULL_FALCON_KAC_IMAGE_REPO \
    --set image.tag=$FALCON_KAC_TAG_VALUE \
    --set image.pullSecrets=$IMAGE_PULL_SECRET || exit_on_error "Failed to deploy Falcon KAC sensor"

  echo "Validating KAC Deployment rollout"
  kubectl rollout status deployment falcon-kac -n $FALCON_NAMESPACE || exit_on_error "Falcon KAC Deployment rollout failed"

  echo "Falcon KAC sensor successfully deployed!"
  monitor_pods
}

# Function to uninstall Falcon KAC
uninstall_kac() {
  echo "Uninstalling Falcon KAC sensor..."

  echo "Deleting Falcon KAC Helm release"
  helm uninstall falcon-kac -n $FALCON_NAMESPACE || exit_on_error "Failed to uninstall Falcon KAC sensor"

  echo "Deleting namespace: $FALCON_NAMESPACE"
  kubectl delete namespace $FALCON_NAMESPACE || exit_on_error "Failed to delete namespace"

  echo "Falcon KAC sensor successfully uninstalled!"
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
check_env_var "FALCON_CID"
check_env_var "ACR_NAME"
check_env_var "FALCON_KAC_REPO"
check_env_var "FALCON_KAC_TAG_VALUE"

# Set variables
FALCON_NAMESPACE="falcon-kac"
IMAGE_PULL_SECRET="falcon-acr-secret"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
FULL_FALCON_KAC_IMAGE_REPO="${ACR_LOGIN_SERVER}/${FALCON_KAC_REPO}"

# Check for the operation argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <deploy|uninstall>"
  exit 1
fi

OPERATION=$1

case $OPERATION in
  deploy)
    install_kac
    ;;
  uninstall)
    uninstall_kac
    ;;
  *)
    echo "Invalid operation: $OPERATION. Use 'deploy' or 'uninstall'."
    exit 1
    ;;
esac