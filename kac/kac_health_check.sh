#!/bin/bash

# Function to exit on error
exit_on_error() {
  echo "❌ Error: $1"
  exit 1
}

# Function to create a temporary debug pod
create_debug_pod() {
  echo "🔍 Creating a temporary debug pod..."

  # Run the pod in the background
  kubectl run debug-container --image=curlimages/curl --restart=Never --namespace="$FALCON_NAMESPACE" -- sleep 300 &>/dev/null

  # Wait for the pod to be ready
  echo "⏳ Waiting for debug pod to be ready..."
  kubectl wait --for=condition=Ready pod/debug-container -n "$FALCON_NAMESPACE" --timeout=30s || exit_on_error "Debug pod failed to start."
}

# Function to check service availability
check_service() {
  echo "🔍 Checking if Falcon KAC service is accessible..."

  # Ensure service exists
  kubectl get svc falcon-kac -n "$FALCON_NAMESPACE" &>/dev/null || exit_on_error "Falcon KAC service not found."

  # Ensure DNS resolution works
  kubectl exec -n "$FALCON_NAMESPACE" debug-container -- nslookup falcon-kac.falcon-kac.svc.cluster.local || exit_on_error "DNS resolution for Falcon KAC service failed."

  echo "✅ Falcon KAC service is accessible."
}

# Function to check liveness endpoints using debug pod
check_liveness_from_debug_pod() {
  echo "🔍 Checking Falcon KAC liveness endpoints from a debug pod..."

  # Define health check URLs
  LIVENESS_CLIENT="https://falcon-kac.falcon-kac.svc.cluster.local:4443/livez"
  LIVENESS_WATCHER="http://falcon-kac.falcon-kac.svc.cluster.local:4080/livez"
  LIVENESS_AC="https://falcon-kac.falcon-kac.svc.cluster.local:4443/livez-kac"

  # Function to perform HTTP check
  perform_http_check() {
    local URL=$1
    local DESC=$2

    echo "▶ Checking $DESC at $URL..."

    RESPONSE=$(kubectl exec -n "$FALCON_NAMESPACE" debug-container -- curl -sk -o /dev/null -w "%{http_code}" "$URL")

    if [[ "$RESPONSE" == "200" ]]; then
      echo "✅ $DESC is healthy (HTTP 200)."
    else
      exit_on_error "$DESC health check failed! HTTP response: $RESPONSE"
    fi
  }

  # Run checks from debug container
  perform_http_check "$LIVENESS_CLIENT" "falcon-client"
  perform_http_check "$LIVENESS_WATCHER" "falcon-watcher"
  perform_http_check "$LIVENESS_AC" "falcon-ac"

  echo "✅ All Falcon KAC liveness probes are healthy!"
}

# Ensure required environment variables are set
if [[ -z "$FALCON_NAMESPACE" ]]; then
  exit_on_error "Required environment variable FALCON_NAMESPACE is not set."
fi

# Run health checks
create_debug_pod
check_service
check_liveness_from_debug_pod

# Cleanup the debug pod after checks
kubectl delete pod debug-container -n "$FALCON_NAMESPACE" --force --grace-period=0 &>/dev/null

echo "🎉 ✅ Falcon KAC health check PASSED!"