#!/bin/bash

set -euo pipefail

# ---------------------------
# Configurable Variables (REQUIRED TO BE SET)
# ---------------------------
: "${FALCON_CID:?Environment variable FALCON_CID must be set}"
: "${FULL_FALCON_IMAGE_REPO:?Environment variable FULL_FALCON_IMAGE_REPO must be set}"
: "${FALCON_IMAGE_TAG:?Environment variable FALCON_IMAGE_TAG must be set}"
: "${IMAGE_PULL_SECRET:?Environment variable IMAGE_PULL_SECRET must be set}"
: "${ACR_NAME:?Environment variable ACR_NAME must be set}"

FALCON_NAMESPACE="falcon-system"
VALUES_TEMPLATE="falcon-values.yaml"
RESOLVED_VALUES="falcon-values.resolved.yaml"

# ---------------------------
# Uninstall Logic
# ---------------------------
if [[ "${1:-}" == "uninstall" ]]; then
  echo "🗑️ Uninstalling Falcon Sensor..."

  if helm list -n "$FALCON_NAMESPACE" | grep -q falcon-sensor; then
    echo "🚨 Removing Helm release"
    helm uninstall falcon-sensor -n "$FALCON_NAMESPACE"
  else
    echo "ℹ️ No Helm release found to uninstall"
  fi

  echo "🧹 Cleaning up namespace: $FALCON_NAMESPACE"
  kubectl delete namespace "$FALCON_NAMESPACE" --ignore-not-found

  echo "✅ Falcon Sensor uninstalled successfully."
  exit 0
fi

# ---------------------------
# Namespace Setup
# ---------------------------
echo "📁 Creating namespace if not present: $FALCON_NAMESPACE"
kubectl get namespace "$FALCON_NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$FALCON_NAMESPACE"

echo "🏷️ Labeling namespace with privileged policy"
kubectl label namespace "$FALCON_NAMESPACE" pod-security.kubernetes.io/enforce=privileged --overwrite

# ---------------------------
# ACR Image Pull Secret Setup
# ---------------------------
echo "🔐 Creating ACR image pull secret if not exists"
if ! kubectl get secret "$IMAGE_PULL_SECRET" -n "$FALCON_NAMESPACE" >/dev/null 2>&1; then
  ACR_ACCESS_TOKEN=$(az acr login --name "$ACR_NAME" --expose-token --output tsv --query accessToken)
  kubectl create secret docker-registry "$IMAGE_PULL_SECRET" \
    --docker-server="$ACR_NAME.azurecr.io" \
    --docker-username="00000000-0000-0000-0000-000000000000" \
    --docker-password="$ACR_ACCESS_TOKEN" \
    --namespace "$FALCON_NAMESPACE"
else
  echo "ℹ️ Image pull secret already exists: $IMAGE_PULL_SECRET"
fi

# ---------------------------
# Helm Repo Setup
# ---------------------------
echo "📦 Ensuring CrowdStrike Helm repo is added"
if ! helm repo list | grep -q crowdstrike; then
  helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
fi
helm repo update

# ---------------------------
# Generate Values File
# ---------------------------
echo "📄 Generating resolved Helm values file"
cat > "$VALUES_TEMPLATE" <<EOF
falcon:
  cid: "\${FALCON_CID}"

node:
  image:
    repository: "\${FULL_FALCON_IMAGE_REPO}"
    tag: "\${FALCON_IMAGE_TAG}"
    pullSecrets: "\${IMAGE_PULL_SECRET}"
  daemonset:
    tolerations:
      - key: "CriticalAddonsOnly"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
EOF

envsubst < "$VALUES_TEMPLATE" > "$RESOLVED_VALUES"
cat "$RESOLVED_VALUES"

# ---------------------------
# Deploy with Helm
# ---------------------------
echo "🚀 Deploying Falcon Sensor with Helm..."
helm upgrade --install falcon-sensor crowdstrike/falcon-sensor \
  -n "$FALCON_NAMESPACE" \
  -f "$RESOLVED_VALUES"

# ---------------------------
# Post-deploy Validation
# ---------------------------
echo "🔍 Validating deployment..."

kubectl rollout status daemonset falcon-sensor -n "$FALCON_NAMESPACE" || {
  echo "❌ DaemonSet rollout failed"
  exit 1
}

echo "✅ Tolerations applied:"
kubectl describe daemonset falcon-sensor -n "$FALCON_NAMESPACE" | grep -A5 Tolerations

echo "📦 Pod status:"
kubectl get pods -n "$FALCON_NAMESPACE" -o wide

echo "✅ Deployment complete!"
