# 🧱 Day 20 — Kubernetes Network Policies (Restrict Pod-to-Pod Communication)

## 🎯 Learning Objectives
By the end of this session, you will:
- Understand what **Network Policies** are in Kubernetes  
- Learn how to **restrict pod-to-pod communication**  
- Secure communication **within and across namespaces**  
- Create and apply policies using YAML manifests

---

## ⚙️ 1. What Are Network Policies?
Network Policies in Kubernetes control how pods communicate with each other and with external endpoints.  
They act as **firewall rules** at the network layer, defining which connections are **allowed** or **denied**.

By default, **all traffic is allowed** between pods — until you define a NetworkPolicy.

---

## 🧩 2. Example: Restrict Pod-to-Pod Communication in the Same Namespace

### Create Namespace and Pods
```bash
kubectl create ns dev
kubectl run frontend --image=nginx -n dev
kubectl run backend --image=nginx -n dev
```

### Create Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: dev
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  policyTypes:
  - Ingress
```

### Apply the Policy
```bash
kubectl apply -f allow-frontend-to-backend.yaml
```

✅ Only the `frontend` pod can now access the `backend` pod.

---

## 🌐 3. Secure Communication Between Namespaces

### Scenario
You have:
- `frontend` pod in the `dev` namespace  
- `backend` pod in the `prod` namespace  

You want to **allow traffic only from `frontend.dev` → `backend.prod`**.

### Create Namespaces and Pods
```bash
kubectl create ns dev
kubectl create ns prod

kubectl run frontend --image=nginx -n dev --labels=app=frontend
kubectl run backend --image=nginx -n prod --labels=app=backend
```

### Create Cross-Namespace Network Policy
In the **`prod` namespace**, create the policy below:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dev-frontend
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: dev
      podSelector:
        matchLabels:
          app: frontend
  policyTypes:
  - Ingress
```

### Apply the Policy
```bash
kubectl apply -f allow-dev-frontend.yaml
```

✅ Now only `frontend` in the `dev` namespace can access `backend` in the `prod` namespace.  
All other pods (in any namespace) are **blocked**.

---

## 🧠 Key Takeaways
- Network Policies define **allowed** traffic; all other traffic is **implicitly denied**.
- Use **namespaceSelector** to control **cross-namespace** access.
- Combine with **Calico** or **Cilium** for enhanced network policy enforcement.

---

## 🧰 Commands Summary
| Action | Command |
|--------|----------|
| Apply a policy | `kubectl apply -f <file>.yaml` |
| List policies | `kubectl get networkpolicies -A` |
| Delete a policy | `kubectl delete networkpolicy <name> -n <namespace>` |

---

**Next → Day 21:** [Service Mesh — Secure Communication with mTLS 🔒](Day21-Service-Mesh-mTLS.md)
