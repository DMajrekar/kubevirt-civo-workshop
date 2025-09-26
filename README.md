# KubeVirt Virtual Machines on Civo Kubernetes Workshop

This workshop demonstrates how to run virtual machines (VMs) on Kubernetes using KubeVirt and Civo's managed Kubernetes platform. You'll learn to create VMs, deploy services within them, and establish bidirectional communication between VMs and Kubernetes cluster services.

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

1. **Get Latest KubeVirt Version**
   ```bash
   export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
   echo $VERSION
   ```

2. **Deploy KubeVirt Operator**
   ```bash
   kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
   ```

3. **Create KubeVirt CR**
   ```bash
   kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
   ```

4. **Verify Installation**
   ```bash
   # Check KubeVirt status (should show "Deployed")
   kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"

   # Check all components
   kubectl get all -n kubevirt
   ```

   Wait until all pods are in Running state before proceeding.

### 3. virtctl Setup

**Goal**: Install virtctl CLI for VM management

1. **Install virtctl Binary**
   ```bash
   VERSION=$(kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.observedKubeVirtVersion}")
   ARCH=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/') || windows-amd64.exe
   echo ${ARCH}
   curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-${ARCH}
   chmod +x virtctl
   sudo install virtctl /usr/local/bin
   ```

2. **Verify Installation**
   ```bash
   virtctl version
   ```

### 4. Virtual Machine Creation

**Goal**: Create and manage your first VM (following KubeVirt Lab 1)

1. **Create VM Manifest**
   Create a file called `testvm.yaml`:
   ```yaml
   apiVersion: kubevirt.io/v1
   kind: VirtualMachine
   metadata:
     name: testvm
   spec:
     running: false
     template:
       metadata:
         labels:
           kubevirt.io/size: small
           kubevirt.io/domain: testvm
       spec:
         domain:
           devices:
             disks:
             - name: containerdisk
               disk:
                 bus: virtio
             - name: cloudinitdisk
               disk:
                 bus: virtio
             interfaces:
             - name: default
               masquerade: {}
           resources:
             requests:
               memory: 64M
         networks:
         - name: default
           pod: {}
         volumes:
         - name: containerdisk
           containerDisk:
             image: quay.io/kubevirt/cirros-container-disk-demo
         - name: cloudinitdisk
           cloudInitNoCloud:
             userDataBase64: SGkuXG4=
   ```

2. **Deploy VM**
   ```bash
   kubectl apply -f testvm.yaml
   ```

3. **Start the VM**
   ```bash
   virtctl start testvm
   ```

4. **Check VM Status**
   ```bash
   kubectl get vms
   kubectl get vmis
   ```

5. **Connect to VM Console** (optional)
   ```bash
   virtctl console testvm
   ```

   Press `Ctrl+]` to disconnect from console.

### 5. Deploy Service within VM

**Goal**: Run an application inside the virtual machine

1. **Access VM**
   ```bash
   virtctl console testvm
   ```

2. **Install and Configure Simple Web Server**
   Once connected to the VM:
   ```bash
   # Login with cirros/gocubsgo
   sudo su -

   # Install a simple HTTP server
   echo "Hello from KubeVirt VM!" > /tmp/index.html

   # Start simple HTTP server on port 8080
   cd /tmp
   python -m SimpleHTTPServer 8080 &
   ```

3. **Test Service from Within VM**
   ```bash
   curl localhost:8080
   ```

   You should see "Hello from KubeVirt VM!" response.

4. **Exit VM Console**
   Press `Ctrl+]` to disconnect.

### 6. Expose VM Service via Kubernetes

**Goal**: Make VM service accessible through Kubernetes Service

1. **Create Kubernetes Service**
   Create `testvm-service.yaml`:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: testvm-service
   spec:
     selector:
       kubevirt.io/domain: testvm
     ports:
     - protocol: TCP
       port: 80
       targetPort: 8080
     type: ClusterIP
   ```

2. **Apply Service**
   ```bash
   kubectl apply -f testvm-service.yaml
   ```

3. **Test Internal Access**
   ```bash
   # Create a test pod to access the service
   kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh

   # Inside the test pod:
   wget -qO- http://testvm-service
   exit
   ```

### 7. Cluster to VM Communication

**Goal**: Demonstrate Kubernetes services can interact with VM services

1. **Deploy Test Application**
   Create `test-app.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: test-app
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: test-app
     template:
       metadata:
         labels:
           app: test-app
       spec:
         containers:
         - name: test-app
           image: busybox
           command: ['sleep', '3600']
   ```

2. **Deploy Application**
   ```bash
   kubectl apply -f test-app.yaml
   ```

3. **Test Communication from Pod to VM**
   ```bash
   kubectl exec -it deployment/test-app -- sh

   # Inside the pod:
   wget -qO- http://testvm-service
   exit
   ```

### 8. VM to Cluster Communication

**Goal**: Show VM can access Kubernetes cluster services

1. **Create a Simple Cluster Service**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl expose deployment nginx --port=80 --name=nginx-service
   ```

2. **Test from VM**
   ```bash
   virtctl console testvm

   # Inside the VM:
   curl nginx-service.default.svc.cluster.local
   ```

   This demonstrates the VM can resolve and access Kubernetes services.

### 9. Expose VM Service to Internet

**Goal**: Make VM service accessible from the internet using LoadBalancer

1. **Create LoadBalancer Service**
   Create `testvm-loadbalancer.yaml`:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: testvm-loadbalancer
   spec:
     selector:
       kubevirt.io/domain: testvm
     ports:
     - protocol: TCP
       port: 80
       targetPort: 8080
     type: LoadBalancer
   ```

2. **Apply LoadBalancer Service**
   ```bash
   kubectl apply -f testvm-loadbalancer.yaml
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
   kubectl delete vm testvm
   kubectl delete svc testvm-service testvm-loadbalancer nginx-service
   kubectl delete deployment test-app nginx
   ```

2. **Delete Cluster**
   - Go back to Civo dashboard
   - Select your cluster
   - Click "Delete" and confirm

## Troubleshooting

### Common Issues

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
