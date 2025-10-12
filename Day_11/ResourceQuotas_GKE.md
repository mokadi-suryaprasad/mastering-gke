# 📏 Day 10 — Resource Quotas & Limits in GKE

## 🧠 Topic: Namespace-level and Pod-level Resource Management

---

## 1️⃣ Part 1: Resource Quotas (Namespace Level)

### 1.1 Why Resource Quotas Exist

- In a shared cluster, multiple teams or apps run together.  
- Without limits, one team could **consume all CPU/memory**, causing other apps to fail.  
- **ResourceQuota** ensures **fair usage** per namespace.

### 1.2 Key Concepts

| Concept         | Purpose |
|-----------------|---------|
| **ResourceQuota** | Sets total CPU, memory, pods, services, etc., allowed in a namespace |
| **Namespace**     | Logical grouping of resources; quota applies per namespace |
| **Hard limits**   | Maximum resources allowed for the namespace |

### 1.3 Example: Resource Quota YAML

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "5"
    services: "2"
    requests.cpu: "2"
    requests.memory: "2Gi"
    limits.cpu: "4"
    limits.memory: "4Gi"
```

**Explanation:**

- **Pods:** max 5 Pods in `dev` namespace  
- **Services:** max 2 Services  
- **Requests:** total CPU ≤ 2, memory ≤ 2Gi  
- **Limits:** total CPU ≤ 4, memory ≤ 4Gi  

### 1.4 Commands to Apply and Monitor

```bash
kubectl apply -f namespace.yaml
kubectl apply -f resource-quota.yaml
kubectl describe quota dev-quota -n dev
kubectl get all -n dev
```

---

### 1.5 Visual Diagram

```
Namespace: dev
-------------------------------
ResourceQuota:
  pods: 5
  services: 2
  requests.cpu: 2
  requests.memory: 2Gi
  limits.cpu: 4
  limits.memory: 4Gi

Pods:
  pod1: requests=200m/256Mi
  pod2: requests=300m/512Mi
  ...
```

---

## 2️⃣ Part 2: Resource Requests & Limits (Pod Level)

### 2.1 Why Requests & Limits Exist

- Even within a quota, a Pod could **consume too much CPU or memory**.  
- **Requests** → Minimum resources guaranteed for the Pod  
- **Limits** → Maximum resources the Pod can use  

### 2.2 Pod-level Example with Requests & Limits

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:stable
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

**Explanation:**

- Requests: Pod **guaranteed 250m CPU & 256Mi memory**  
- Limits: Pod **cannot use more than 500m CPU & 512Mi memory**  

---

### 2.3 Deploying Multiple Pods within Quota

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod2
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:stable
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "1Gi"
```

- Kubernetes checks **ResourceQuota** first, then **Pod requests/limits**.  
- If total requests exceed namespace quota → Pod creation fails.  

---

### 2.4 Commands to Apply & Monitor

```bash
kubectl apply -f pod1.yaml
kubectl apply -f pod2.yaml
kubectl describe pod pod1 -n dev
kubectl describe quota dev-quota -n dev
kubectl get all -n dev
```

---

### 2.5 Visual Diagram

```
Namespace: dev (ResourceQuota)
--------------------------------
Total requests.cpu = 2
Total requests.memory = 2Gi

Pods:
 pod1: requests=250m/256Mi, limits=500m/512Mi
 pod2: requests=500m/512Mi, limits=1/1Gi
 ...
```

---

## ✅ Summary

1. **Namespace-level ResourceQuota** → Limits total Pods, Services, CPU, memory  
2. **Pod-level Requests & Limits** → Guarantees and caps per Pod  
3. Combined → Ensures **fair usage and stable cluster performance**  
4. Monitor with `kubectl describe quota` and `kubectl describe pod`  

---

### 3️⃣ Quick Reference Commands

```bash
kubectl apply -f namespace.yaml
kubectl apply -f resource-quota.yaml
kubectl apply -f pod1.yaml
kubectl apply -f pod2.yaml
kubectl describe quota dev-quota -n dev
kubectl describe pod pod1 -n dev
kubectl get all -n dev
```

> Proper resource management ensures **high availability, fairness, and predictable cluster behavior** in GKE.
