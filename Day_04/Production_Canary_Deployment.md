# 🏭 Production-Grade Canary Deployment with Helm, ArgoCD, and GitOps

This guide explains **how to implement a safe, production-ready Canary Deployment** using **Helm, ArgoCD, and Git as the single source of truth**. All explanations are in **basic English** for easy understanding.

---

## 1️⃣ Git as Single Source of Truth

All **Helm charts**, **environment-specific values**, and **deployment configurations** are stored in Git.

**Repo structure example:**

```
gitops-repo/
├── charts/
│   └── shop-frontend/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
├── environments/
│   ├── dev/
│   │   └── values-dev.yaml
│   └── prod/
│       ├── values-prod.yaml
│       └── values-canary.yaml
└── README.md
```

---

## 2️⃣ Canary Deployment Example

### Helm Deployment YAML (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "shop-frontend.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "shop-frontend.name" . }}
      version: {{ .Values.version }}
  template:
    metadata:
      labels:
        app: {{ include "shop-frontend.name" . }}
        version: {{ .Values.version }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 80
```

**values-canary.yaml**

```yaml
replicaCount: 1
image:
  repository: shop-frontend
  tag: 1.1
version: canary
```

**values-prod.yaml**

```yaml
replicaCount: 3
image:
  repository: shop-frontend
  tag: 1.0
version: stable
```

> Canary pods have `version: canary` label; stable pods have `version: stable`.

---

## 3️⃣ Service & Traffic Split Example

**Service YAML (`service.yaml`)**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-frontend-service
spec:
  selector:
    app: shop-frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

**Traffic splitting** (optional, production-grade):

* Use **Ingress controller or service mesh (Istio/Linkerd)** to route 5–10% traffic to canary pods.
* Kubernetes alone cannot split traffic precisely; use labels + weighted routing.

---

## 4️⃣ ArgoCD Application Example (`application-canary.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: shop-frontend-canary
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main
    path: charts/shop-frontend
    helm:
      valueFiles:
        - ../../environments/prod/values-canary.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

* ArgoCD watches Git and **automatically deploys canary pods**.
* `prune: true` removes deleted resources.
* `selfHeal: true` keeps cluster in sync with Git.

---

## 5️⃣ Git-Based Rollback (Production Way)

**Step 1: Update Git**

* Revert canary changes or scale down canary:

```yaml
# environments/prod/values-canary.yaml
replicaCount: 0
```

**Step 2: Commit & Push**

```bash
git add environments/prod/values-canary.yaml
git commit -m "Rollback canary deployment to stable"
git push origin main
```

**Step 3: ArgoCD Sync**

* ArgoCD automatically applies rollback:

  * Canary pods removed
  * Stable pods continue running
* Verify with:

```bash
kubectl get pods -n prod -l app=shop-frontend
```

---

## 6️⃣ Monitoring & Health Checks

* Use **readiness** and **liveness probes** in deployment.
* Monitor canary using Prometheus/Grafana or ArgoCD health metrics.
* If canary fails, rollback immediately using Git.

---

## 7️⃣ Key Production Best Practices

1. Always deploy **canary first**; stable deployment stays live.
2. Never modify Kubernetes resources manually; always use Git.
3. Use **ArgoCD auto-sync & self-heal**.
4. Monitor metrics before promoting canary.
5. Gradually scale canary pods into full rollout.
6. Keep Git as the **source of truth** for rollback.

---
