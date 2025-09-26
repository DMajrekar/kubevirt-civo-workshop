#!/bin/bash

set -e

echo "🚀 Setting up CDI (Containerized Data Importer)..."

# Get latest CDI version
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))
echo "📦 Installing CDI version: $VERSION"

# Deploy CDI operator
echo "🔧 Deploying CDI operator..."
kubectl create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml"

# Deploy CDI CR
echo "🔧 Creating CDI custom resource..."
kubectl create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml"

# Wait for CDI to be ready
echo "⏳ Waiting for CDI to reach 'Deployed' phase..."
timeout 600 bash -c 'until kubectl get cdi cdi -n cdi -o jsonpath="{.status.phase}" 2>/dev/null | grep -q "Deployed"; do echo "Current phase: $(kubectl get cdi cdi -n cdi -o jsonpath="{.status.phase}" 2>/dev/null)"; sleep 5; done'

# Verify installation
echo "🔍 Verifying CDI installation..."
PHASE=$(kubectl get cdi cdi -n cdi -o jsonpath="{.status.phase}")
echo "CDI phase: $PHASE"

if [ "$PHASE" = "Deployed" ]; then
    echo "✅ CDI is ready!"
else
    echo "⚠️  CDI phase is $PHASE - installation may have failed"
    exit 1
fi

echo "📋 CDI components:"
kubectl get pods -n cdi

echo ""
echo "🎉 CDI setup complete! You can now create DataVolumes for VM disk images."