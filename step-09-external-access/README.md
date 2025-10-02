# Step 9: Expose VM Service to Internet

**Goal**: Make VM service accessible from the internet using LoadBalancer

## Prerequisites
- Ubuntu VM with web service running (Steps 5-6)
- VM service exposed internally (Step 7)

## Apply LoadBalancer Service

```bash
kubectl apply -f ubuntu-vm-loadbalancer.yaml
```

This creates a LoadBalancer service that:
- Exposes the VM service to the internet
- Gets an external IP from Civo's cloud provider
- Maps external port 80 to VM's internal port 8080

## Get External IP

Wait for the external IP to be assigned:
```bash
kubectl get svc ubuntu-vm-loadbalancer -w
```

**Note**: On Civo, it may take 2-5 minutes for the external IP to be provisioned.

You should see output like:
```
NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
ubuntu-vm-loadbalancer   LoadBalancer   10.43.xxx.xxx  91.xxx.xxx.xxx  80:xxxxx/TCP   2m
```

## Test External Access

Once you have the external IP, test from your local machine:
```bash
curl http://<EXTERNAL-IP>
```

Or open the IP in your web browser.

### Expected Result
You should see "Hello from Ubuntu VM!" from anywhere on the internet!

## What You've Achieved

- ✅ **Internet accessibility**: VM service is now publicly available
- ✅ **Cloud integration**: Using Civo's LoadBalancer service
- ✅ **Production-ready**: Same pattern used for real applications
- ✅ **End-to-end**: Complete flow from VM to internet

## Architecture Summary

The complete flow is now:
```
Internet → LoadBalancer → Kubernetes Service → VM Service (port 8080)
```

## Troubleshooting

### LoadBalancer External IP Pending
- This is normal on Civo, wait 2-5 minutes
- Check service status: `kubectl describe svc ubuntu-vm-loadbalancer`

### Service Not Accessible
- Verify VM is running: `kubectl get vmis`
- Check service endpoints: `kubectl get endpoints ubuntu-vm-loadbalancer`
- Test internal connectivity first (Step 7)

## Files in this step
- `ubuntu-vm-loadbalancer.yaml` - LoadBalancer service definition

## Next Step
Congratulations! You've successfully exposed a VM service to the internet. When you're ready to clean up all resources, proceed to [Step 99: Cleanup](../step-99-cleanup/).