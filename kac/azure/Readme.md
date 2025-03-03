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

### 2. **Authenticate with Azure and Connect to AKS**
```bash
az login
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

#### **Example Deploment**

```bash
./deploy_kac_sensor.sh deploy
Deploying Falcon KAC sensor...
Creating namespace: falcon-kac
namespace/falcon-kac created
Labeling namespace for privileged access
namespace/falcon-kac labeled
Retrieving ACR access token
WARNING: You can perform manual login using the provided access token below, for example: 'docker login loginServer -u 00000000-0000-0000-0000-000000000000 -p accessToken'
Creating ACR image pull secret
secret/falcon-acr-secret created
Adding CrowdStrike Helm repo
"crowdstrike" already exists with the same configuration, skipping
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "crowdstrike" chart repository
Update Complete. ⎈Happy Helming!⎈
Deploying Falcon KAC sensor using Helm
Release "falcon-kac" does not exist. Installing it now.
NAME: falcon-kac
LAST DEPLOYED: Mon Mar  3 19:56:49 2025
NAMESPACE: falcon-kac
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing the CrowdStrike Falcon Kubernetes Admission Controller!

Note that in order for the Falcon Kubernetes Admissions Controller to run, the
falcon-kac image must be present in a container registry accessible to the
kubernetes deployment.

When utilizing your own registry, a common error on installation is forgetting
to add your containerized sensor to your local image registry prior to
executing `helm install`. Please read the Helm Chart's readme for more
deployment considerations.

To check the status of Falcon Kubernetes Admissions Controller pods, run the
following command:

  kubectl -n falcon-kac get pods
Validating KAC Deployment rollout
Waiting for deployment "falcon-kac" rollout to finish: 0 of 1 updated replicas are available...
deployment "falcon-kac" successfully rolled out
Falcon KAC sensor successfully deployed!
Monitoring pods and deployments in namespace falcon-kac for 5 minutes...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           4s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          4s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           35s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          35s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           65s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          65s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           95s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          95s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           2m5s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          2m5s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           2m35s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          2m35s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           3m6s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          3m6s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           3m36s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          3m36s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           4m6s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          4m6s
Waiting for 30 seconds...
Fetching current deployments and pods...
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/falcon-kac   1/1     1            1           4m36s

NAME                              READY   STATUS    RESTARTS   AGE
pod/falcon-kac-5d9d88fdb9-bdt2w   3/3     Running   0          4m36s
Waiting for 30 seconds...
Monitoring completed after 5 minutes.
```

---

## **Uninstall**
```bash
./deploy_aks_kac.sh uninstall
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
- [Azure AKS Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Kubernetes Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Helm Documentation](https://helm.sh/docs/)

