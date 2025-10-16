# ☸️ Day 15 — Taints and Tolerations in Kubernetes

![Taints and Tolerations](https://kubernetes.io/images/docs/taints-tolerations.svg)

## 🎯 Objective
Learn how to **repel unwanted Pods** and **allow only specific workloads** on certain nodes using **Taints** and **Tolerations**.

---

## 🧠 Why Use Taints and Tolerations?
By default, Kubernetes can schedule Pods on **any available Node**.  
But sometimes you want to control this — for example:

- Keep **database Pods** on dedicated nodes  
- Prevent **test Pods** from running on **production nodes**  
- Run **monitoring Pods** only on specific nodes

To achieve this, Kubernetes provides:

- **Taints** → Applied to Nodes to *repel* Pods  
- **Tolerations** → Applied to Pods to *allow* scheduling on tainted nodes

Together, they ensure that only the **right Pods** run on the **right Nodes**.

---

## 🧩 Step 1: Add a Taint to a Node

### Syntax:
```bash
kubectl taint nodes <node-name> key=value:effect
```

### Example:
```bash
kubectl taint nodes gke-cluster-node-1 env=production:NoSchedule
```

✅ Verify:
```bash
kubectl describe node gke-cluster-node-1 | grep Taint
```

Output:
```
Taints: env=production:NoSchedule
```

---

## ⚙️ Step 2: Understand Taint Effects

| Effect | Description |
|--------|--------------|
| **NoSchedule** | Pod will *not* be scheduled unless it has a matching toleration |
| **PreferNoSchedule** | Tries to avoid scheduling Pod, but not guaranteed |
| **NoExecute** | Existing Pods without toleration are evicted, new Pods won’t schedule |

---

## 🚫 Step 3: What Happens Without Toleration?

If you create a normal Pod after applying a taint, it will remain **Pending**.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: nginx
    image: nginx
```

Run:
```bash
kubectl apply -f test-pod.yaml
kubectl get pods -o wide
```

Output:
```
NAME        STATUS    NODE
test-pod    Pending   <none>
```

Reason: The Node is **tainted**, and the Pod does **not tolerate** it.

---

## ✅ Step 4: Add a Toleration to Allow Pod Scheduling

Now, add a **Toleration** in the Pod spec.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: prod-pod
spec:
  tolerations:
  - key: "env"
    operator: "Equal"
    value: "production"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
```

Apply it:
```bash
kubectl apply -f prod-pod.yaml
```

Now check:
```bash
kubectl get pods -o wide
```

✅ You’ll see:
```
NAME        STATUS    NODE
prod-pod    Running   gke-cluster-node-1
```

Because the Pod **tolerates** the taint on that Node.

---

## 💡 Step 5: Multiple Taints Example

You can add more than one taint on a Node.

```bash
kubectl taint nodes gke-cluster-node-1 security=restricted:NoSchedule
kubectl taint nodes gke-cluster-node-1 workload=backend:PreferNoSchedule
```

You can add multiple tolerations in a Pod to match them.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-toleration-pod
spec:
  tolerations:
  - key: "env"
    operator: "Equal"
    value: "production"
    effect: "NoSchedule"
  - key: "workload"
    operator: "Equal"
    value: "backend"
    effect: "PreferNoSchedule"
  containers:
  - name: nginx
    image: nginx
```

---

## 🧱 Step 6: Example with NoExecute (Eviction)

If a node is tainted with `NoExecute`, Pods without matching toleration are **evicted immediately**.

```bash
kubectl taint nodes gke-cluster-node-1 maintenance=true:NoExecute
```

Now, existing Pods without tolerations will be **evicted**.

But you can allow a Pod to **stay temporarily** using `tolerationSeconds`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: maintenance-pod
spec:
  tolerations:
  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
    tolerationSeconds: 60
  containers:
  - name: nginx
    image: nginx
```

⏳ The Pod will stay for 60 seconds even after the taint is added, then get evicted.

---

## 🧰 Step 7: Remove Taints

To remove a taint:

```bash
kubectl taint nodes gke-cluster-node-1 env=production:NoSchedule-
```

(The `-` at the end **removes** the taint)

---

## 🚀 Real-World GKE Use Cases

| Scenario | Description |
|-----------|--------------|
| 🧠 Dedicated Nodes | Taint “db=true:NoSchedule” → Only database Pods can tolerate |
| ⚙️ Maintenance Mode | Temporarily taint nodes with “maintenance=true:NoExecute” |
| 🔒 Secure Workloads | Allow only trusted Pods on secure nodes |
| 💰 Cost Optimization | Run cost-sensitive workloads on preemptible node pools |
| ☁️ Multi-Environment | Separate dev, staging, and prod workloads via taints |

---

## 🧹 Clean Up

```bash
kubectl delete pod test-pod prod-pod multi-toleration-pod maintenance-pod
kubectl taint nodes gke-cluster-node-1 env-
kubectl taint nodes gke-cluster-node-1 workload-
kubectl taint nodes gke-cluster-node-1 maintenance-
```

---

## 📘 Summary

| Concept | Description |
|----------|--------------|
| **Taint** | Marks a Node to repel Pods |
| **Toleration** | Allows specific Pods to run on tainted Nodes |
| **NoSchedule** | New Pods without toleration will not schedule |
| **PreferNoSchedule** | Avoid scheduling but not strictly |
| **NoExecute** | Evicts existing Pods without toleration |
| **tolerationSeconds** | Allows temporary stay before eviction |

---

## 🎓 Hands-On Tips for GKE

1. Create separate node pools for frontend, backend, and database workloads.
2. Apply taints to node pools:
   ```bash
   kubectl taint nodes <node-name> role=frontend:NoSchedule
   ```
3. Add tolerations in corresponding Pod YAMLs.
4. Use taints in combination with **Node Affinity** for fine-grained control.

---

## 🧠 Next Topic

👉 **Day 16 — Pod Priority & Preemption**  
Learn how Kubernetes decides **which Pods are more important** when resources are low.
