# 🛡️ Deploying CrowdStrike Falcon Operator and NodeSensor on EKS

This guide explains how to deploy the CrowdStrike Falcon Operator and Falcon Node Sensor on an Amazon EKS cluster using a private ECR-hosted sensor image.

---

## 📋 Prerequisites

- AWS CLI configured with access to your EKS cluster
- `kubectl` and `helm` installed
- CrowdStrike CID (Customer ID)
- ECR-hosted Falcon Sensor image
- EKS nodes have access to pull from ECR

---

## 🔧 1. Update Kubeconfig

```bash
aws eks update-kubeconfig \
  --region us-east-2 \
  --name eus2-eks-cl01 \
  --profile csadmin01_715841348376
```

---

## 🏗️ 2. Deploy the Falcon Operator

```bash
kubectl apply -f https://raw.githubusercontent.com/CrowdStrike/falcon-operator/main/deploy/falcon-operator.yaml
```

> This deploys the operator to the `falcon-operator` namespace and installs the required CRDs and RBAC.

---

## 🧱 3. Create the FalconNodeSensor Resource

Create a file called `falcon-node-sensor.yaml`:

```yaml
apiVersion: falcon.crowdstrike.com/v1alpha1
kind: FalconNodeSensor
metadata:
  name: falcon-node-sensor
spec:
  falcon:
    cid: 3D0203D68AB74763A56BC5AA06F30957-25
  node:
    image: 715841348376.dkr.ecr.us-east-2.amazonaws.com/falcon-sensor:7.23.0-17607-1.falcon-linux.Release.US-1
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      - key: "CriticalAddonsOnly"
        operator: "Exists"
```

Then apply it:

```bash
kubectl apply -f falcon-node-sensor.yaml
```

---

## 📊 4. Validate the Deployment

### Check the DaemonSet:

```bash
kubectl get daemonset falcon-node-sensor -n falcon-system
```

Expected output:

```
NAME                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
falcon-node-sensor   2         2         2       2            2           kubernetes.io/os=linux   Xm
```

### Monitor rollout:

```bash
kubectl rollout status daemonset/falcon-node-sensor -n falcon-system
```

### View logs (optional):

```bash
kubectl logs -n falcon-system -l app=falcon-sensor --tail=50
```

---

## 🧹 5. Cleanup

To delete the sensor:

```bash
kubectl delete falconnodesensor falcon-node-sensor
```

To remove the operator:

```bash
kubectl delete -f https://raw.githubusercontent.com/CrowdStrike/falcon-operator/main/deploy/falcon-operator.yaml
```

---

## 🧩 Notes

- `FalconNodeSensor` is **cluster-scoped**, so it should not specify a namespace.
- The sensor image must be accessible to all EKS worker nodes.
- If using private ECR, ensure your nodes have permissions via IAM role or pull secrets.
```