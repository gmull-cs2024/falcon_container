# Falcon Sensor Helm Deployment

This repository provides Helm deployment scripts for deploying the CrowdStrike Falcon Sensor on various Kubernetes platforms, including AWS EKS, Azure AKS, Google Cloud GKE, and standard Kubernetes (K8s/K3s).

## Supported Platforms
- **AWS EKS** (Elastic Kubernetes Service)
- **Azure AKS** (Azure Kubernetes Service)
- **Google Cloud GKE** (Google Kubernetes Engine - Standard)
- **Standard Kubernetes / K3s**

---

# Deployment Guide

## AWS EKS Deployment

### Environment Setup
Set the required environment variables before deploying to AWS EKS:

```bash
export FALCON_CID=<falcon_cid_value>                       # Note: Include the -XX value
export ECR_REPO_FALCON_SENSOR="<aws_ecr_repo_path>"        # Example: 123456789012.dkr.ecr.us-east-2.amazonaws.com/falcon-sensor/us-1/release/falcon-sensor
export FALCON_SENSOR_TAG_VALUE="<falcon_sensor_tag_value>" # Example: 7.19.0-17219-1.falcon-linux.Release.US-1
export AWS_REGION_VALUE="<aws_region>"                     # Example: us-east-2
```

### Deployment
Run the following script to deploy Falcon Sensor on AWS EKS:
```bash
./deploy_eks_falconSensor.sh
```

### Uninstall
To uninstall Falcon Sensor from AWS EKS:
```bash
./deploy_eks_falconSensor.sh uninstall
```

---

## Azure AKS Deployment

### Environment Setup
Set the required environment variables for Azure AKS:

```bash
export FALCON_CID=<falcon_cid_value>  # Note: Include the -XX value
export FALCON_SENSOR_REPO="falcon-sensor"
export FALCON_SENSOR_TAG_VALUE="7.21.0-17405-1.falcon-linux.Release.US-1"
export ACR_NAME="<acr_name>"  # ACR Name (do not include 'azurecr.io')
export AZURE_RG_NAME="<azure_resource_group>" # Azure Resource Group Name
export AZURE_CLUSTER_NAME="<azure_aks_cluster_name>"  # Azure AKS Cluster Name
```

### Connect to AKS Cluster
Authenticate and connect to your AKS cluster:
```bash
az aks get-credentials --resource-group $AZURE_RG_NAME --name $AZURE_CLUSTER_NAME
```

### Validate Connection
Ensure you are connected to the AKS cluster:
```bash
kubectl get nodes
```

### Deployment
Deploy Falcon Sensor on Azure AKS:
```bash
./deploy_aks_falconSensor.sh
```

### Uninstall
To remove Falcon Sensor from AKS:
```bash
./deploy_aks_falconSensor.sh uninstall
```

---

## Google Cloud GKE Deployment

### Environment Setup
Set up the necessary environment variables for Google Cloud GKE:

```bash
export FALCON_CID=<falcon_cid_value>  # Note: Include the -XX value
export FALCON_SENSOR_REPO="falcon-sensor"
export FALCON_SENSOR_TAG_VALUE="<falcon_sensor_tag_value>"  # Example: 7.19.0-17219-1.falcon-linux.Release.US-1
export GKE_CLUSTER_NAME="<gke_cluster_name>"
export GCP_PROJECT_ID="<gcp_project_id>"
export GCP_REGION="<gcp_region>"
```

### Connect to GKE Cluster
Authenticate and retrieve cluster credentials:
```bash
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --region $GCP_REGION --project $GCP_PROJECT_ID
```

### Validate Connection
Ensure you are connected to the GKE cluster:
```bash
kubectl get nodes
```

### Deployment
Deploy Falcon Sensor on GKE:
```bash
./deploy_gke_falconSensor.sh
```

### Uninstall
To remove Falcon Sensor from GKE:
```bash
./deploy_gke_falconSensor.sh uninstall
```

---

## Standard Kubernetes / K3s Deployment

### Environment Setup
Set up the necessary environment variables:

```bash
export FALCON_CID=<falcon_cid_value>  # Note: Include the -XX value
export FALCON_SENSOR_REPO="falcon-sensor"
export FALCON_SENSOR_TAG_VALUE="<falcon_sensor_tag_value>"
```

### Connect to Kubernetes Cluster
Ensure `kubectl` is configured to communicate with your cluster:
```bash
kubectl config current-context
```

### Validate Connection
Verify cluster connectivity:
```bash
kubectl get nodes
```

### Deployment
Deploy Falcon Sensor on a standard Kubernetes cluster:
```bash
./deploy_k8s_falconSensor.sh
```

### Uninstall
To remove Falcon Sensor from Kubernetes:
```bash
./deploy_k8s_falconSensor.sh uninstall
```

---

## Example Deployment Output

Below is an example of a successful Falcon Sensor deployment:

### AWS

```bash
./deploy_eks_falconSensor.sh
Creating namespace: falcon-system
namespace/falcon-system created
Labeling namespace for privileged access
namespace/falcon-system labeled
Creating ECR image pull secret
secret/falcon-ecr-secret created
Adding CrowdStrike Helm repo
"crowdstrike" already exists with the same configuration, skipping
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "crowdstrike" chart repository
Update Complete. ⎈Happy Helming!⎈
Deploying Falcon sensor using Helm
Release "falcon-sensor" does not exist. Installing it now.
NAME: falcon-sensor
LAST DEPLOYED: Thu Dec 12 12:40:29 2024
NAMESPACE: falcon-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the CrowdStrike Falcon Helm Chart!

CrowdStrike Falcon sensors will deploy across all nodes in your Kubernetes cluster after
installing this Helm chart.

Validating DaemonSet deployment
Waiting for daemon set "falcon-sensor" rollout to finish...
daemon set "falcon-sensor" successfully rolled out
Falcon sensor successfully deployed!
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
falcon-sensor   2         2         2       2            2           kubernetes.io/os=linux   6s
```

### Azure

```bash
./deploy_aks_falconSensor_v2.sh
🆕 Creating namespace: falcon-system
namespace/falcon-system created
🔖 Labeling namespace for privileged access
namespace/falcon-system labeled
🔑 Retrieving ACR access token
WARNING: You can perform manual login using the provided access token below, for example: 'docker login loginServer -u 00000000-0000-0000-0000-000000000000 -p accessToken'
🔐 Creating ACR image pull secret
secret/falcon-acr-secret created
🔄 Updating Helm repo
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "crowdstrike" chart repository
Update Complete. ⎈Happy Helming!⎈
🚀 Deploying Falcon sensor using Helm
Release "falcon-sensor" does not exist. Installing it now.
NAME: falcon-sensor
LAST DEPLOYED: Mon Mar  3 19:48:44 2025
NAMESPACE: falcon-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the CrowdStrike Falcon Helm Chart!

Access to the Falcon Linux and Container Sensor downloads at registry.crowdstrike.com are
required to complete the install of this Helm chart. If an internal registry is used instead of registry.crowdstrike.com.
the containerized sensor must be present in a container registry accessible from Kubernetes installation.
CrowdStrike Falcon sensors will deploy across all nodes in your Kubernetes cluster after
installing this Helm chart. The default image name to deploy a kernel sensor to a node is `falcon-node-sensor`.

When utilizing your own registry, an extremely common error on installation is accidentally forgetting to add your containerized
sensor to your local image registry prior to executing `helm install`. Please read the Helm Chart's readme
for more deployment considerations.
✅ Validating DaemonSet deployment
Waiting for daemon set "falcon-sensor" rollout to finish: 0 of 2 updated pods are available...
Waiting for daemon set "falcon-sensor" rollout to finish: 1 of 2 updated pods are available...
daemon set "falcon-sensor" successfully rolled out
🎉 Falcon sensor successfully deployed!
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
falcon-sensor   2         2         2       2            2           kubernetes.io/os=linux   4s
NAME                  READY   STATUS    RESTARTS   AGE
falcon-sensor-8fvbc   1/1     Running   0          5s
falcon-sensor-v74p9   1/1     Running   0          5s
```

---

## Troubleshooting
- Ensure you have the correct cluster credentials before deploying.
- Verify Helm is installed and the CrowdStrike Helm repository is added.
- Check Kubernetes logs for any errors using:
  ```bash
  kubectl logs -n falcon-system -l app=falcon-sensor
  ```
- Validate that required environment variables are correctly set before execution.

---

## Additional Resources
- [CrowdStrike Falcon Sensor Documentation](https://github.com/CrowdStrike/falcon-helm/tree/main/helm-charts/falcon-sensor)
- [Helm Chart Repository](https://helm.sh/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Google Cloud GKE Documentation](https://cloud.google.com/kubernetes-engine/docs/)
