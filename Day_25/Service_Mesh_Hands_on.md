# Service Mesh Hands-On Guide

This document contains practical hands-on examples for:
✅ JWT + Gateway Level Enforcement
✅ Production-Grade Rate Limiting (External Ratelimit Service)
✅ Step-by-step Multi-Cluster Istio Setup (Primary–Remote)
✅ Zero Trust & Multi-Cluster Architecture Diagrams

---

# ✅ 1. JWT Authentication at Istio Ingress Gateway (Hands-On)

## **Step 1: Create RequestAuthentication (Validate JWT at Gateway)**

```yaml
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: ingress-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "https://example.com/"
    jwksUri: "https://example.com/.well-known/jwks.json"
```

## **Step 2: Create AuthorizationPolicy to Allow Only Valid JWTs**

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ingress-jwt-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
```

✅ Only requests with valid JWT tokens will pass through the Ingress Gateway.

---

# ✅ 2. Production-Grade Global Rate Limiting (Envoy External RateLimit Service)

## **Architecture Overview**

```
Client → Ingress Gateway → Envoy Filter → RateLimit Service → Destination
```

## **Step 1: Deploy Lyft Envoy Ratelimit Service**

```bash
git clone https://github.com/lyft/ratelimit
kubectl apply -f ratelimit/kubernetes/
```

## **Step 2: Create EnvoyFilter to Enable Global Rate Limiting**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ext-rate-limit
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      istio: ingressgateway
  configPatches:
  - applyTo: HTTP_FILTER
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.ratelimit
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
          domain: productpage
          rate_limit_service:
            grpc_service:
              envoy_grpc:
                cluster_name: rate_limit_cluster
              timeout: 0.25s
```

## **Step 3: Add Cluster Config for External RateLimit Service**

```yaml
  - applyTo: CLUSTER
    patch:
      operation: ADD
      value:
        name: rate_limit_cluster
        type: STRICT_DNS
        connect_timeout: 0.25s
        lb_policy: ROUND_ROBIN
        load_assignment:
          cluster_name: rate_limit_cluster
          endpoints:
          - lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: ratelimit
                    port_value: 8081
```

✅ This deploys **global**, **shared**, **production-grade** rate limiting.

---

# ✅ 3. Multi-Cluster Istio Setup (Primary–Remote)

## **Architecture**

```
Cluster A (Primary) → runs istiod + east-west gateway  
Cluster B (Remote)  → connects to primary control plane  
```

## **Step 1: Install Istio on Primary Cluster**

```bash
istioctl install --set profile=default \
  --set values.global.multiCluster.clusterName=primary \
  --set values.global.network=network1 -y
```

## **Step 2: Export Primary’s API Server to Remote Cluster**

```bash
kubectl apply -f samples/multicluster/expose-primary.yaml
```

## **Step 3: Install Istio on Remote Cluster (NO istiod)**

```bash
istioctl install --set profile=remote \
  --set values.global.multiCluster.clusterName=remote1 \
  --set values.global.network=network1 -y
```

## **Step 4: Connect Remote to Primary (Generate Secrets)**

### On Primary:

```bash
istioctl x create-remote-secret \
  --name remote1 > remote1-secret.yaml
```

### Apply on Remote:

```bash
kubectl apply -f remote1-secret.yaml
```

✅ Remote cluster is now registered to Primary’s control plane.

## **Step 5: Deploy Sample App Across Clusters**

Cluster A:

```bash
kubectl apply -f samples/helloworld/helloworld.yaml
```

Cluster B:

```bash
kubectl apply -f samples/helloworld/helloworld-v2.yaml
```

✅ Both services discover each other across clusters.

---

# ✅ 4. Diagrams for Zero Trust & Multi-Cluster Mesh

## **Zero Trust Flow in Istio**

```
User → Gateway → (JWT Verification)  
        → Sidecar A → mTLS → Sidecar B → Service B  

Policies enforced:  
✔ JWT Validation  
✔ Mutual TLS  
✔ Least Privilege (AuthorizationPolicy)  
✔ Deny-By-Default  
```

## **Multi-Cluster Networking Flow**

```
          +-------------------+       +------------------+
          |   Cluster A       |       |    Cluster B     |
          | (Primary Istiod)  |       |   (Remote)       |
          +---------+---------+       +---------+--------+
                    |                         |
            East-West Gateway         East-West Gateway
                    |                         |
                    +-------- mTLS Tunnel ----+
                    |                         |
           Services discover across clusters via Primary Control Plane
```

---

If you want, I can add next:
✅ End-to-End Hands-On Canary Deployment
✅ Traffic Shifting with Ingress Gateway
✅ Security Policy Cookbook (60+ examples)
✅ Deployment Scenarios for Production Istio

Just tell me! 🚀
