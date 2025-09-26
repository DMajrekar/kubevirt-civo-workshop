#!/bin/bash

set -e

echo "🚀 Downloading virtctl to local folder..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is required but not installed. Please install kubectl first."
    exit 1
fi

# Check if KubeVirt is installed
if ! kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt &> /dev/null; then
    echo "❌ KubeVirt is not installed. Please run setup-kubevirt.sh first."
    exit 1
fi

# Get KubeVirt version
VERSION=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
if [ -z "$VERSION" ]; then
    echo "❌ Could not determine KubeVirt version. Is KubeVirt fully deployed?"
    exit 1
fi

echo "📦 Downloading virtctl version: $VERSION"

# Detect architecture
ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/')
echo "🔍 Detected architecture: $ARCH"

# Download virtctl
DOWNLOAD_URL="https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}"
echo "📥 Downloading from: $DOWNLOAD_URL"

curl -L -o virtctl "$DOWNLOAD_URL"

if [ ! -f virtctl ]; then
    echo "❌ Failed to download virtctl"
    exit 1
fi

# Make executable
chmod +x virtctl

# Verify download
echo "✅ virtctl downloaded successfully!"
echo "🔍 Verifying download..."
./virtctl version

echo "🎉 virtctl is ready in the current directory!"
echo "💡 Use './virtctl' to run commands (e.g., './virtctl start testvm')"