# Canary Deployments on GKE — Easy, Real‑World Guide

This guide shows how to do **canary deployments on Google Kubernetes Engine (GKE)** using the **Google Cloud external HTTP(S) Load Balancer** via the **GKE Ingress (GCE)** controller. We’ll ship a small % of traffic to a new version (the “canary”), watch it, then roll forward or roll back.

> Works on: **GKE Standard or Autopilot** with the **GCE Ingress** class (the default). No extra controllers required.

---

## What you’ll build (mental model)

```
Internet
   ↓
Google Cloud External HTTP(S) Load Balancer
   ↓
GKE Ingress (gce)
   ├─ Base Ingress  ──> Service v1 → Deployment v1  (stable)
   └─ Canary Ingress ─> Service v2 → Deployment v2  (new, 5–20% traffic)
```

We use **two Ingress objects** pointing at **two Services**. The **canary Ingress** has special annotations to receive a **weighted %** of traffic.

---

## Prerequisites

- A GKE cluster and `kubectl` configured
- A public DNS name (optional but recommended) — otherwise you can use the LB IP
- Kubernetes 1.19+ (typical for modern GKE)
- Default **Ingress class** is `gce` (or set it explicitly)

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <PROJECT_ID>
kubectl get nodes
```

---

## Step 1: Create the **stable** app (v1)

**Deployment (v1)**

```yaml
# app-v1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
      version: v1
  template:
    metadata:
      labels:
        app: hello
        version: v1
    spec:
      containers:
      - name: web
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080
```

**Service (v1)**

```yaml
# svc-v1.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-v1
spec:
  selector:
    app: hello
    version: v1
  ports:
  - port: 80
    targetPort: 8080
  type: NodePort
```

**Base Ingress (stable)**

```yaml
# ingress-base.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-base
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.allow-http: "true"
spec:
  rules:
  - host: <YOUR_DNS_NAME>   # or omit host to use LB IP
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-v1
            port:
              number: 80
```

Apply:

```bash
kubectl apply -f app-v1-deployment.yaml
kubectl apply -f svc-v1.yaml
kubectl apply -f ingress-base.yaml
```

Wait for IP:

```bash
kubectl get ingress hello-base
```

> Note the **ADDRESS**. If no DNS, test using that IP.

---

## Step 2: Create the **canary** (v2)

**Deployment (v2)**

```yaml
# app-v2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello
      version: v2
  template:
    metadata:
      labels:
        app: hello
        version: v2
    spec:
      containers:
      - name: web
        image: gcr.io/google-samples/hello-app:2.0
        ports:
        - containerPort: 8080
```

**Service (v2)**

```yaml
# svc-v2.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-v2
spec:
  selector:
    app: hello
    version: v2
  ports:
  - port: 80
    targetPort: 8080
  type: NodePort
```

**Canary Ingress**

Create a **second Ingress** with the **canary annotations**. This tells the GCE Ingress controller to split traffic by **weight**.

```yaml
# ingress-canary.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-canary
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.allow-http: "true"
    ingress.gcp.kubernetes.io/canary: "true"           # mark as canary
    ingress.gcp.kubernetes.io/canary-weight: "10"      # percentage of requests (0–100)
    # Optional alternative:
    # ingress.gcp.kubernetes.io/canary-by-header: "X-Canary"
    # ingress.gcp.kubernetes.io/canary-by-header-value: "yes"
spec:
  rules:
  - host: <YOUR_DNS_NAME>   # must match the base ingress host (or omit host on both)
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-v2
            port:
              number: 80
```

Apply:

```bash
kubectl apply -f app-v2-deployment.yaml
kubectl apply -f svc-v2.yaml
kubectl apply -f ingress-canary.yaml
```

> After a few minutes, ~**10%** of traffic flows to **v2**, **90%** stays on **v1**.

---

## Step 3: Test the split

**Curl loop** against your DNS or LB IP:

```bash
export HOST=<YOUR_DNS_NAME_OR_IP>
for i in {1..20}; do
  curl -s http://$HOST/ | grep -E "v1|v2" || true
done
```

- `hello-app:1.0` responses = v1
- `hello-app:2.0` responses = v2  
You should see roughly the ratio you set (`canary-weight: 10`).

### Optional: Header-based canary
If you used header annotations, you can force canary:

```bash
curl -H "X-Canary: yes" http://$HOST/
```

---

## Step 4: Gradually increase traffic

Update the **canary weight**:

```bash
kubectl annotate ingress hello-canary \
  ingress.gcp.kubernetes.io/canary-weight="25" --overwrite
```

Typical progression: **5% → 10% → 25% → 50% → 100%** (then decommission v1).

---

## Step 5: Roll forward or roll back

- **Healthy?** Increase weight until 100%, then delete base ingress (or point base to v2).
- **Issues?** Set weight to 0 or **delete canary ingress** to instantly stop canary traffic:

```bash
kubectl delete ingress hello-canary
# or
kubectl annotate ingress hello-canary ingress.gcp.kubernetes.io/canary-weight="0" --overwrite
```

---

## Observability tips

- Enable **Cloud Logging & Monitoring** for backend services
- Track **error rate**, **latency p95/p99**, and **CPU/memory**
- Use **SLOs** and set **alerting** before increasing weight

---

## Production checklist

- [ ] Health/readiness probes on both versions
- [ ] HPA/Autoscaling covers peak + canary ramp
- [ ] DB schema is **backward compatible**
- [ ] Config flags/feature toggles for easy rollback
- [ ] Header or cookie‑based routing for internal testing (QA/UAT)
- [ ] Automated canary analysis (optional: Kayenta/Flagger/Argo Rollouts)

---

## Common pitfalls & fixes

- **Different hosts** on base vs canary Ingress → **Must match** (or omit host on both).
- **NEG/IAP conflicts** → keep settings consistent across ingresses.
- **Weight seems off** → test with enough requests; LB is eventually consistent.
- **Session stickiness** → disable if you need true per‑request split.

---

## Clean up

```bash
kubectl delete -f ingress-canary.yaml
kubectl delete -f ingress-base.yaml
kubectl delete -f svc-v2.yaml -f app-v2-deployment.yaml
kubectl delete -f svc-v1.yaml -f app-v1-deployment.yaml
```

---

## FAQ (Very Short)

**Q: Do I need another controller (e.g., NGINX)?**  
A: No. The **GCE Ingress** supports canary with annotations.

**Q: Can I route canary by header/cookie instead of weight?**  
A: Yes, use `ingress.gcp.kubernetes.io/canary-by-header` (or cookie) annotations.

**Q: Can Autopilot do this?**  
A: Yes, same manifests; just ensure the Ingress class is `gce`.
