# ☸️ Day 14 — Node Affinity, Node Anti-Affinity & NodeSelector in Kubernetes

## 🎯 Objective
Learn how to **schedule Pods intelligently** on specific Nodes in a GKE Cluster using:
- **Node Labels**
- **Node Selector**
- **Node Affinity (required & preferred)**
- **Node Anti-Affinity (avoid same node scheduling)**

---

## 🧠 What is Node Scheduling?
In Kubernetes, the **scheduler** decides *which Node* a Pod should run on.  
Sometimes, you may want to **control where Pods run** — for example:
- Run backend Pods only on powerful nodes (with more CPU/RAM)
- Run logging Pods on dedicated nodes
- Run frontend Pods in specific zones (for latency)

That’s where **Node labels**, **NodeSelector**, **Node Affinity**, and **Node Anti-Affinity** come in.

---

## 🏷️ Step 1: Add Labels to Nodes

Labels are **key-value pairs** that help you identify Nodes.

```bash
kubectl get nodes
kubectl label node <node-name> env=production
kubectl label node <node-name> disk=ssd
```

✅ Verify labels:
```bash
kubectl get nodes --show-labels
```

Example Output:
```
gke-cluster-node-1   Ready   <none>   8d   v1.30.2   env=production,disk=ssd
```

---

## ⚙️ Step 2: NodeSelector — Simple Node Scheduling

The **NodeSelector** is the simplest way to tell Kubernetes:
> "Schedule this Pod only on Nodes that have this label."

Example: Schedule a Pod only on `env=production` nodes.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
spec:
  containers:
  - name: nginx
    image: nginx
  nodeSelector:
    env: production
```

🔹 Explanation:
- The Pod will only be scheduled on Nodes with the label `env=production`.
- If no such Node exists, the Pod will stay in **Pending** state.

---

## ⚙️ Step 3: Node Affinity — Advanced Scheduling

`nodeAffinity` gives **more flexibility** than NodeSelector.

It supports:
- **requiredDuringSchedulingIgnoredDuringExecution** → Must match (like NodeSelector)
- **preferredDuringSchedulingIgnoredDuringExecution** → Soft preference

### ✅ Example 1: Required Node Affinity (Hard Rule)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: env
            operator: In
            values:
            - production
  containers:
  - name: backend
    image: nginx
```

### 💡 Example 2: Preferred Node Affinity (Soft Rule)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: recommendation-pod
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd
  containers:
  - name: recommender
    image: nginx
```

### ⚙️ Example 3: Combine Required + Preferred

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: full-affinity-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: env
            operator: In
            values:
            - production
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd
  containers:
  - name: app
    image: nginx
```

---

## 🧩 Node Anti-Affinity — Avoid Running Pods on Same Node

**Node Anti-Affinity** ensures Pods of the same app **do not get scheduled on the same Node**.  
This helps achieve **High Availability (HA)** — if one node goes down, not all replicas are lost.

### 🧠 Example: Avoid Same Node Scheduling

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx
```

🧩 Explanation:
- Each replica of this deployment runs on a **different Node**
- `topologyKey: kubernetes.io/hostname` → ensures Pods are spread across Nodes
- Useful for **frontend**, **API**, or **database replicas**

---

## 🚀 Real-World Use Cases

| Use Case | Example |
|-----------|----------|
| 🧠 Performance | Run ML workloads only on GPU nodes (`gpu=true`) |
| 🔐 Security | Run sensitive workloads only on secure nodes (`env=secure`) |
| 💰 Cost | Schedule dev/test workloads on cheaper nodes (`type=spot`) |
| ⚡ High I/O | Run database Pods on nodes with `disk=ssd` |
| 🧩 High Availability | Spread replicas across different nodes using Anti-Affinity |

---

## 🧹 Clean Up

```bash
kubectl delete pod frontend-pod backend-pod recommendation-pod full-affinity-pod
kubectl delete deployment web-deployment
kubectl label node <node-name> env-
```

---

## 📘 Summary

| Concept | Description |
|----------|--------------|
| **Node Labels** | Add identifiers to nodes |
| **NodeSelector** | Simple label-based scheduling |
| **Node Affinity** | Advanced scheduling using rules |
| **Node Anti-Affinity** | Prevent same-node scheduling for HA |
| **Required** | Hard condition (must match) |
| **Preferred** | Soft condition (best effort) |

---

## 🎓 Hands-On Tips for GKE

1. Label GKE nodes by zone or purpose:
   ```bash
   kubectl label node gke-gkecluster-default-pool-abc123 zone=asia-south1-a
   ```
2. Deploy Pods with affinity to control placement.
3. Use **GKE Autopilot + Affinity rules** to optimize workload cost and performance.

---

## 🧠 Next Topic

👉 **Day 15 — Taints and Tolerations**  
Learn how to **repel unwanted Pods** and **allow only specific workloads** on certain nodes.
