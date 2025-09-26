# Step 6: Deploy Service within VM

**Goal**: Run an application inside the virtual machine

## Access Ubuntu VM

```bash
./virtctl console ubuntu-vm
```

## Install and Configure Web Server

```bash
# Login with ubuntu/ubuntu

# Create content
echo "Hello from Ubuntu VM!" > /tmp/index.html

# Start Python HTTP server
cd /tmp
python3 -m http.server 8080 &
```

## Test Service from Within VM

```bash
curl localhost:8080
```

You should see "Hello from Ubuntu VM!" response.

## Exit VM Console

Press `Ctrl+]` to disconnect from the VM console.


## What We've Accomplished

- ✅ Deployed a web service inside a VM
- ✅ Verified the service responds locally
- ✅ Demonstrated VM can run standard applications

## Comparison with CirrOS

If you tried this with the CirrOS VM from Step 3:
- ❌ No Python available
- ❌ Limited tools for web services
- ❌ Minimal environment

This shows why CDI and full Linux images are valuable for real applications.


## Next Step
Now that we have a service running in the VM, let's expose it through Kubernetes services. Proceed to [Step 7: Expose Services](../step-07-expose-services/).