# Step 99: Cleanup

**Goal**: Clean up all workshop resources

## Delete Workshop Resources

### 1. Delete VMs
```bash
# Delete VMs (this also stops them if running)
kubectl delete vm ubuntu-vm testvm
```

### 2. Delete Services
```bash
# Delete VM services
kubectl delete svc ubuntu-vm-service ubuntu-vm-loadbalancer

# Delete test services
kubectl delete svc nginx-service
```

### 3. Delete Deployments
```bash
# Delete test deployments
kubectl delete deployment nginx
```

### 4. Delete DataVolumes 
```bash
# This also deletes the associated PVC and data
kubectl delete datavolume ubuntu
```

### 5. Remove CDI (Optional)
If you want to completely remove CDI:
```bash
# Get CDI version
export VERSION=$(basename $(curl -s -w %{redirect_url} https://github.com/kubevirt/containerized-data-importer/releases/latest))

# Remove CDI
kubectl delete cdi cdi -n cdi
kubectl delete -f "https://github.com/kubevirt/containerized-data-importer/releases/download/${VERSION}/cdi-operator.yaml"
```

### 6. Remove KubeVirt (Optional)
If you want to completely remove KubeVirt:
```bash
# Get KubeVirt version
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

# Remove KubeVirt
kubectl delete -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
kubectl delete -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"

# Remove kernel modules DaemonSet
kubectl delete daemonset kubevirt-kernel-modules -n kube-system
```

## Delete Cluster

### Via Civo Dashboard
1. Go to [dashboard.civo.com](https://dashboard.civo.com)
2. Navigate to "Kubernetes" section
3. Find your `kubevirt-workshop` cluster
4. Click "Delete" and confirm

### Via Civo CLI (Alternative)
```bash
civo kubernetes delete kubevirt-workshop
```

## Local Cleanup

### Remove kubeconfig
```bash
# If you exported it temporarily
unset KUBECONFIG

# Or delete the downloaded file
rm ~/Downloads/kubevirt-workshop-kubeconfig
```

### Remove virtctl (Optional)
```bash
# Remove the downloaded virtctl binary
rm ./virtctl
```

## Verification

### Before Cluster Deletion
Verify workshop resources are cleaned up (run this before deleting the cluster):

```bash
# These should show no resources
kubectl get vms
kubectl get vmis
kubectl get datavolumes
kubectl get svc --selector='!kubernetes.io/name'
```

### After Cluster Deletion
Once the cluster is deleted, verify via Civo dashboard:
- Cluster should no longer appear in your Kubernetes clusters list
- Associated LoadBalancers and volumes should be cleaned up automatically

## What You've Learned

Throughout this workshop, you've successfully:

- ✅ **Set up KubeVirt** on a Kubernetes cluster
- ✅ **Created and managed** virtual machines in Kubernetes
- ✅ **Ran services** within VMs (both minimal CirrOS and full Ubuntu)
- ✅ **Established networking** between VMs and Kubernetes services
- ✅ **Exposed VM services** to the internet via LoadBalancer
- ✅ **Understood the power** of combining traditional VMs with cloud-native Kubernetes

## Next Steps

- Explore more KubeVirt features like persistent storage
- Try different VM operating systems
- Implement more complex networking scenarios
- Look into VM migration capabilities
- Consider how VMs fit into your cloud-native architecture

Thank you for completing the KubeVirt Civo Workshop!