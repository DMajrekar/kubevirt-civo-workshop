# Step 4: CDI Installation (Optional)

**Goal**: Install CDI (Containerized Data Importer) for importing cloud images

## Why CDI?

While CirrOS from Step 3 is great for validation, CDI allows you to create VMs from full Linux distributions like:
- Ubuntu, Fedora, CentOS, RHEL
- Cloud images with package managers
- Pre-configured operating systems
- Custom disk images

CDI provides full Linux environments with standard tools and package managers.

## Automated Installation (Recommended)

```bash
./setup-cdi.sh
```

This script will:
- Download and install the latest CDI operator
- Create the CDI custom resource
- Wait for CDI to be fully deployed
- Verify the installation

## Manual Installation (Alternative)

```bash
# Get latest CDI version
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))

# Install CDI operator and CR
kubectl create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-operator.yaml"
kubectl create -f "https://github.com/kubevirt/containerized-data-importer/releases/download/$VERSION/cdi-cr.yaml"

# Verify installation
kubectl get cdi cdi -n cdi
kubectl get pods -n cdi
```

## Verify Installation

```bash
# Check CDI status
kubectl get cdi cdi -n cdi -o jsonpath="{.status.phase}"

# Should show "Deployed"
kubectl get pods -n cdi
```

## What CDI Enables

With CDI installed, you can now:
- Import Ubuntu, Fedora, and other cloud images
- Create VMs with full package managers
- Use persistent storage for VM disks
- Clone and snapshot VM images

## Files in this step
- `setup-cdi.sh` - CDI installation script

## Next Step
With CDI installed, you can now create full Ubuntu VMs. Proceed to [Step 5: VM Creation](../step-05-vm-creation/).