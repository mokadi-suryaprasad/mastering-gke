# Kubernetes Troubleshooting: ImagePullBackOff — Simple Step-by-Step (GKE)

This is a **clear, no-confusion step-by-step** guide for two ways to use **private images** with **GKE**:

* **Way A — DockerHub** (use when your image is hosted on DockerHub)
* **Way B — Google Artifact Registry** (use when your image is in GAR)

---

## Before you start (prerequisites)

1. `gcloud` and `kubectl` installed and configured for your GCP project and GKE cluster.
2. You are connected to your cluster: `gcloud container clusters get-credentials <CLUSTER> --zone <ZONE> --project <PROJECT_ID>`
3. You have the image names and credentials ready.

---

# WAY A — DockerHub (Simple 6 steps)

1. **Login locally to DockerHub (optional but useful)**

   ```bash
   docker login
   # enter DockerHub username and password (or token)
   ```

2. **Create a Kubernetes secret with DockerHub credentials**

   ```bash
   kubectl create secret docker-registry dockerhub-secret \
     --docker-username=DOCKERHUB_USERNAME \
     --docker-password=DOCKERHUB_PASSWORD_OR_TOKEN \
     --docker-email=YOUR_EMAIL \
     --docker-server=https://index.docker.io/v1/
   ```

   * Replace placeholders with your values.

3. **Write a minimal Deployment YAML using the private image** (save as `deployment-dockerhub.yaml`)

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: myapp-dockerhub
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: myapp-dockerhub
     template:
       metadata:
         labels:
           app: myapp-dockerhub
       spec:
         containers:
           - name: myapp
             image: docker.io/DOCKERHUB_USERNAME/IMAGE_NAME:TAG
             ports:
               - containerPort: 80
         imagePullSecrets:
           - name: dockerhub-secret
   ```

   * Important: Use the exact `docker.io/USERNAME/IMAGE:TAG` path.

4. **Apply the Deployment**

   ```bash
   kubectl apply -f deployment-dockerhub.yaml
   ```

5. **Check pod status and describe if errors**

   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>      # if container started and then crashed
   ```

6. **If you see ImagePullBackOff**

   * `kubectl describe pod` → look under **Events** for detailed error (wrong credentials, not found, unauthorized).
   * Recreate secret if credentials were wrong.

---

# WAY B — Google Artifact Registry (Simple 7 steps)

**Note:** Artifact Registry images look like: `us-central1-docker.pkg.dev/PROJECT_ID/REPO_NAME/IMAGE:TAG`

1. **Enable Artifact Registry API (one-time)**

   ```bash
   gcloud services enable artifactregistry.googleapis.com --project=<PROJECT_ID>
   ```

2. **Authenticate gcloud and connect to cluster** (if not already)

   ```bash
   gcloud auth login
   gcloud container clusters get-credentials <CLUSTER> --zone <ZONE> --project <PROJECT_ID>
   ```

3. **Create a Kubernetes secret using your access token**

   ```bash
   kubectl create secret docker-registry gar-secret \
     --docker-server=us-central1-docker.pkg.dev \
     --docker-username=oauth2accesstoken \
     --docker-password="$(gcloud auth print-access-token)" \
     --docker-email=YOUR_EMAIL
   ```

   * Replace `us-central1` with the region of your Artifact Registry.

4. **(Optional but recommended) Create a Google service account with reader role**

   ```bash
   gcloud iam service-accounts create gke-pull-sa --project=<PROJECT_ID>

   gcloud projects add-iam-policy-binding <PROJECT_ID> \
     --member="serviceAccount:gke-pull-sa@<PROJECT_ID>.iam.gserviceaccount.com" \
     --role="roles/artifactregistry.reader"
   ```

   * This ensures GCP IAM allows image reads.

5. **Write Deployment YAML pointing to Artifact Registry** (save as `deployment-gar.yaml`)

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: myapp-gar
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: myapp-gar
     template:
       metadata:
         labels:
           app: myapp-gar
       spec:
         containers:
           - name: myapp
             image: us-central1-docker.pkg.dev/PROJECT_ID/REPO_NAME/IMAGE:TAG
             ports:
               - containerPort: 80
         imagePullSecrets:
           - name: gar-secret
   ```

6. **Apply the Deployment**

   ```bash
   kubectl apply -f deployment-gar.yaml
   ```

7. **Check pod status and troubleshoot**

   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   ```

   * If `ImagePullBackOff`, `describe` → **Events** will say `unauthorized` (bad credentials) or `not found` (wrong path).

---

## Quick Troubleshooting Checklist (both ways)

* Did you use the exact image path and tag?
* Is the `imagePullSecrets` name spelled correctly in YAML?
* `kubectl get secret` — does your secret exist in the same namespace?
* `kubectl describe pod <pod>` → read Events for the precise error.
* For GAR: ensure Artifact Registry API is enabled and the service account has `artifactregistry.reader`.

---

# ✅ WAY C — Production Method (Workload Identity + Artifact Registry)

This is the **recommended production approach** for GKE because:

* ✅ No need to store Docker passwords in Kubernetes
* ✅ No secrets for image pulling
* ✅ Secure, IAM‑based authentication
* ✅ Automatic token rotation by Google

Follow these simple steps:

---

## ✅ Step 1: Enable Workload Identity on the cluster

Check if your cluster already has it:

```bash
gcloud container clusters describe <CLUSTER> --zone <ZONE> --project <PROJECT_ID> | grep workloadIdentity
```

If not enabled, recreate/update the cluster with Workload Identity:

```bash
gcloud container clusters update <CLUSTER> \
  --workload-pool=<PROJECT_ID>.svc.id.goog \
  --zone <ZONE> --project <PROJECT_ID>
```

---

## ✅ Step 2: Create Google Service Account (GSA)

```bash
gcloud iam service-accounts create gar-reader-sa --project=<PROJECT_ID>
```

Grant Artifact Registry read permissions:

```bash
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:gar-reader-sa@<PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

---

## ✅ Step 3: Create Kubernetes Service Account (KSA)

```bash
kubectl create serviceaccount ksa-gar-reader -n default
```

---

## ✅ Step 4: Bind the Kubernetes SA ↔ Google SA

This step links them using Workload Identity.

```bash
gcloud iam service-accounts add-iam-policy-binding \
  gar-reader-sa@<PROJECT_ID>.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:<PROJECT_ID>.svc.id.goog[default/ksa-gar-reader]" \
  --project <PROJECT_ID>
```

Annotate KSA:

```bash
kubectl annotate serviceaccount \
  ksa-gar-reader \
  iam.gke.io/gcp-service-account=gar-reader-sa@<PROJECT_ID>.iam.gserviceaccount.com \
  -n default
```

---

## ✅ Step 5: Use the KSA in your Deployment (No secrets required!)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp-prod
  template:
    metadata:
      labels:
        app: myapp-prod
    spec:
      serviceAccountName: ksa-gar-reader
      containers:
        - name: myapp
          image: us-central1-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG
          ports:
            - containerPort: 80
```

✅ **You do NOT add imagePullSecrets in production Workload Identity method!**

---

## ✅ Final Verification

```bash
kubectl apply -f deployment.yaml
kubectl get pods
kubectl describe pod <pod-name>
```

If everything is configured properly, GKE will pull images **securely using IAM**, not secrets.

---

# ✅ Why Workload Identity is Production Best Practice

| Feature               | DockerHub | GAR Secret | Workload Identity (Best) |
| --------------------- | --------- | ---------- | ------------------------ |
| Uses passwords        | ✅ Yes     | ✅ Yes      | ❌ No                     |
| Uses IAM roles        | ❌ No      | ✅ Yes      | ✅ Yes                    |
| Needs secret rotation | ✅ Yes     | ✅ Yes      | ❌ No                     |
| Secure for production | ❌ No      | ✅ Good     | ✅✅ Best                  |
| Recommended by Google | ❌ No      | ✅ Partial  | ✅✅ Yes                   |

---

