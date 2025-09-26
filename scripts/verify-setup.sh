#!/bin/bash

echo "🔍 Verifying workshop setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check kubectl
echo "Checking kubectl..."
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
    print_status 0 "kubectl is installed: $kubectl_version"
else
    print_status 1 "kubectl is not installed"
    exit 1
fi

# Check cluster connectivity
echo "Checking cluster connectivity..."
if kubectl cluster-info &> /dev/null; then
    print_status 0 "Connected to Kubernetes cluster"
    print_info "Cluster info:"
    kubectl cluster-info | head -2
else
    print_status 1 "Cannot connect to Kubernetes cluster"
    print_warning "Make sure KUBECONFIG is set: export KUBECONFIG=/path/to/your/kubeconfig"
    exit 1
fi

# Check nodes
echo "Checking cluster nodes..."
node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ $node_count -gt 0 ]; then
    print_status 0 "Cluster has $node_count node(s)"
    kubectl get nodes
else
    print_status 1 "No nodes found in cluster"
fi

# Check KubeVirt installation
echo "Checking KubeVirt installation..."
if kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt &> /dev/null; then
    kubevirt_phase=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}" 2>/dev/null)
    if [ "$kubevirt_phase" = "Deployed" ]; then
        print_status 0 "KubeVirt is installed and deployed"
        kubevirt_version=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}" 2>/dev/null)
        print_info "KubeVirt version: $kubevirt_version"
    else
        print_status 1 "KubeVirt is installed but not ready (phase: $kubevirt_phase)"
        print_warning "Run: kubectl get all -n kubevirt to check status"
    fi
else
    print_status 1 "KubeVirt is not installed"
    print_warning "Run: ./scripts/setup-kubevirt.sh to install KubeVirt"
fi

# Check virtctl (local)
echo "Checking virtctl..."
if [ -f "./virtctl" ]; then
    virtctl_version=$(./virtctl version --client 2>/dev/null || echo "unknown")
    print_status 0 "virtctl is available locally: $virtctl_version"
elif command -v virtctl &> /dev/null; then
    virtctl_version=$(virtctl version --client 2>/dev/null || echo "unknown")
    print_status 0 "virtctl is installed globally: $virtctl_version"
else
    print_status 1 "virtctl is not available"
    print_warning "Run: ./scripts/install-virtctl.sh to download virtctl"
fi

echo ""
echo "🎯 Setup verification complete!"