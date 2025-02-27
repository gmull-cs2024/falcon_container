# Falcon KAC Health Check Script

## Overview
This script is designed to verify the health and accessibility of the Falcon KAC service running in an AKS (Azure Kubernetes Service) environment. It ensures that the service is reachable, DNS resolution is working, and all liveness endpoints are responding correctly.

## Features
- **Creates a Debug Pod**: A temporary `curl`-based pod is created to perform network tests.
- **Verifies Service Availability**: Checks if the `falcon-kac` service exists and is resolvable via DNS.
- **Performs Liveness Probes**: Sends HTTP requests to various Falcon KAC endpoints to confirm they are responding.
- **Automatic Cleanup**: Ensures the debug pod is deleted after checks are completed.
- **Parallelized Health Checks**: Runs multiple liveness checks concurrently to improve efficiency.

## Prerequisites
Before running the script, ensure:
- You have `kubectl` installed and configured to access the Kubernetes cluster.
- Your environment has `curl` installed.
- The `FALCON_NAMESPACE` environment variable is set to the namespace where Falcon KAC is deployed.

## Usage
1. **Set the required environment variable:**
   ```sh
   export FALCON_NAMESPACE=<your-namespace>
   ```
2. **Run the script:**
   ```sh
   ./falcon_kac_healthcheck.sh
   ```

## Health Checks Performed
1. **Debug Pod Creation**: A temporary pod (`debug-container`) is created using the `curlimages/curl` image.
2. **Service Accessibility Check**:
   - Verifies the `falcon-kac` service exists in the cluster.
   - Ensures DNS resolution works using `nslookup`.
3. **Liveness Probes**:
   - Checks Falcon Client (`/livez` on port 4443 - HTTPS)
   - Checks Falcon Watcher (`/livez` on port 4080 - HTTP)
   - Checks Falcon AC (`/livez-kac` on port 4443 - HTTPS)
4. **Cleanup**: The debug pod is deleted upon completion.

## Expected Output
If all checks pass, you should see:
```
✅ Falcon KAC service is accessible.
✅ falcon-client is healthy (HTTP 200).
✅ falcon-watcher is healthy (HTTP 200).
✅ falcon-ac is healthy (HTTP 200).
🎉 ✅ Falcon KAC health check PASSED!
```
If any check fails, the script will exit with an error message.

## Troubleshooting
- If the debug pod fails to start, ensure your cluster has enough resources.
- If the service check fails, verify that `falcon-kac` is correctly deployed.
- If a liveness probe fails, check the corresponding Falcon KAC component logs.

## Cleanup
The script automatically removes the debug pod upon completion. However, if needed, you can manually delete it using:
```sh
kubectl delete pod debug-container -n "$FALCON_NAMESPACE" --force --grace-period=0
```
