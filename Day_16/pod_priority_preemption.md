# ☸️ Day 16 — Pod Priority & Preemption in Kubernetes

## 🎯 Objective
Learn how Kubernetes decides **which Pods are more important** when resources are low using **Pod Priority and Preemption**.

---

## 🧠 Why Pod Priority & Preemption?

In a Kubernetes cluster, resources (CPU, memory) may become scarce.  
Kubernetes needs a way to **decide which Pods to schedule first** and **which Pods can be evicted**.

- **Pod Priority** → Assigns an integer value to a Pod to indicate importance. Higher priority = more important.
- **Preemption** → If a high-priority Pod cannot be scheduled due to lack of resources, Kubernetes **evicts low-priority Pods** to make space.

This ensures critical workloads run even under resource constraints.

---

## 🧩 Step 1: Enable Priority and Preemption

1. Verify that **PriorityClass** is supported in your cluster (GKE supports it by default).
2. You can create custom PriorityClasses to assign priorities to Pods.

### Example: Create a PriorityClass
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "This is a high-priority class."
```

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: low-priority
value: 100
globalDefault: false
description: "This is a low-priority class."
```

Apply it:
```bash
kubectl apply -f high-priority-class.yaml
kubectl apply -f low-priority-class.yaml
kubectl get priorityclass
```

Output:
```
NAME            VALUE   GLOBAL-DEFAULT   AGE
high-priority   1000    false            1m
low-priority    100     false            1m
system-node-critical 2000000000 true     10d
system-cluster-critical 2000000000 true   10d
```

---

## ⚙️ Step 2: Assign Priority to Pods

### High-priority Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-pod
spec:
  priorityClassName: high-priority
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
```
### Low-priority Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: noncritical-pod
spec:
  priorityClassName: low-priority
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
```

---

## ⚙️ Step 3: Observe Preemption

1. Fill the cluster with low-priority Pods until resources are scarce.
2. Deploy a **high-priority Pod** that cannot schedule due to lack of resources.
3. Kubernetes will **evict one or more low-priority Pods** to make room for the high-priority Pod.

Check status:
```bash
kubectl get pods -o wide
kubectl describe pod critical-pod
```

You’ll see that **noncritical Pods were evicted** and critical Pod is scheduled.

---

## ⚙️ Step 4: Using Pod Priority in Deployments

You can also assign priorityClassName in Deployment Pod templates. All replicas inherit the priority and preemption behavior.

### High-Priority Deployment

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      priorityClassName: high-priority
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: "500m"
            memory: "256Mi"
```
### Low-Priority Deployment

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: noncritical-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: noncritical-app
  template:
    metadata:
      labels:
        app: noncritical-app
    spec:
      priorityClassName: low-priority
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: "500m"
            memory: "256Mi"
```
✅ How it works:

- Kubernetes schedules Pods based on priorityClassName and available resources.

- If high-priority Pods cannot schedule, it evicts lower-priority Pods automatically.

- Scaling a Deployment inherits the same priority rules.

💡 Best Practices:

- Combine with Node Affinity & Taints/Tolerations for dedicated resources.

- Always define requests/limits for accurate preemption behavior.

- Only assign high priority to critical workloads to avoid excessive evictions.

---

## 🧩 Step 5: Real-World Use Cases

| Scenario | Example |
|----------|---------|
| 🧠 Critical workloads | Run payment gateway, database, or API services with high priority |
| ⚡ Burst workloads | High-priority batch jobs or ML workloads that must run |
| 💰 Cost-sensitive | Noncritical workloads (dev/test) can be low priority and evicted if needed |
| ☁️ Multi-tenant clusters | Ensure important tenants’ workloads are scheduled first |

---

## 🧹 Step 6: Clean Up

```bash
kubectl delete pod critical-pod noncritical-pod
kubectl delete deployment critical-deployment noncritical-deployment
kubectl delete priorityclass high-priority low-priority
```

---

## 📘 Summary

| Concept               | Description                                                            |
| --------------------- | ---------------------------------------------------------------------- |
| **Pod Priority**      | Numeric value indicating Pod importance                                |
| **Preemption**        | Evict lower-priority Pods to schedule higher-priority Pods             |
| **PriorityClass**     | Defines a reusable class for assigning Pod priorities                  |
| **Requests & Limits** | Combined with Priority, determines if Pod can be scheduled             |
| **Eviction**          | Automatic removal of low-priority Pods when resources are insufficient |
| **Deployments**       | All replicas inherit priority and preemption behavior                  |


---

## 🎓 Hands-On Tips for GKE

1. Use **PriorityClass** to separate critical vs non-critical workloads.
2. Combine **Pod Priority + Node Affinity + Taints/Tolerations** for robust scheduling policies.
3. Monitor cluster resource usage (`kubectl top nodes/pods`) to test preemption behavior.
