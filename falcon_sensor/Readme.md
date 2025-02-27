# Deployment Notes

## Environment Setup

Setup the environment variable to meet your AWS EKS Settings

*Example*
```bash
export FALCON_CID=<falcon_cid_value>                       # Note: Include the -XX value"
export ECR_REPO_FALCON_SENSOR="<aws_ecr_repo_path>"        # "123456789012.mydkr.ecr.us-east-2.amazonaws.com/falcon-sensor/us-1/release/falcon-sensor"
export FALCON_SENSOR_TAG_VALUE="<falcon_sensor_tag_value>" # Example: 7.19.0-17219-1.falcon-linux.Release.US-1
export AWS_REGION_VALUE="<aws_region>"                     # Example: us-east-2
```

## Deployment

*Deployment*

```bash
deploy_eks_falconSensor.sh
```

*Uninstall*

```bash
deploy_eks_falconSensor.sh uninstall
```

### Example Output

Example Deployment Output

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

Access to the Falcon Linux and Container Sensor downloads at registry.crowdstrike.com are
required to complete the install of this Helm chart. If an internal registry is used instead of registry.crowdstrike.com.
the containerized sensor must be present in a container registry accessible from Kubernetes installation.
CrowdStrike Falcon sensors will deploy across all nodes in your Kubernetes cluster after
installing this Helm chart. The default image name to deploy a kernel sensor to a node is `falcon-node-sensor`.

When utilizing your own registry, an extremely common error on installation is accidentally forgetting to add your containerized
sensor to your local image registry prior to executing `helm install`. Please read the Helm Chart's readme
for more deployment considerations.
Validating DaemonSet deployment
Waiting for daemon set "falcon-sensor" rollout to finish: 0 of 2 updated pods are available...
Waiting for daemon set "falcon-sensor" rollout to finish: 1 of 2 updated pods are available...
daemon set "falcon-sensor" successfully rolled out
Falcon sensor successfully deployed!
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
falcon-sensor   2         2         2       2            2           kubernetes.io/os=linux   6s
```

## AKS Deployment

### Set Environment

```bash
export FALCON_CID = "<FALCON_CID>-<EXTENDED_VAL>"
export ACR_NAME = "<AZURE_CONTAINER_REGISTRY_NAME>"
export FALCON_SENSOR_REPO="<FALCON_SENSOR_NAME>"
export FALCON_SENSOR_TAG_VALUE="<FALCON_SENSOR_TAG_VALUE>"

```