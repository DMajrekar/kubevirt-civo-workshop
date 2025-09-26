#!/bin/bash

set -e

echo "🚀 Setting up KubeVirt..."

# Deploy kernel modules DaemonSet first
echo "🔧 Deploying kernel modules DaemonSet..."
kubectl apply -f manifests/kernel-modules-daemonset.yaml

# Wait for DaemonSet to be ready on all nodes
echo "⏳ Waiting for kernel modules to be loaded on all nodes..."
kubectl rollout status daemonset/kubevirt-kernel-modules -n kube-system --timeout=300s

# Detect if this is a managed cluster
echo "🔍 Detecting cluster type..."
CONTROL_PLANE_NODES=$(kubectl get nodes --selector=node-role.kubernetes.io/control-plane -o name 2>/dev/null | wc -l)
MASTER_NODES=$(kubectl get nodes --selector=node-role.kubernetes.io/master -o name 2>/dev/null | wc -l)

if [ "$CONTROL_PLANE_NODES" -eq 0 ] && [ "$MASTER_NODES" -eq 0 ]; then
    echo "🔧 Detected managed cluster (no control plane nodes available)"
    MANAGED_CLUSTER=true
else
    echo "🔧 Detected standard cluster with control plane access"
    MANAGED_CLUSTER=false
fi

# Get latest KubeVirt version
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo "📦 Installing KubeVirt version: $VERSION"

# Deploy KubeVirt operator
echo "🔧 Deploying KubeVirt operator..."
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"

# Create KubeVirt CR based on cluster type
if [ "$MANAGED_CLUSTER" = true ]; then
    echo "🔧 Creating KubeVirt CR for managed cluster..."
    # Check if we're running from the repo directory
    if [ -f "manifests/kubevirt-cr-managed.yaml" ]; then
        kubectl apply -f manifests/kubevirt-cr-managed.yaml
    else
        echo "⚠️  Custom CR not found, downloading and patching standard CR..."
        # Download standard CR and apply custom node placement
        curl -s "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml" | \
        kubectl apply -f -

        # Patch the KubeVirt resource with managed cluster configuration
        echo "🔧 Patching KubeVirt CR for managed cluster compatibility..."
        kubectl patch kubevirt kubevirt -n kubevirt --type='merge' -p='{
            "spec": {
                "infra": {
                    "nodePlacement": {
                        "nodeSelector": {"kubernetes.io/os": "linux"},
                        "tolerations": []
                    }
                },
                "workloads": {
                    "nodePlacement": {
                        "nodeSelector": {"kubernetes.io/os": "linux"},
                        "tolerations": []
                    }
                }
            }
        }'
    fi
else
    echo "🔧 Creating standard KubeVirt CR..."
    kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
fi

# Wait for KubeVirt to reach 'Deployed' phase
echo "⏳ Waiting for KubeVirt to reach 'Deployed' phase..."
timeout 600 bash -c 'until kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}" 2>/dev/null | grep -q "Deployed"; do echo "Current phase: $(kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}" 2>/dev/null)"; sleep 5; done'

# Verify installation
echo "🔍 Verifying installation..."
PHASE=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}")
echo "KubeVirt phase: $PHASE"

if [ "$PHASE" = "Deployed" ]; then
    echo "✅ KubeVirt is ready!"
else
    echo "⚠️  KubeVirt phase is $PHASE - installation may have failed"
    exit 1
fi

echo "📋 KubeVirt components:"
kubectl get all -n kubevirt