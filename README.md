# KubeVirt Virtual Machines on Civo Kubernetes Workshop

This workshop demonstrates how to run virtual machines (VMs) on Kubernetes using KubeVirt and Civo's managed Kubernetes platform. You'll learn to create VMs, deploy services within them, and establish bidirectional communication between VMs and Kubernetes cluster services.

## Architecture Overview

![Workshop Architecture](workshop-architecture-diagram.png)

This diagram shows the complete workshop architecture, demonstrating how VMs integrate with Kubernetes services, storage, and external access through Civo's LoadBalancer.

## Workshop Overview

By the end of this workshop, you will have:

- Created a Kubernetes cluster on Civo
- Installed and configured KubeVirt
- Created and managed virtual machines in Kubernetes
- Deployed services within VMs
- Established communication between VMs and Kubernetes services
- Exposed VM services to the internet via LoadBalancer

## Prerequisites

Before starting this workshop, ensure you have:

- **Civo workshop account** - Sign up at [civo.com](https://www.civo.com)
- **kubectl** - Kubernetes command-line tool ([installation guide](https://kubernetes.io/docs/tasks/tools/))
- **virtctl** - We'll guide you through the installation during the workshop

## Getting Started

1. **Clone this repository**
   ```bash
   git clone https://github.com/your-username/kubevirt-civo-workshop.git
   cd kubevirt-civo-workshop
   ```

## Workshop File Structure

```
kubevirt-civo-workshop/
├── manifests/           # Kubernetes YAML files
│   ├── testvm.yaml
│   ├── testvm-service.yaml
│   ├── testvm-loadbalancer.yaml
│   └── test-app.yaml
├── scripts/             # Helper scripts
│   ├── setup-kubevirt.sh
│   ├── install-virtctl.sh
│   └── verify-setup.sh
├── docs/                # Additional documentation
│   └── troubleshooting.md
├── CLAUDE.md            # Claude Code automation
└── README.md            # This workshop guide
```

## Workshop Steps

### 1. Civo Cluster Setup

**Goal**: Create a Kubernetes cluster and verify connectivity

1. **Create Cluster via Civo Dashboard**
   - Log into your Civo account at [dashboard.civo.com](https://dashboard.civo.com)
   - Navigate to "Kubernetes" section
   - Click "Create Cluster"
   - Choose cluster specifications:
     - Name: `kubevirt-workshop`
     - Nodes: 3 nodes (medium size recommended)
     - Network: Default
   - Click "Create cluster" and wait for provisioning (typically 2-3 minutes)

2. **Download Kubeconfig**

   - Once cluster is ready, click on your cluster name
   - Download the kubeconfig file
   - Save it to a secure location (e.g., `~/Downloads/kubevirt-workshop-kubeconfig`)

3. **Set KUBECONFIG Environment Variable**

   ```bash
   export KUBECONFIG=~/Downloads/kubevirt-workshop-kubeconfig
   ```

4. **Verify Cluster Access**

   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

   You should see your cluster information and 3 nodes in Ready state.

### 2. KubeVirt Installation

**Goal**: Install KubeVirt operator and verify it's running

1. **Run KubeVirt Setup Script**
   ```bash
   ./scripts/setup-kubevirt.sh
   ```

   This script will:
   - Deploy kernel modules DaemonSet (loads `tun` and `vhost-net` modules)
   - Wait for kernel modules to be ready on all nodes
   - Download the latest KubeVirt version
   - Deploy the KubeVirt operator
   - Create the KubeVirt CR (with managed cluster compatibility)
   - Wait for the installation to complete
   - Verify the installation status

2. **Manual Installation (Alternative)**
   If you prefer to run commands manually:

   a) **Deploy Kernel Modules First** (required for all clusters):
   ```bash
   # Deploy kernel modules DaemonSet
   kubectl apply -f manifests/kernel-modules-daemonset.yaml

   # Wait for modules to be loaded on all nodes
   kubectl rollout status daemonset/kubevirt-kernel-modules -n kube-system --timeout=300s
   ```

   b) **Standard Clusters** (with control plane access):
   ```bash
   export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
   kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
   kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
   kubectl wait --for=condition=Available kubevirt kubevirt --namespace=kubevirt --timeout=10m

   # Wait for fully deployed status
   kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}"
   ```

   c) **Managed Clusters** (like Civo - no control plane access):
   ```bash
   export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
   kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"

   # Use the managed cluster compatible CR
   kubectl apply -f manifests/kubevirt-cr-managed.yaml

   # Or apply and patch the standard CR
   # kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
   # kubectl patch kubevirt kubevirt -n kubevirt --type='merge' -p='{"spec":{"infra":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"},"tolerations":[]}},"workloads":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"},"tolerations":[]}}}}'

   kubectl wait --for=condition=Available kubevirt kubevirt --namespace=kubevirt --timeout=10m

   # Verify deployment phase
   kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}"
   ```

3. **Verify Installation**
   ```bash
   # Should show "Deployed"
   kubectl get kubevirt kubevirt -n kubevirt -o jsonpath="{.status.phase}"

   # All pods should be Running
   kubectl get pods -n kubevirt
   ```

### 3. virtctl Setup

**Goal**: Install virtctl CLI for VM management

1. **Run virtctl Installation Script**
   ```bash
   ./scripts/install-virtctl.sh
   ```

   This script will:
   - Detect your system architecture
   - Download the correct virtctl version to the current directory
   - Make it executable
   - Verify the download

2. **Manual virtctl Installation (Alternative)**
   If you prefer to download virtctl manually:
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

3. **Verify Setup**
   ```bash
   ./scripts/verify-setup.sh
   ```

   This will check that kubectl, cluster connectivity, KubeVirt, and virtctl are all working properly.

### 4. CDI Installation (Optional - for Full Linux VMs)

**Goal**: Install CDI (Containerized Data Importer) for importing cloud images

CDI allows you to create VMs from cloud images (like Ubuntu, Fedora) instead of minimal container images. This provides full Linux environments with package managers and standard tools.

1. **Run CDI Setup Script**
   ```bash
   ./scripts/setup-cdi.sh
   ```

   This script will:
   - Download and install the latest CDI operator
   - Create the CDI custom resource
   - Wait for CDI to be fully deployed
   - Verify the installation

2. **Manual CDI Installation (Alternative)**
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

3. **Create Ubuntu DataVolume**
   ```bash
   kubectl apply -f manifests/ubuntu-datavolume.yaml

   # Monitor the import process
   kubectl get datavolume ubuntu -w
   ```

   **Note**: The DataVolume will download a Ubuntu 24.04 LTS cloud image. This may take several minutes depending on your internet connection.

### 5. Virtual Machine Creation

**Goal**: Create and manage your first VM

You have two options:

#### Option A: Quick CirrOS VM (Lightweight)

1. **Deploy VM**
   ```bash
   kubectl apply -f manifests/testvm.yaml
   ```

2. **Start the VM**
   ```bash
   ./virtctl start testvm
   ```

3. **Check VM Status**
   ```bash
   kubectl get vms
   kubectl get vmis
   ```

4. **Connect to VM Console** (optional)
   ```bash
   ./virtctl console testvm
   ```

   Login with `cirros` / `gocubsgo`. Press `Ctrl+]` to disconnect.

#### Option B: Full Ubuntu VM (Requires CDI)

1. **Deploy Ubuntu VM** (after DataVolume is ready)
   ```bash
   kubectl apply -f manifests/ubuntu-vm.yaml
   ```

2. **Start the VM**
   ```bash
   ./virtctl start ubuntu-vm
   ```

3. **Check VM Status**
   ```bash
   kubectl get vms
   kubectl get vmis
   ```

4. **Connect to VM Console**
   ```bash
   ./virtctl console ubuntu-vm
   ```

   Login with `ubuntu` / `ubuntu`. Press `Ctrl+]` to disconnect.

### 6. Deploy Service within VM

**Goal**: Run an application inside the virtual machine

#### For CirrOS VM (Option A):

1. **Access VM**
   ```bash
   ./virtctl console testvm
   ```

2. **Note about CirrOS limitations**
   ```bash
   # Login with cirros/gocubsgo

   # CirrOS is a minimal image without Python or web servers
   # For HTTP services, use the Fedora VM option instead
   echo "Hello from CirrOS VM!" > /tmp/index.html
   cat /tmp/index.html
   ```

   **Note**: CirrOS doesn't have Python or web server tools. For HTTP service demos, use Option B (Ubuntu VM).

#### For Ubuntu VM (Option B):

1. **Access VM**
   ```bash
   ./virtctl console ubuntu-vm
   ```

2. **Install and Configure Web Server**
   ```bash
   # Login with ubuntu/ubuntu

   # Create content
   echo "Hello from Ubuntu VM!" > /tmp/index.html

   # Start Python HTTP server
   cd /tmp
   python3 -m http.server 8080 &
   ```

3. **Test Service from Within VM**
   ```bash
   curl localhost:8080
   ```

4. **Exit VM Console**
   Press `Ctrl+]` to disconnect.

### 7. Expose VM Service via Kubernetes

**Goal**: Make VM service accessible through Kubernetes Service

1. **Apply Service**
   ```bash
   kubectl apply -f manifests/testvm-service.yaml
   ```

2. **Test Internal Access**
   ```bash
   # Create a test pod to access the service directly
   kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://ubuntu-vm-service
   ```

### 8. Cluster to VM Communication

**Goal**: Demonstrate Kubernetes services can interact with VM services

**Test Communication from Pod to VM**
```bash
# Create a temporary pod that fetches content from the VM service
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://ubuntu-vm-service
```

You should see "Hello from Ubuntu VM!" response, demonstrating successful communication from cluster pods to the VM service.

### 9. VM to Cluster Communication

**Goal**: Show VM can access Kubernetes cluster services

1. **Create a Simple Cluster Service**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl apply -f manifests/nginx-service.yaml
   ```

2. **Test from VM**
   ```bash
   ./virtctl console testvm

   # Inside the VM:
   curl nginx-service.default.svc.cluster.local
   ```

   This demonstrates the VM can resolve and access Kubernetes services.

### 10. Expose VM Service to Internet

**Goal**: Make VM service accessible from the internet using LoadBalancer

1. **Apply LoadBalancer Service**
   ```bash
   kubectl apply -f manifests/testvm-loadbalancer.yaml
   ```

3. **Get External IP**
   ```bash
   kubectl get svc testvm-loadbalancer -w
   ```

   Wait for the EXTERNAL-IP to be assigned (may take a few minutes).

4. **Test External Access**
   Once you have the external IP:
   ```bash
   curl http://<EXTERNAL-IP>
   ```

   You should see "Hello from KubeVirt VM!" from the internet!

## Cleanup

When you're done with the workshop:

1. **Delete Resources**
   ```bash
   # Delete VMs
   kubectl delete vm ubuntu-vm testvm

   # Delete services
   kubectl delete svc ubuntu-vm-service ubuntu-vm-loadbalancer
   kubectl delete -f manifests/nginx-service.yaml

   # Delete deployments
   kubectl delete deployment nginx

   # Delete DataVolume (optional - also deletes PVC)
   kubectl delete datavolume ubuntu
   ```

2. **Delete Cluster**
   - Go back to Civo dashboard
   - Select your cluster
   - Click "Delete" and confirm

## Troubleshooting

For detailed troubleshooting information, see [docs/troubleshooting.md](docs/troubleshooting.md).

### Quick Fixes

1. **VM Won't Start**
   ```bash
   kubectl describe vm testvm
   kubectl get events --field-selector involvedObject.name=testvm
   ```

2. **Can't Connect to VM Console**
   - Ensure VM is running: `kubectl get vmis`
   - Check VM events: `kubectl describe vmi testvm`

3. **Service Not Accessible**
   - Check service endpoints: `kubectl get endpoints testvm-service`
   - Verify VM is running and service is active inside VM

4. **LoadBalancer External IP Pending**
   - This is normal on Civo, it may take 2-5 minutes
   - Check service status: `kubectl describe svc testvm-loadbalancer`

## What You've Learned

- How to set up KubeVirt on a Kubernetes cluster
- Creating and managing virtual machines in Kubernetes
- Running services within VMs
- Networking between VMs and Kubernetes services
- Exposing VM services to the internet
- The power of combining traditional VMs with cloud-native Kubernetes

## Next Steps

- Explore more KubeVirt features like persistent storage
- Try different VM operating systems
- Implement more complex networking scenarios
- Look into VM migration capabilities

## Resources

- [KubeVirt Documentation](https://kubevirt.io/)
- [KubeVirt Labs](https://kubevirt.io/labs/)
- [Civo Documentation](https://www.civo.com/docs)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
