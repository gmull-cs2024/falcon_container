#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "Error: $1"
  exit 1
}

# Variables
FALCON_NAMESPACE="falcon-system"
IMAGE_PULL_SECRET="artifact-registry-secret"

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

  if [ -z "$ARTIFACTORY_REPO_URL" ]; then
    echo "Error: ARTIFACTORY_REPO_URL environment variable is not set."
    echo "Please set it using: export ARTIFACTORY_REPO_URL=<artifact_registry_url>"
    exit 1
  fi

  if [ -z "$FALCON_SENSOR_TAG_VALUE" ]; then
    echo "Error: FALCON_SENSOR_TAG_VALUE environment variable is not set."
    echo "Please set it using: export FALCON_SENSOR_TAG_VALUE=<your_falcon_sensor_image_tag>"
    exit 1
  fi

  if [ -z "$GOOGLE_CLOUD_KEYFILE" ]; then
    echo "Error: GOOGLE_CLOUD_KEYFILE environment variable is not set."
    echo "Please set it using: export GOOGLE_CLOUD_KEYFILE=<path_to_service_account_key_file>"
    exit 1
  fi

  # Authenticate with Google Cloud
  echo "Authenticating with Google Cloud"
  gcloud auth activate-service-account --key-file="$GOOGLE_CLOUD_KEYFILE" || exit_on_error "Failed to authenticate with Google Cloud"
  gcloud auth configure-docker || exit_on_error "Failed to configure Docker for Artifact Registry"

  # Set other variables
  FALCON_IMAGE_REPO=$ARTIFACTORY_REPO_URL
  FALCON_IMAGE_TAG=$FALCON_SENSOR_TAG_VALUE

  echo "Creating namespace: $FALCON_NAMESPACE"
  kubectl create namespace $FALCON_NAMESPACE || echo "Namespace already exists"

  #echo "Labeling namespace for privileged access"
  #kubectl label namespace $FALCON_NAMESPACE pod-security.kubernetes.io/enforce=privileged --overwrite || exit_on_error "Failed to label namespace"

  echo "Creating Artifact Registry image pull secret"
  kubectl create secret docker-registry $IMAGE_PULL_SECRET \
    --docker-server=$(echo $ARTIFACTORY_REPO_URL | cut -d'/' -f1) \
    --docker-username=_json_key \
    --docker-password="$(cat $GOOGLE_CLOUD_KEYFILE)" \
    --namespace $FALCON_NAMESPACE || echo "Secret already exists"

  echo "Adding CrowdStrike Helm repo"
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm || exit_on_error "Failed to add Helm repo"
  helm repo update || exit_on_error "Failed to update Helm repo"

  echo "Deploying Falcon sensor using Helm"
  helm upgrade --install falcon-sensor crowdstrike/falcon-sensor \
    -n $FALCON_NAMESPACE --create-namespace \
    --set falcon.cid=$FALCON_CID \
    --set node.image.repository=$FALCON_IMAGE_REPO \
    --set node.image.tag=$FALCON_IMAGE_TAG \
    --set node.image.pullSecrets=$IMAGE_PULL_SECRET \
    --set node.privileged=false \
    --set node.hostPID=false \
    --set node.hostIPC=false \
    --set node.hostNetwork=false \
    --set node.gke.autopilot=true \
    --set node.capabilities="{AUDIT_WRITE,CHOWN,DAC_OVERRIDE,FOWNER,FSETID,KILL,MKNOD,NET_BIND_SERVICE,NET_RAW,SETFCAP,SETGID,SETPCAP,SETUID,SYS_CHROOT,SYS_PTRACE}" \
    --set node.useHostPathVolume=false \
    --set node.storage.type=emptyDir \
    --set node.backend=bpf || exit_on_error "Failed to deploy Falcon sensor"

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
