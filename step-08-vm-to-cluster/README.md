# Step 8: VM to Cluster Communication

**Goal**: Show VM can access Kubernetes cluster services

## Create a Simple Cluster Service

First, let's create a simple web service in the cluster:

```bash
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml
```

This creates:
- An nginx deployment
- A service exposing nginx on port 80

## Test from VM

Now access the cluster service from inside the VM:

```bash
./virtctl console ubuntu-vm
```

Inside the VM, test connectivity to the cluster service:
```bash
# Standard service name resolution
curl nginx-service.default.svc.cluster.local

# Short service name (works within same namespace)
curl nginx-service
```

### Expected Result
You should see the nginx welcome page HTML, demonstrating that the VM can resolve and access Kubernetes services.

## What This Demonstrates

- ✅ **Bidirectional networking**: VMs can access cluster services
- ✅ **DNS resolution**: VMs can resolve Kubernetes service names
- ✅ **Network integration**: VMs are part of the cluster network
- ✅ **Service mesh ready**: VMs can participate in service mesh architectures

## Advanced Testing

### Test with different protocols:
```bash
# Inside the VM
nslookup nginx-service.default.svc.cluster.local
ping nginx-service.default.svc.cluster.local
```

### Check cluster DNS from VM:
```bash
# Inside the VM
cat /etc/resolv.conf
```

## Use Cases This Enables

This bidirectional communication enables:
- **Hybrid architectures**: VMs consuming cluster databases, APIs
- **Legacy integration**: Legacy apps in VMs accessing modern services
- **Gradual migration**: Moving workloads piece by piece
- **Data processing**: VMs processing data from cluster services

## Files in this step
- `nginx-deployment.yaml` - Nginx deployment for testing
- `nginx-service.yaml` - Service exposing the nginx deployment

## Next Step
Now let's expose the VM service to the internet using a LoadBalancer. Proceed to [Step 9: External Access](../step-09-external-access/).