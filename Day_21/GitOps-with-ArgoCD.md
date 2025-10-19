# 🚀 Day 21 — GitOps with ArgoCD
### Continuous Delivery for GKE Workloads ☸️

GitOps is a modern approach to **Continuous Delivery (CD)** where **Git** acts as the *single source of truth* for both application and infrastructure definitions.  
With **ArgoCD**, any change you push to Git automatically syncs with your Kubernetes cluster — ensuring consistency, reliability, and faster deployments.

---

## 🎯 Learning Objectives
By the end of this session, you will:
- Understand **GitOps principles**  
- Set up **ArgoCD** on **Google Kubernetes Engine (GKE)**  
- Deploy workloads from Git automatically  
- Manage **syncs**, **rollbacks**, and **health checks** using ArgoCD UI and CLI  

---

## ⚙️ 1. What is ArgoCD?
**ArgoCD** is a declarative, GitOps continuous delivery tool for Kubernetes.  
It continuously monitors Git repositories and applies the desired state to Kubernetes clusters.

### 🔑 Key Features
- Declarative GitOps model  
- Automatic or manual sync from Git to cluster  
- Rollbacks and history tracking  
- Web UI, CLI, and REST API  
- Integration with Helm, Kustomize, and plain YAML  

---

## 🧱 2. Prerequisites
Before starting, ensure you have:
- A running **GKE cluster**
- `kubectl` and `gcloud` configured
- GitHub repo with your **Kubernetes manifests** (e.g., `deployments/`, `services/` folders)

---

## 🧰 3. Install ArgoCD on GKE

### Step 1: Create Namespace
```bash
kubectl create namespace argocd
```

### Step 2: Install ArgoCD
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Step 3: Verify Pods
```bash
kubectl get pods -n argocd
```

### Step 4: Expose ArgoCD Server (LoadBalancer)
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n argocd
```

Note the **EXTERNAL-IP** — this is your ArgoCD dashboard URL.

---

## 🔐 4. Login to ArgoCD

### Get Initial Admin Password
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### Access UI
Open: `https://<EXTERNAL-IP>`  
Username: `admin`  
Password: `<from command above>`

---

## 📦 5. Create an Application in ArgoCD

You can create the ArgoCD application either through **UI** or **YAML**.

### Example Application YAML
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gke-sample-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/mokadi-suryaprasad/GCP-DevOps-CICD-Pipeline.git'
    targetRevision: main
    path: manifests/
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### Apply the App
```bash
kubectl apply -f app-gke.yaml
```

✅ ArgoCD will automatically deploy the workloads defined in your Git repo to GKE.

---

## 🔄 6. GitOps Workflow (Auto Sync)

1. Developer updates manifest (e.g., image tag) in GitHub.  
2. ArgoCD detects the commit difference.  
3. It automatically syncs and deploys changes to the cluster.  
4. The ArgoCD dashboard reflects the latest deployed state.

---

## 🧩 7. Rollback and Sync Control

- **Manual Sync:** Click *Sync* in UI or run:
  ```bash
  argocd app sync gke-sample-app
  ```
- **Rollback:** Choose a previous revision and click *Rollback* in UI.

---

## 🧠 Key Takeaways
- **Git is your source of truth.**
- ArgoCD ensures **declarative, consistent, and automated** deployments.  
- Sync policies can be **manual or automatic**.  
- Use **Argo Rollouts** for advanced progressive delivery (future topic!).

---

## 🧰 Common Commands
| Action | Command |
|--------|----------|
| Get ArgoCD applications | `kubectl get applications -n argocd` |
| Login via CLI | `argocd login <EXTERNAL-IP>` |
| Sync an app | `argocd app sync <app-name>` |
| Check app status | `argocd app get <app-name>` |

---

**Next → Day 22:** Progressive Delivery with Argo Rollouts — Canary & Blue/Green Deployments 🎯
