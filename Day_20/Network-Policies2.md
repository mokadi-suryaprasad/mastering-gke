# 🧱 Day 20 — Kubernetes Network Policies  
### Restrict Pod-to-Pod Communication

In Kubernetes, **Network Policies** are used to control how Pods communicate with each other and other network endpoints.  
They define **who can talk to whom** — enhancing cluster security by restricting unnecessary network access.

---

## 🎯 Learning Objectives

By the end of this session, you’ll be able to:

- Understand what Network Policies are and why they’re needed  
- Create policies to **restrict traffic** between Pods  
- Allow **specific ingress and egress** traffic  
- Test policies using simple Pods  

---

## ⚙️ 1. What are Network Policies?

A **NetworkPolicy** resource defines how Pods are allowed to communicate with:

- Other Pods  
- Namespaces  
- External IPs  

By default, **all traffic between Pods is allowed**.  
Once a **NetworkPolicy** is applied, **only explicitly allowed traffic** is permitted — everything else is **denied**.

---

## 🧩 2. Example Scenario

Let’s assume you have the following Pods in the `default` namespace:

- **frontend** Pod  
- **backend** Pod  
- **db** Pod  

Goal:  
Allow **frontend → backend** communication,  
but **block backend → db** and all other cross-pod traffic.

---

## 🛠️ 3. Create Namespace and Pods

```bash
kubectl create namespace demo-network
kubectl run frontend --image=nginx --namespace=demo-network
kubectl run backend --image=nginx --namespace=demo-network
kubectl run db --image=nginx --namespace=demo-network
```

Verify pods:
```bash
kubectl get pods -n demo-network -o wide
```

---

## 🚫 4. Restrict All Pod-to-Pod Communication

First, create a **default deny** NetworkPolicy.

**File:** `default-deny-all.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: demo-network
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Apply it:
```bash
kubectl apply -f default-deny-all.yaml
```

🧠 Now, all Pods in the `demo-network` namespace **cannot communicate** with each other.

---

## ✅ 5. Allow Frontend → Backend Traffic

**File:** `allow-frontend-to-backend.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: demo-network
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

Label the pods:
```bash
kubectl label pod frontend app=frontend -n demo-network
kubectl label pod backend app=backend -n demo-network
kubectl label pod db app=db -n demo-network
```

Apply policy:
```bash
kubectl apply -f allow-frontend-to-backend.yaml
```

---

## 🔍 6. Test Connectivity

Exec into the **frontend** Pod and try to reach **backend**:

```bash
kubectl exec -it frontend -n demo-network -- curl backend
```

✅ Should work!

Now try reaching **db**:
```bash
kubectl exec -it frontend -n demo-network -- curl db
```
❌ Should fail!

---

## 🌐 7. Allow Egress to External Services (Optional)

If Pods need to connect to the internet or external API endpoints, you can allow egress:

**File:** `allow-egress-external.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-external
  namespace: demo-network
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
```

Apply:
```bash
kubectl apply -f allow-egress-external.yaml
```

---

## 🧠 8. Key Points

- Without a Network Policy → **all traffic allowed**
- With a Network Policy → **deny all by default**
- Use **labels** carefully — they determine policy scope
- Combine multiple NetworkPolicies for complex environments
- You need a **CNI plugin** that supports Network Policies (e.g., Calico, Cilium, Weave Net)

---

## 🧾 Summary

| Concept | Description |
|----------|--------------|
| **Default Behavior** | All Pods can communicate freely |
| **NetworkPolicy** | Kubernetes resource to control network traffic |
| **Ingress Rules** | Define who can send traffic **to** a Pod |
| **Egress Rules** | Define where a Pod can **send** traffic |
| **Default Deny** | Secure baseline — deny all, then allow selectively |

---

## 🧱 Exercise

- Create a new policy that allows **only db Pod** to accept traffic **from backend**.  
- Test by using `curl` commands between Pods.

---

## 🧩 References

- [Kubernetes Docs — Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Calico Network Policy Guide](https://docs.tigera.io/calico/latest/network-policy/)

---

**Next → Day 21:** Service Mesh — Secure Communication with mTLS 🔒
