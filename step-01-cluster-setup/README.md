# Step 1: Civo Cluster Setup

**Goal**: Create a Kubernetes cluster and verify connectivity

## Create Cluster via Civo Dashboard

1. **Log into your Civo account** at [dashboard.civo.com](https://dashboard.civo.com)
2. **Navigate to "Kubernetes" section**
3. **Click "Create Cluster"**
4. **Choose cluster specifications:**
   - Name: `kubevirt-workshop`
   - Nodes: 3 nodes (medium size)
   - Network: Default
5. **Click "Create cluster"** and wait for provisioning (typically 2-3 minutes)

## Download Kubeconfig

1. **Once cluster is ready**, click on your cluster name
2. **Download the kubeconfig file**
3. **Save it to a secure location** (e.g., `~/Downloads/kubevirt-workshop-kubeconfig`)

## Set KUBECONFIG Environment Variable

```bash
export KUBECONFIG=~/Downloads/kubevirt-workshop-kubeconfig
```

## Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
```

*Sample output*
```
❯ kubectl cluster-info
Kubernetes control plane is running at https://212.2.240.68:6443
CoreDNS is running at https://212.2.240.68:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://212.2.240.68:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


❯ kubectl get nodes
NAME                                            STATUS   ROLES    AGE    VERSION
k3s-workshop-e17a-bbb893-node-pool-8938-ci2dq   Ready    <none>   1m    v1.30.5+k3s1
k3s-workshop-e17a-bbb893-node-pool-8938-cod9s   Ready    <none>   1m   v1.30.5+k3s1
k3s-workshop-e17a-bbb893-node-pool-8938-vakpn   Ready    <none>   1m   v1.30.5+k3s1

```

You should see your cluster information and 3 nodes in Ready state.

## Next Step
Once your cluster is ready and you can see 3 nodes, proceed to [Step 2: KubeVirt Installation](../step-02-kubevirt-installation/README.md).