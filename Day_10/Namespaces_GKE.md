# 📂 Day 10 — Kubernetes Namespaces in GKE

## 🧠 Topic: Logical Separation of Environments in GKE

---

## 1️⃣ What is a Namespace?

- A **namespace** is like a **folder** in your Kubernetes cluster.  
- It separates resources such as **Pods, Services, ConfigMaps** so they don’t interfere with each other.  
- Think of it as a **virtual cluster within a cluster**.  

**Why it matters:** In a big cluster used by multiple teams or environments, namespaces prevent chaos and make management easier.

---

## 2️⃣ Why Namespaces Are Important in Production

Imagine a company running **three environments** in the same cluster:  

| Environment | Namespace | Purpose |
|------------|-----------|---------|
| Development | `dev` | Developers test new features |
| Staging | `staging` | QA team tests features before release |
| Production | `prod` | Live environment serving real users |

**Example scenario:**  
- A developer accidentally deploys a faulty Pod.  
- If everything is in the `default` namespace, **production might break**.  
- With namespaces:  
  - `dev` is isolated → problem only affects dev resources  
  - `prod` remains stable and safe

---

## 3️⃣ Key Features of Namespaces

| Feature | Explanation |
|---------|------------|
| Isolation | Resources in one namespace cannot affect another directly |
| RBAC | Permissions can be set per namespace (dev team vs prod team) |
| Environment separation | Easy to distinguish dev, staging, prod apps |
| Resource management | Later, quotas or limits can be applied per namespace |

---

## 4️⃣ Default Namespaces

Kubernetes provides some built-in namespaces:

| Namespace | Purpose |
|-----------|---------|
| `default` | Default namespace if none specified |
| `kube-system` | Kubernetes system components (controller, scheduler, etc.) |
| `kube-public` | Public resources readable by all users |
| `kube-node-lease` | Node heartbeat management |

> Best practice: **create custom namespaces** for applications/environments instead of using `default`.

---

## 5️⃣ Common Use Cases

- **Development Environment:** `dev` namespace  
- **Staging Environment:** `staging` namespace  
- **Production Environment:** `prod` namespace  

> Each namespace can have **isolated resources, RBAC permissions, and environment-specific configuration**.

---

## 6️⃣ Creating Namespaces

**Step 1: Create dev namespace**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```bash
kubectl apply -f namespace-dev.yaml
kubectl get namespaces
```

**Step 2: Create staging namespace**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
```

```bash
kubectl apply -f namespace-staging.yaml
```

**Step 3: Create production namespace**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
```

```bash
kubectl apply -f namespace-prod.yaml
```

---

## 7️⃣ Using Namespaces in Commands

```bash
# Deploy resources in a specific namespace
kubectl apply -f my-app.yaml -n dev

# List all resources in a namespace
kubectl get all -n staging

# Switch default namespace for current context
kubectl config set-context --current --namespace=prod
```

> By specifying `-n <namespace>` you ensure you’re working in the correct environment.

---

## 8️⃣ Production Example

Imagine a company running an **e-commerce application**:

- **dev namespace:** Developers test new features like a “discount code” service.  
- **staging namespace:** QA team tests the full checkout flow before it goes live.  
- **prod namespace:** Only tested and approved services are running, serving actual customers.  

With namespaces:  

- If the new “discount code” service crashes in dev → **production unaffected**.  
- Each environment can have **different database connections, configurations, and resource usage**.  

---

## 9️⃣ Best Practices

1. Always create separate namespaces for **dev, staging, and prod**.  
2. Never deploy all apps in the `default` namespace.  
3. Use **RBAC** to control who can deploy in each namespace.  
4. Keep naming consistent (`dev`, `staging`, `prod`) for clarity.  

---

## ✅ Summary

- **Namespaces** are logical partitions in Kubernetes.  
- Provide **isolation, security, and environment separation**.  
- In production, using dev/staging/prod namespaces ensures **safe deployments** and **stable services**.  
- They are the foundation for advanced resource management like **quotas, limits, and RBAC**.

---

## 10️⃣ Quick Reference Commands

```bash
kubectl apply -f namespace-dev.yaml
kubectl apply -f namespace-staging.yaml
kubectl apply -f namespace-prod.yaml
kubectl get namespaces
kubectl apply -f app.yaml -n dev
kubectl get all -n staging
kubectl config set-context --current --namespace=prod
```
