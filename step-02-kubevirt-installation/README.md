# Step 2: KubeVirt Installation

**Goal**: Install KubeVirt operator and verify it's running

## Prerequisites Check
Before starting, verify your cluster is ready:
```bash
# Check cluster connectivity
kubectl cluster-info

# Verify nodes are ready
kubectl get nodes
```

## Automated Installation (Recommended)

Run the KubeVirt setup script:
```bash
./setup-kubevirt.sh
```

This script will:
- Deploy kernel modules DaemonSet (loads `tun` and `vhost-net` modules)
- Wait for kernel modules to be ready on all nodes
- Download the latest KubeVirt version
- Deploy the KubeVirt operator
- Create the KubeVirt CR (with managed cluster compatibility for Civo)
- Wait for the installation to complete
- Verify the installation status

## Manual Installation (Alternative)

If you prefer to run commands manually:

### 1. Deploy Kernel Modules First (Required)
```bash
# Deploy kernel modules DaemonSet
kubectl apply -f kernel-modules-daemonset.yaml

# Wait for modules to be loaded on all nodes
kubectl rollout status daemonset/kubevirt-kernel-modules -n kube-system --timeout=300s
```

### 2. Install KubeVirt for Managed Clusters (Civo)
```bash
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"

# Use the managed cluster compatible CR
kubectl apply -f kubevirt-cr-managed.yaml

kubectl wait --for=condition=Available kubevirt kubevirt --namespace=kubevirt --timeout=10m

# Verify deployment phase
kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}"
```

## Verify Installation

```bash
# Should show "Deployed"
kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}"

# All pods should be Running
kubectl get pods -n kubevirt
```

## Verify Complete Setup

Run the verification script to ensure everything is working:
```bash
./verify-setup.sh
```

This checks that kubectl, cluster connectivity, KubeVirt, and all components are working properly.

## Files in this step
- `setup-kubevirt.sh` - Automated installation script
- `kernel-modules-daemonset.yaml` - Required kernel modules for KubeVirt
- `kubevirt-cr-managed.yaml` - KubeVirt custom resource for managed clusters
- `verify-setup.sh` - Complete setup verification script

## Next Step
Once KubeVirt shows "Deployed" status and verification passes, proceed to [Step 3: Initial VM Validation](../step-03-initial-vm-validation/).