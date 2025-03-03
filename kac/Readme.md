# Kubernetes Admission Controller (KAC) Deployment

This repository provides deployment scripts for deploying the **Kubernetes Admission Controller (KAC)** across multiple cloud platforms using **Helm**.

## Supported Platforms
- **AWS EKS**
- **Azure AKS**
- **Google Cloud GKE (Standard)**

Each cloud provider has its own directory containing a deployment script and detailed instructions.

---

## **Deployment Instructions**

### **AWS EKS**
- Navigate to the **`aws/`** folder.
- Follow instructions in **`aws/README.md`**.

```bash
cd aws/
./deploy_eks_kac.sh deploy
```

### **Azure AKS**
- Navigate to the **`azure/`** folder.
- Follow instructions in **`azure/README.md`**.

```bash
cd azure/
./deploy_aks_kac.sh deploy
```

### **Google Cloud GKE**
- Navigate to the **`gcp/`** folder.
- Follow instructions in **`gcp/README.md`**.

```bash
cd gcp/
./deploy_gke_kac.sh deploy
```

---

## **Uninstallation**
To remove KAC from any cluster, run the appropriate `uninstall` command:

```bash
./deploy_<platform>_kac.sh uninstall
```
Example for AWS:
```bash
cd aws/
./deploy_eks_kac.sh uninstall
```

---

## **Troubleshooting**
- Ensure you have the correct cluster credentials before deploying.
- Check Kubernetes logs if the deployment fails:
  ```bash
  kubectl logs -n falcon-kac -l app=falcon-kac
  ```
- Verify Helm and Kubernetes CLI (`kubectl`) are installed.

---

## **Additional Resources**
- [Kubernetes Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Helm Documentation](https://helm.sh/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [GCP GKE Documentation](https://cloud.google.com/kubernetes-engine/docs/)
```

---

### **`aws/README.md`**
```markdown
# AWS EKS - Kubernetes Admission Controller (KAC) Deployment

## **Prerequisites**
- AWS CLI installed and configured
- `kubectl` configured for EKS
- Helm installed
- An AWS ECR registry for storing container images

---

## **Deployment Steps**
### 1. **Set Environment Variables**
```bash
export AWS_REGION_VALUE="us-east-2"
export KAC_IMAGE_REPO="<aws_ecr_repo_path>"
export KAC_IMAGE_TAG="v1.0.0"
```

### 2. **Run Deployment Script**
```bash
./deploy_eks_kac.sh deploy
```

### 3. **Verify Deployment**
```bash
kubectl get pods -n falcon-kac
```

### **Uninstall**
```bash
./deploy_eks_kac.sh uninstall
```
```

---

### **`azure/README.md`**
```markdown
# Azure AKS - Kubernetes Admission Controller (KAC) Deployment

## **Prerequisites**
- Azure CLI installed and configured
- `kubectl` configured for AKS
- Helm installed
- An Azure Container Registry (ACR) for storing container images

---

## **Deployment Steps**
### 1. **Set Environment Variables**
```bash
export ACR_NAME="<acr_name>"
export AZURE_RG_NAME="<resource_group>"
export AZURE_CLUSTER_NAME="<aks_cluster_name>"
export KAC_IMAGE_TAG="v1.0.0"
```

### 2. **Authenticate and Connect to AKS**
```bash
az aks get-credentials --resource-group $AZURE_RG_NAME --name $AZURE_CLUSTER_NAME
```

### 3. **Run Deployment Script**
```bash
./deploy_aks_kac.sh deploy
```

### 4. **Verify Deployment**
```bash
kubectl get pods -n falcon-kac
```

### **Uninstall**
```bash
./deploy_aks_kac.sh uninstall
```
```

---

### **`gcp/README.md`**
```markdown
# Google Cloud GKE - Kubernetes Admission Controller (KAC) Deployment

## **Prerequisites**
- Google Cloud CLI (`gcloud`) installed and configured
- `kubectl` configured for GKE
- Helm installed
- A Google Container Registry (GCR) for storing container images

---

## **Deployment Steps**
### 1. **Set Environment Variables**
```bash
export GKE_CLUSTER_NAME="<gke_cluster_name>"
export GCP_PROJECT_ID="<gcp_project_id>"
export GCP_REGION="<gcp_region>"
export KAC_IMAGE_TAG="v1.0.0"
```

### 2. **Authenticate and Connect to GKE**
```bash
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --region $GCP_REGION --project $GCP_PROJECT_ID
```

### 3. **Run Deployment Script**
```bash
./deploy_gke_kac.sh deploy
```

### 4. **Verify Deployment**
```bash
kubectl get pods -n falcon-kac
```

### **Uninstall**
```bash
./deploy_gke_kac.sh uninstall
```
```

---

### **Deployment Scripts**
Each script (`deploy_eks_kac.sh`, `deploy_aks_kac.sh`, `deploy_gke_kac.sh`) will:
1. **Set up the namespace** (`falcon-kac`).
2. **Create image pull secrets**.
3. **Deploy KAC using Helm**.
4. **Monitor the deployment rollout**.
5. **Provide logs for troubleshooting**.

---

### **Next Steps**
- Integrate with CI/CD pipelines for automated deployment.
- Add monitoring and alerting for failed admission controller events.

