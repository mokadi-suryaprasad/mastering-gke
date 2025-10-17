# ⚡ Day 18: GKE Cluster Autoscaler (Node-Level Scaling)

## 🎯 Learning Objectives
By the end of this session, you’ll be able to:
- Understand the concept of **Cluster Autoscaler** in GKE.
- Differentiate between **Pod Autoscaler** and **Node Autoscaler**.
- Configure and enable Cluster Autoscaler in GKE.
- Observe real-time node scaling behavior based on workload.

---

## 🚀 What is GKE Cluster Autoscaler?
The **GKE Cluster Autoscaler** automatically adjusts the number of nodes in a cluster's node pool based on pending pods or underutilized nodes.

It helps optimize costs by scaling down unused nodes and maintaining performance by scaling up when workloads increase.

---

## ⚙️ Key Concepts

| Feature | Description |
|----------|--------------|
| **Scale Up** | Adds nodes when pods are unschedulable due to insufficient resources. |
| **Scale Down** | Removes idle nodes when their workloads can be rescheduled elsewhere. |
| **Node Pool** | A group of nodes within a GKE cluster that can scale independently. |
| **Min/Max Nodes** | Defines the boundaries for autoscaler adjustments. |

---

## 🧠 Difference: HPA vs. Cluster Autoscaler

| Feature | HPA (Pod Level) | Cluster Autoscaler (Node Level) |
|----------|----------------|----------------------------------|
| Target | Pods | Nodes |
| Metric | CPU/Memory usage of pods | Unschedulable pods / idle nodes |
| Action | Adds/removes pods | Adds/removes nodes |
| Scope | Application-level scaling | Infrastructure-level scaling |

---

## 🧩 Prerequisites
- A working **GKE cluster**.
- `gcloud` CLI configured and authenticated.
- IAM permissions to modify cluster settings.

---

## 🏗️ Step 1: Enable Autoscaling on a Node Pool

You can enable autoscaling during cluster creation or update it for an existing node pool.

### ✅ Example: Enable Autoscaler for a Node Pool

```bash
gcloud container clusters update my-cluster   --enable-autoscaling   --min-nodes 1   --max-nodes 5   --node-pool default-pool
```

### ✅ Or create a new node pool with autoscaling
```bash
gcloud container node-pools create scalable-pool   --cluster my-cluster   --enable-autoscaling   --min-nodes 1   --max-nodes 5   --num-nodes 2
```

---

## 🧪 Step 2: Deploy a Sample Workload

Deploy a workload that consumes significant resources to trigger autoscaling.

```bash
kubectl create deployment stress-deploy   --image=polinux/stress   --replicas=10   -- /bin/sh -c "stress --cpu 2 --io 1 --vm 1 --vm-bytes 128M --timeout 300s"
```

---

## 📈 Step 3: Observe Autoscaler in Action

Check cluster and node pool status:
```bash
gcloud container clusters describe my-cluster   --format="table(name, currentNodeCount, status)"
```

Check autoscaler logs in GCP Console → **Kubernetes Engine → Clusters → Details → Autoscaling logs**.

---

## 🧹 Step 4: Clean Up Resources

```bash
kubectl delete deployment stress-deploy
gcloud container node-pools delete scalable-pool --cluster my-cluster
```

---

## 🔍 Troubleshooting Tips
- **Pods remain pending:** Check if the node pool’s max node limit is reached.
- **Autoscaling not triggered:** Verify autoscaler is enabled and sufficient quota exists.
- **Scale down not happening:** Ensure nodes are truly idle and have drainable pods.

---

## 🧭 Summary

| Concept | Description |
|----------|--------------|
| **Cluster Autoscaler** | Dynamically adjusts node count based on workloads. |
| **Benefits** | Cost optimization, flexibility, and improved resource utilization. |
| **Use Case** | Ideal for workloads with fluctuating demands. |

---

## 🎯 Hands-On Exercise
- Enable autoscaler for your GKE node pool.
- Deploy high-resource workloads to trigger scaling.
- Observe scaling events in the GCP Console.
- Record before and after node count snapshots.



