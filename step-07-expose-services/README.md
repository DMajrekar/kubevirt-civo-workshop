# Step 7: Expose VM Service via Kubernetes

**Goal**: Make VM service accessible through Kubernetes Service

## Prerequisites
- Ubuntu VM is running (from Step 5)
- Web service is running inside the VM on port 8080 (from Step 6)

## Prerequisites Check
Verify the Ubuntu VM and web service are ready:
```bash
# Check Ubuntu VM is running
kubectl get vmi ubuntu-vm

# Verify VM has an IP address
kubectl get vmi ubuntu-vm -o jsonpath='{.status.interfaces[0].ipAddress}'
```

## Apply Service

Create a Kubernetes service to expose the VM:
```bash
kubectl apply -f ubuntu-vm-service.yaml
```

This creates a ClusterIP service that maps to the VM's IP address.

## Test Internal Access

Test that the service is accessible from within the cluster:
```bash
# Create a test pod to access the service directly
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://ubuntu-vm-service
```

You should see "Hello from Ubuntu VM!" response, demonstrating successful communication from cluster pods to the VM service.

## Alternative Testing Methods

### Using curl with a different image:
```bash
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl http://ubuntu-vm-service
```

### Using service FQDN:
```bash
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://ubuntu-vm-service.default.svc.cluster.local
```

## What This Demonstrates

- ✅ **Seamless integration**: VMs appear as regular services to Kubernetes workloads
- ✅ **Service discovery**: Standard Kubernetes DNS resolution works for VM services
- ✅ **Network connectivity**: Pods can communicate with VM services using service names
- ✅ **Load balancing**: Kubernetes service provides load balancing capabilities

## Troubleshooting

If the connection fails:

1. **Check service endpoints:**
   ```bash
   kubectl get endpoints ubuntu-vm-service
   ```

2. **Verify VM is running:**
   ```bash
   kubectl get vmis
   ```

3. **Verify service inside VM:**
   ```bash
   ./virtctl console ubuntu-vm
   # Inside VM: curl localhost:8080
   ```

## How It Works

The service manifest:
1. **Selects the VM** using labels that match the VirtualMachine
2. **Maps port 80** on the service to **port 8080** inside the VM
3. **Creates a stable endpoint** that Kubernetes pods can use
4. **Provides DNS resolution** within the cluster

## Service Discovery

The service is now available at:
- **Service name**: `ubuntu-vm-service`
- **Cluster FQDN**: `ubuntu-vm-service.default.svc.cluster.local`
- **Port**: 80 (mapped to VM's port 8080)

## Files in this step
- `ubuntu-vm-service.yaml` - Kubernetes Service definition for VM

## Next Step
Now let's test the reverse: VM accessing Kubernetes cluster services. Proceed to [Step 8: VM to Cluster Communication](../step-08-vm-to-cluster/).