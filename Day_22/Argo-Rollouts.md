# 🎯 Day 22 — Progressive Delivery with Argo Rollouts (ArgoCD + GitOps)  

### Canary & Blue/Green Deployments 🚀

**Argo Rollouts** extends Kubernetes Deployments by enabling **progressive delivery strategies** such as:  
- **Canary Deployments** – gradually shift traffic to new versions  
- **Blue/Green Deployments** – deploy parallel environment before switching traffic  
- **Automated Rollbacks** – revert automatically if health checks fail  
- **Integration with Service Mesh** – supports Istio, NGINX, etc.

By combining **ArgoCD + Argo Rollouts**, you get a **GitOps workflow**: any change pushed to Git is automatically applied, and Argo Rollouts handles traffic management, monitoring, and rollbacks.

---

## 🎯 Learning Objectives
By the end of this session, you will:  
- Understand **progressive delivery** concepts  
- Install and configure **Argo Rollouts**  
- Implement **Canary** and **Blue/Green deployments**  
- Monitor and manage rollouts via **Argo Rollouts Dashboard & CLI**  
- Use **ArgoCD for GitOps automation**  
- Perform **safe rollbacks and promotions**  

---

## ⚙️ 1. Progressive Delivery Concept
Progressive Delivery is an evolution of Continuous Delivery that deploys changes **gradually**, monitors metrics, and ensures safe releases.

### Benefits:
- Safer releases  
- Real-time monitoring  
- Instant rollbacks  
- Supports experimentation and feature flags  

---

## 🧱 2. Install Argo Rollouts

```bash
# Create namespace
kubectl create namespace argo-rollouts

# Install CRDs and controller
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Verify
kubectl get pods -n argo-rollouts

# Install CLI (macOS example)
brew install argoproj/tap/kubectl-argo-rollouts
```

---

## 🧩 3. GitOps with ArgoCD

1. **Git = Source of Truth:** All manifests are stored in Git.  
2. **ArgoCD Sync:** Automatically applies manifests to the cluster.  
3. **Argo Rollouts:** Handles traffic splitting, metrics, and promotion.

### Repo Structure Example
```
microservices-demo/
├─ manifests/
│  ├─ canary-service.yaml
│  ├─ canary-rollout.yaml
│  ├─ bluegreen-services.yaml
│  └─ bluegreen-rollout.yaml
└─ argo-apps/
   └─ rollout-app.yaml
```

### ArgoCD Application YAML (`argo-apps/rollout-app.yaml`)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: progressive-rollouts
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/mokadi-suryaprasad/microservices-demo.git'
    targetRevision: main
    path: manifests
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🧩 4. Canary Deployment Example

**Service (`manifests/canary-service.yaml`):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: canary-demo
spec:
  selector:
    app: canary-demo
  ports:
  - port: 80
    targetPort: 8080
```

**Rollout (`manifests/canary-rollout.yaml`):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: canary-demo
spec:
  replicas: 4
  selector:
    matchLabels:
      app: canary-demo
  template:
    metadata:
      labels:
        app: canary-demo
    spec:
      containers:
      - name: canary-demo
        image: nginx:1.20
        ports:
        - containerPort: 8080
  strategy:
    canary:
      steps:
      - setWeight: 25
      - pause: { duration: 30s }
      - setWeight: 50
      - pause: { duration: 30s }
      - setWeight: 100
```

**Workflow:**
1. Push manifests to Git → ArgoCD syncs automatically.  
2. Argo Rollouts shifts traffic gradually.  
3. Monitor rollout:
```bash
kubectl argo rollouts get rollout canary-demo --watch
```

---

## 🌐 5. Blue/Green Deployment Example

**Services (`manifests/bluegreen-services.yaml`):**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: bluegreen-active
spec:
  selector:
    app: bluegreen-demo
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bluegreen-preview
spec:
  selector:
    app: bluegreen-demo
  ports:
  - port: 80
    targetPort: 8080
```

**Rollout (`manifests/bluegreen-rollout.yaml`):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: bluegreen-demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: bluegreen-demo
  template:
    metadata:
      labels:
        app: bluegreen-demo
    spec:
      containers:
      - name: bluegreen-demo
        image: nginx:1.21
        ports:
        - containerPort: 8080
  strategy:
    blueGreen:
      activeService: bluegreen-active
      previewService: bluegreen-preview
      autoPromotionEnabled: false
```

**Workflow:**
1. Push to Git → ArgoCD syncs.  
2. Preview deployed, active traffic remains on old version.  
3. Promote:
```bash
kubectl argo rollouts promote bluegreen-demo
```
4. Rollback if needed:
```bash
kubectl argo rollouts undo bluegreen-demo
```

---

## 🔄 6. Monitor Rollouts

- Dashboard:
```bash
kubectl argo rollouts dashboard
```

- CLI Commands:

| Action | Command |
|--------|---------|
| List rollouts | `kubectl argo rollouts list rollouts` |
| Watch rollout | `kubectl argo rollouts get rollout <name> --watch` |
| Promote rollout | `kubectl argo rollouts promote <name>` |
| Undo rollout | `kubectl argo rollouts undo <name>` |
| Open dashboard | `kubectl argo rollouts dashboard` |

---

## 🧠 Key Takeaways
- GitOps workflow with **ArgoCD + Rollouts** ensures safe deployments.  
- **Canary** → gradual traffic shift.  
- **Blue/Green** → parallel environments and instant promotion.  
- Supports metrics-based monitoring and automated rollback.  
- Integrates seamlessly with ArgoCD and Service Meshes.  

---

**Next → Day 23:** Continuous Security — Image Scanning and Policy Enforcement with Trivy & Kyverno 🛡️
