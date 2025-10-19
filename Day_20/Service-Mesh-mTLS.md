# 🕸️ Day 21 — Service Mesh  
### Secure Communication with mTLS 🔒

A **Service Mesh** is a dedicated infrastructure layer for controlling, observing, and securing service-to-service (pod-to-pod) communication within a Kubernetes cluster — **without modifying application code**.

It handles **traffic routing, observability, retries, security (mTLS),** and **policy enforcement** transparently using **sidecar proxies**.

---

## 🎯 Learning Objectives

By the end of this session, you’ll be able to:

- Understand what a Service Mesh is and why it’s needed  
- Deploy a sample Service Mesh (Istio)  
- Enable **mutual TLS (mTLS)** between services  
- Observe secure service-to-service communication  
- Compare Service Mesh vs NetworkPolicy  

---

## ⚙️ 1. What Is a Service Mesh?

A **Service Mesh** sits between services using lightweight proxies (usually Envoy) injected as **sidecars** into each Pod.

Each proxy handles:

- Service discovery  
- Traffic routing and load balancing  
- mTLS encryption  
- Telemetry (metrics, logs, traces)  
- Access control and fault injection  

Popular Service Mesh tools:
- 🌀 **Istio**  
- 🧩 **Linkerd**  
- 🐙 **Consul**  
- 🔗 **Kuma**

---

## 🧩 2. Why Use Service Mesh?

| Problem | Traditional Approach | Service Mesh Solution |
|----------|----------------------|------------------------|
| Secure Pod Communication | Manual TLS setup | Built-in mTLS |
| Observability | Custom code / sidecars | Metrics & tracing built-in |
| Traffic Management | LoadBalancer or Ingress | Smart routing & retries |
| Policy Enforcement | NetworkPolicies | Fine-grained RBAC |

---

## 🛠️ 3. Install Istio (Quick Demo)

Install Istio CLI:

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
```

Install Istio into your cluster:

```bash
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled
```

Verify:
```bash
kubectl get pods -n istio-system
```

---

## 🧱 4. Deploy Sample Application

Use the **Bookinfo** app (official Istio demo):

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

Check:
```bash
kubectl get pods
kubectl get svc
```

---

## 🔐 5. Enable Mutual TLS (mTLS)

Istio can enforce **strict mTLS**, ensuring encrypted and authenticated communication between all workloads.

**File:** `peer-authentication.yaml`

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: STRICT
```

Apply it:
```bash
kubectl apply -f peer-authentication.yaml
```

🧠 **What happens:**  
All services in the `default` namespace will now only accept **encrypted** traffic using mutual TLS certificates.

---

## 🔎 6. Verify mTLS Is Active

Check connection security:

```bash
istioctl authn tls-check <pod-name> <destination-pod>.<namespace>.svc.cluster.local
```

Example:
```bash
istioctl authn tls-check reviews-v1-xxxxx ratings.default.svc.cluster.local
```

Output should show:  
`TLS Mode: ISTIO_MUTUAL ✅`

---

## 🧰 7. Traffic Control Example

Create a **DestinationRule** to enforce TLS mode:

**File:** `destinationrule-mtls.yaml`

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
```

Apply:
```bash
kubectl apply -f destinationrule-mtls.yaml
```

---

## 🧠 8. Observability in Service Mesh

Istio automatically provides:

- **Kiali** → Network visualization  
- **Jaeger** → Distributed tracing  
- **Prometheus** → Metrics collection  
- **Grafana** → Visualization  

Access Kiali dashboard:
```bash
istioctl dashboard kiali
```

---

## 🔒 9. NetworkPolicy vs Service Mesh (Comparison)

| Feature | NetworkPolicy | Service Mesh |
|----------|----------------|--------------|
| Layer | L3/L4 (IP, port) | L7 (application) |
| Encryption | ❌ Manual | ✅ Built-in mTLS |
| Traffic Control | ❌ Basic | ✅ Advanced routing |
| Observability | ❌ None | ✅ Built-in telemetry |
| Fault Injection | ❌ Not supported | ✅ Supported |
| Implementation | CNI plugin | Sidecar proxies |

---

## 🧾 Summary

| Concept | Description |
|----------|--------------|
| **Service Mesh** | Layer managing inter-service communication |
| **Sidecar Proxy** | Envoy instance that handles network traffic |
| **mTLS** | Mutual TLS — both sides authenticate each other |
| **Istio** | Popular open-source Service Mesh |
| **Kiali / Jaeger** | Tools for visualization and tracing |

---

## 🧱 Exercise

- Deploy any 2-service app (e.g., frontend & backend).  
- Enable strict mTLS with PeerAuthentication.  
- Use `istioctl authn tls-check` to confirm secure communication.  

---

## 🧩 References

- [Istio Official Docs](https://istio.io/latest/docs/)  
- [Kubernetes mTLS Concept](https://kubernetes.io/docs/concepts/security/overview/)  
- [Kiali Dashboard](https://kiali.io/)

---

**Next → Day 22:** Advanced Traffic Management — Canary & A/B Deployments 🚦
