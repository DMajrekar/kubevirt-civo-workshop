# KubeVirt Workshop Troubleshooting Guide

This guide covers common issues you might encounter during the workshop and their solutions.

## Prerequisites Issues

### kubectl not found
**Problem**: `kubectl: command not found`
**Solution**: Install kubectl following the [official documentation](https://kubernetes.io/docs/tasks/tools/)

### KUBECONFIG issues
**Problem**: `The connection to the server localhost:8080 was refused`
**Solution**:
```bash
# Make sure KUBECONFIG is set to your downloaded file
export KUBECONFIG=/path/to/your/kubeconfig

# Verify the file exists and is readable
ls -la $KUBECONFIG
```

## KubeVirt Installation Issues

### KubeVirt operator fails to install
**Problem**: Error when creating KubeVirt operator
**Solution**:
```bash
# Check if it already exists
kubectl get pods -n kubevirt

# If it exists but failing, try to delete and reinstall
kubectl delete -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
kubectl delete -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"

# Wait a moment and reinstall
./scripts/setup-kubevirt.sh
```

### KubeVirt stuck in "Deploying" phase
**Problem**: KubeVirt phase remains "Deploying" for a long time
**Solution**:
```bash
# Check the operator logs
kubectl logs -n kubevirt deployment/virt-operator

# Check if all pods are running
kubectl get pods -n kubevirt

# Check events for issues
kubectl get events -n kubevirt --sort-by=.metadata.creationTimestamp
```

### KubeVirt installation job pending on managed clusters
**Problem**: Installation job shows "0/X nodes are available: X node(s) didn't match Pod's node affinity/selector"
**Solution**: This occurs on managed clusters (like Civo) where control plane nodes are hidden. Patch the KubeVirt resource to remove control plane requirements:
```bash
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
```

### Insufficient node resources
**Problem**: Pods stuck in "Pending" state
**Solution**:
```bash
# Check node resources
kubectl top nodes

# Check pod resource requests
kubectl describe pod -n kubevirt <pod-name>

# Consider scaling up your Civo cluster nodes
```

## virtctl Issues

### virtctl download fails
**Problem**: `curl: (22) The requested URL returned error: 404 Not Found`
**Solution**:
```bash
# Check KubeVirt version
kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}"

# Manual download with correct version
VERSION=<version-from-above>
ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/')
curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
chmod +x virtctl
sudo install virtctl /usr/local/bin
```

### virtctl permission denied
**Problem**: `sudo: install: command not found` or permission issues
**Solution**:
```bash
# Alternative installation method
sudo mv virtctl /usr/local/bin/
sudo chmod +x /usr/local/bin/virtctl

# Or install to user directory
mkdir -p ~/bin
mv virtctl ~/bin/
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Virtual Machine Issues

### VM fails to start due to kernel modules
**Problem**: VM shows "ErrorUnschedulable" status with node selector/affinity errors
**Solution**: Ensure kernel modules are loaded on all nodes:
```bash
# Check if kernel modules DaemonSet is running
kubectl get daemonset kubevirt-kernel-modules -n kube-system

# Check DaemonSet pod status
kubectl get pods -n kube-system -l app=kubevirt-kernel-modules

# Check logs for module loading
kubectl logs -n kube-system -l app=kubevirt-kernel-modules

# If needed, redeploy the DaemonSet
kubectl delete daemonset kubevirt-kernel-modules -n kube-system
kubectl apply -f manifests/kernel-modules-daemonset.yaml
```

### VM fails to start
**Problem**: VM remains in "Starting" state or fails to start
**Solution**:
```bash
# Check VM status
kubectl get vms
kubectl get vmis

# Check VM events
kubectl describe vm testvm
kubectl get events --field-selector involvedObject.name=testvm

# Check virt-launcher pod logs
kubectl logs -n default <virt-launcher-testvm-xxxx>
```

### Can't connect to VM console
**Problem**: `virtctl console testvm` hangs or fails
**Solution**:
```bash
# Ensure VM is running
kubectl get vmis testvm

# Check if VMI exists and is running
kubectl describe vmi testvm

# Try with timeout
virtctl console testvm --timeout=30s

# Alternative: check via virt-launcher logs
kubectl logs <virt-launcher-testvm-xxxx>
```

### VM console login issues
**Problem**: Can't login to CirrOS VM
**Solution**:
- Default credentials: `cirros` / `gocubsgo`
- Wait for the VM to fully boot (may take 1-2 minutes)
- Press Enter to get login prompt

## Networking Issues

### Service not accessible from cluster
**Problem**: Cannot reach VM service from test pod
**Solution**:
```bash
# Check service endpoints
kubectl get endpoints testvm-service

# Ensure VM is running and service is active
virtctl console testvm
# Inside VM: netstat -tlnp | grep 8080

# Check service selector matches VM labels
kubectl get vm testvm --show-labels
kubectl describe service testvm-service
```

### LoadBalancer external IP pending
**Problem**: External IP shows `<pending>` for LoadBalancer service
**Solution**:
- This is normal on Civo - wait 2-5 minutes
- Check service status: `kubectl describe svc testvm-loadbalancer`
- Verify Civo account has LoadBalancer quota available

### VM cannot access cluster services
**Problem**: VM cannot reach Kubernetes services
**Solution**:
```bash
# From inside VM, check DNS resolution
nslookup kubernetes.default.svc.cluster.local

# Check if CoreDNS is working
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Try accessing service by IP
kubectl get svc kubernetes -o wide
```

## Performance Issues

### Slow VM startup
**Problem**: VM takes a long time to start
**Solution**:
- This is normal for first start as it downloads container image
- Subsequent starts should be faster
- Check node resources: `kubectl top nodes`

### High resource usage
**Problem**: Cluster running out of resources
**Solution**:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Scale down test resources
kubectl delete deployment test-app
kubectl delete deployment nginx

# Consider increasing VM memory limits in testvm.yaml
```

## Cleanup Issues

### Resources won't delete
**Problem**: VM or services stuck in "Terminating" state
**Solution**:
```bash
# Force delete VM
kubectl delete vm testvm --force --grace-period=0

# Remove finalizers if needed
kubectl patch vm testvm -p '{"metadata":{"finalizers":[]}}' --type=merge

# Force delete stuck pods
kubectl delete pod <pod-name> --force --grace-period=0
```

## CDI and DataVolume Issues

### DataVolume stuck in WaitForFirstConsumer
**Problem**: DataVolume PVC shows "WaitForFirstConsumer" and import doesn't start
**Solution**: Add immediate binding annotation to force PVC binding:
```bash
# Add this annotation to your DataVolume manifest:
metadata:
  annotations:
    cdi.kubevirt.io/storage.bind.immediate.requested: "true"

# Or patch existing DataVolume:
kubectl annotate datavolume <datavolume-name> cdi.kubevirt.io/storage.bind.immediate.requested="true"

# Check PVC status:
kubectl get pvc
```

### DataVolume import fails with storage errors
**Problem**: DataVolume fails with "no accessMode specified" error
**Solution**: Ensure DataVolume has proper storage configuration:
```bash
# DataVolume must include accessModes:
spec:
  storage:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 5Gi
```

### Monitor DataVolume import progress
**Solution**: Track the import process:
```bash
# Watch DataVolume status
kubectl get datavolume <name> -w

# Check importer pod logs
kubectl logs -f $(kubectl get pods -l app=containerized-data-importer -o name | head -1)

# Check CDI events
kubectl get events --field-selector involvedObject.kind=DataVolume
```

## Civo-Specific Issues

### Cluster creation fails
**Problem**: Civo cluster fails to create
**Solution**:
- Check Civo account quotas and billing
- Try different region (PHX1, LON1, NYC1)
- Ensure cluster name is unique
- Contact Civo support if persistent

### kubeconfig download issues
**Problem**: Downloaded kubeconfig doesn't work
**Solution**:
```bash
# Verify file contents
cat /path/to/kubeconfig | head -10

# Ensure file has correct permissions
chmod 600 /path/to/kubeconfig

# Try re-downloading from Civo dashboard
```

## Getting Help

If you continue to have issues:

1. Check the [KubeVirt documentation](https://kubevirt.io/user-guide/)
2. Review [KubeVirt GitHub issues](https://github.com/kubevirt/kubevirt/issues)
3. Ask questions on the [KubeVirt Slack](https://kubernetes.slack.com/channels/virtualization)
4. For Civo-specific issues, check [Civo documentation](https://www.civo.com/docs) or support

## Useful Debugging Commands

```bash
# General cluster health
kubectl get nodes
kubectl get pods -A
kubectl top nodes

# KubeVirt status
kubectl get all -n kubevirt
kubectl get kubevirt -n kubevirt -o yaml

# VM debugging
kubectl get vms
kubectl get vmis
kubectl describe vm <vm-name>
kubectl logs <virt-launcher-pod>

# Service debugging
kubectl get svc
kubectl get endpoints
kubectl describe svc <service-name>

# Events (often very helpful)
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl get events --field-selector involvedObject.name=<resource-name>
```