#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

# Validate dependencies
command -v kubectl >/dev/null 2>&1 || exit_on_error "kubectl is required but not installed."
command -v helm >/dev/null 2>&1 || exit_on_error "helm is required but not installed."
command -v az >/dev/null 2>&1 || exit_on_error "Azure CLI is required but not installed."

# Variables
FALCON_NAMESPACE="falcon-system"
IMAGE_PULL_SECRET="falcon-acr-secret"
AZURE_KEYVAULT_NAME="<your-keyvault-name>"   # Replace with your actual Key Vault name
FALCON_CID_SECRET_NAME="FalconCID"            # Name of the secret in Key Vault

# Function to retrieve Falcon CID from Azure Key Vault
retrieve_falcon_cid() {
  echo "Retrieving Falcon CID from Azure Key Vault..."
  FALCON_CID=$(az keyvault secret show --name $FALCON_CID_SECRET_NAME --vault-name $AZURE_KEYVAULT_NAME --query value -o tsv) || exit_on_error "Failed to retrieve Falcon CID from Azure Key Vault."
}

# Uninstall function
uninstall_falcon_sensor() {
  echo "Uninstalling Falcon sensor deployment..."
  helm uninstall falcon-sensor -n $FALCON_NAMESPACE || echo "Helm release not found or already deleted."
  kubectl delete namespace $FALCON_NAMESPACE --ignore-not-found=true
  echo "Falcon sensor deployment uninstalled successfully!"
  exit 0
}

# Install function
install_falcon_sensor() {
  # Retrieve Falcon CID from Azure Key Vault
  retrieve_falcon_cid

  # Validate required environment variables
  for var in FALCON_CID ACR_NAME FALCON_SENSOR_REPO FALCON_SENSOR_TAG_VALUE; do
    if [ -z "${!var}" ]; then
      exit_on_error "Environment variable $var is not set."
    fi
  done

  # Construct ACR details
  ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"
  FULL_FALCON_IMAGE_REPO="${ACR_LOGIN_SERVER}/${FALCON_SENSOR_REPO}"
  FALCON_IMAGE_TAG=$FALCON_SENSOR_TAG_VALUE

  # Create namespace (idempotent)
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $FALCON_NAMESPACE
  labels:
    pod-security.kubernetes.io/enforce: privileged
EOF

  # Authenticate with ACR
  echo "Retrieving ACR access token..."
  ACR_ACCESS_TOKEN=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken) || exit_on_error "Failed to retrieve ACR access token."

  # Create/update the image pull secret
  kubectl delete secret $IMAGE_PULL_SECRET -n $FALCON_NAMESPACE --ignore-not-found=true
  kubectl create secret docker-registry $IMAGE_PULL_SECRET \
    --docker-server=$ACR_LOGIN_SERVER \
    --docker-username="00000000-0000-0000-0000-000000000000" \
    --docker-password="$ACR_ACCESS_TOKEN" \
    --namespace $FALCON_NAMESPACE || exit_on_error "Failed to create image pull secret."

  # Helm repo setup
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm --force-update || exit_on_error "Failed to add/update Helm repo."

  # Deploy Falcon sensor
  echo "Deploying Falcon sensor..."
  helm upgrade --install falcon-sensor crowdstrike/falcon-sensor \
    -n $FALCON_NAMESPACE \
    --set falcon.cid=$FALCON_CID \
    --set node.image.repository=$FULL_FALCON_IMAGE_REPO \
    --set node.image.tag=$FALCON_IMAGE_TAG \
    --set node.image.pullSecrets=$IMAGE_PULL_SECRET || exit_on_error "Failed to deploy Falcon sensor."

  # Validate DaemonSet deployment
  echo "Validating deployment..."
  kubectl rollout status daemonset falcon-sensor -n $FALCON_NAMESPACE || exit_on_error "DaemonSet deployment failed."
  
  echo "Falcon sensor successfully deployed!"
  kubectl get daemonset falcon-sensor -n $FALCON_NAMESPACE
}

# Main execution logic
case "$1" in
  uninstall)
    uninstall_falcon_sensor
    ;;
  *)
    install_falcon_sensor
    ;;
esac
