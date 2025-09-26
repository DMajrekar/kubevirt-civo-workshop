# Step 3: Initial VM Validation

**Goal**: Install virtctl CLI and validate KubeVirt with a lightweight CirrOS VM

## Install virtctl CLI

### Automated Installation (Recommended)
```bash
./install-virtctl.sh
```

### Manual Installation (Alternative)
```bash
# Get the KubeVirt version
VERSION=$(kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.observedKubeVirtVersion}")

# Detect architecture
ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/')

# Download to current directory
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl

# Verify
./virtctl version
```

## Create and Test CirrOS VM

CirrOS is a minimal Linux distribution perfect for initial testing and validation.

### 1. Deploy the VM
```bash
kubectl apply -f testvm.yaml
```

### 2. Start the VM
```bash
./virtctl start testvm
```

### 3. Check VM Status
```bash
kubectl get vms
kubectl get vmis
```

### 4. Connect to VM Console (Optional)
```bash
./virtctl console testvm
```
Login with `cirros` / `gocubsgo`. Press `Ctrl+]` to disconnect.

## Why CirrOS for Initial Validation?

CirrOS is excellent for:
- ✅ Quick VM startup and validation
- ✅ Minimal resource usage
- ✅ Testing KubeVirt functionality
- ✅ Network connectivity verification

However, CirrOS has limitations:
- ❌ No package manager (apt, yum, etc.)
- ❌ No Python or common web servers
- ❌ Limited tooling for real applications

## Files in this step
- `install-virtctl.sh` - virtctl installation script
- `testvm.yaml` - CirrOS VM definition for testing

## Next Step
CirrOS is great for validation, but for running real applications with upstream images like Ubuntu, we need CDI (Containerized Data Importer). Proceed to [Step 4: CDI Installation](../step-04-cdi-installation/).