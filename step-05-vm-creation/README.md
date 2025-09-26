# Step 5: VM Creation with Ubuntu

**Goal**: Create a full Ubuntu VM using CDI DataVolumes

## Prerequisites
- CDI must be installed (Step 4)
- CDI status should show "Deployed"

## Create Ubuntu DataVolume

DataVolumes automatically download and import cloud images:

```bash
kubectl apply -f ubuntu-datavolume.yaml

# Monitor the import process (this may take several minutes)
kubectl get datavolume ubuntu -w
```

**Note**: The DataVolume downloads a Ubuntu 24.04 LTS cloud image. This may take several minutes depending on your internet connection.

## Deploy Ubuntu VM

Once the DataVolume shows "Succeeded" status:

```bash
kubectl apply -f ubuntu-vm.yaml
```

## Start the VM

```bash
./virtctl start ubuntu-vm
```

## Check VM Status

```bash
kubectl get vms
kubectl get vmis
```

## Connect to VM Console

```bash
./virtctl console ubuntu-vm
```

Login with `ubuntu` / `ubuntu`. Press `Ctrl+]` to disconnect.

## Ubuntu VM Capabilities

Unlike the CirrOS VM from Step 3, Ubuntu provides:
- ✅ Full package manager (apt)
- ✅ Python, Node.js, and other runtimes
- ✅ Web servers (Apache, Nginx, Python HTTP server)
- ✅ Complete development environment
- ✅ Standard Linux utilities and tools

## Files in this step
- `ubuntu-datavolume.yaml` - DataVolume for Ubuntu 24.04 LTS image
- `ubuntu-vm.yaml` - Ubuntu VM definition

## Next Step
With a full Ubuntu VM running, you can now deploy services inside it. Proceed to [Step 6: VM Services](../step-06-vm-services/).