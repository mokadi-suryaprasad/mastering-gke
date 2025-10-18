# 🔐 Day 19 — Secrets Management

Secure credentials with Kubernetes Secrets, GCP Secret Manager, and HashiCorp Vault

**Goal:** Learn simple, real examples to store and use secrets (passwords, API keys) securely with Kubernetes, Google Cloud Secret Manager, and HashiCorp Vault. Written in plain/basic English with commands and YAML you can copy.

---

## 📚 Overview (in simple words)

- **Secret** = any sensitive information (passwords, API keys, tokens).
- You should never put secrets in plain text in code or public repos.
- This guide shows three ways to store secrets and how to use them from apps running in Kubernetes.
  1. Kubernetes Secrets (good for small clusters or simple needs)
  2. Google Cloud Secret Manager (managed, secure, integrates with GCP)
  3. HashiCorp Vault (advanced: dynamic secrets, secret rotation, multi-cloud)

---

## ✅ Pre-requisites

- kubectl configured to talk to your Kubernetes cluster
- Access to a Google Cloud Project and `gcloud` installed (for GCP Secret Manager examples)
- Vault server (you can run dev mode locally for learning) and `vault` CLI installed
- Basic familiarity with Pods and Deployments

---

# Part A — Kubernetes Secrets (easy & local)

### 1) Create a secret from literal values

```bash
# create a generic secret named my-db-secret
kubectl create secret generic my-db-secret \
  --from-literal=username=dbuser \
  --from-literal=password='S3cr3tP@ssw0rd'

# verify
kubectl get secrets my-db-secret -o yaml
```

> Note: Kubernetes stores secrets base64-encoded, not encrypted by default. Consider enabling encryption at rest in your cluster.

### 2) Use the secret as environment variables in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-using-secret
spec:
  containers:
  - name: myapp
    image: busybox
    command: ["sh", "-c", "echo DB user=$DB_USER; echo DB pass=$DB_PASS; sleep 3600"]
    env:
      - name: DB_USER
        valueFrom:
          secretKeyRef:
            name: my-db-secret
            key: username
      - name: DB_PASS
        valueFrom:
          secretKeyRef:
            name: my-db-secret
            key: password
```

`kubectl apply -f pod.yaml` then `kubectl logs pod/app-using-secret` to see values printed (only for demo — don’t print secrets in production!).

### 3) Use secret as a mounted file

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-secret-volume
spec:
  containers:
  - name: myapp
    image: busybox
    command: ["sh", "-c", "cat /etc/secret/password; sleep 3600"]
    volumeMounts:
      - name: secret-vol
        mountPath: /etc/secret
        readOnly: true
  volumes:
    - name: secret-vol
      secret:
        secretName: my-db-secret
        items:
          - key: password
            path: password
```

### 4) Best practices for Kubernetes Secrets

- Enable **encryption at rest** for secret data in the cluster (KMS integration).
- Use **ServiceAccount** and RBAC to restrict who can read secrets.
- Avoid `kubectl describe` or logs that reveal secret values.
- Consider external secret stores (GCP Secret Manager or Vault) for stronger guarantees.

---

# Part B — Google Cloud Secret Manager (managed)

### 1) Create a secret in GCP (example)

```bash
# set project
gcloud config set project YOUR_GCP_PROJECT_ID

# create secret and add a version
echo -n "S3cr3tP@ssw0rd" | gcloud secrets create my-db-secret --data-file=-

# list secrets
gcloud secrets list

# access secret value (call from a safe shell)
gcloud secrets versions access latest --secret=my-db-secret
```

### 2) Allow a GKE workload to access secrets

1. Enable Workload Identity on your GKE cluster (recommended). This lets pods use a GCP service account without long-lived keys.
2. Grant the service account the `roles/secretmanager.secretAccessor` role for the secret.

Example commands (short form):

```bash
# create a GCP service account
gcloud iam service-accounts create k8s-secret-sa --project=YOUR_GCP_PROJECT_ID

# grant access to the secret
gcloud secrets add-iam-policy-binding my-db-secret \
  --member="serviceAccount:k8s-secret-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

3. Bind a Kubernetes ServiceAccount to the GCP service account (Workload Identity) and add annotation on K8s SA.

```bash
kubectl create serviceaccount app-sa
kubectl annotate serviceaccount app-sa iam.gke.io/gcp-service-account=k8s-secret-sa@YOUR_GCP_PROJECT_ID.iam.gserviceaccount.com
```

4. In the application Pod, use the Google Cloud client libraries to fetch the secret at runtime (do not bake the secret into the image). Example (pseudo-code):

```python
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
name = f"projects/{project_id}/secrets/my-db-secret/versions/latest"
response = client.access_secret_version(name=name)
secret_value = response.payload.data.decode('UTF-8')
```

This way the secret is fetched when the app starts or when needed.

### 3) Advantages of Secret Manager

- Managed by Google — secure storage and audit logs.
- IAM-based access control and fine-grained permissions.
- Versioning and easy rotation of secrets.
- Integrates cleanly with Workload Identity for GKE.

---

# Part C — HashiCorp Vault (advanced, powerful)

Vault supports dynamic secrets, leases, and automatic rotation. Good for production and multi-cloud.

### 1) Run Vault in dev mode (only for learning)

```bash
# run locally (dev mode - do NOT use in production)
vault server -dev

# set environment variable for the token
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='$(cat ~/.vault-token)'
```

### 2) Put a secret into Vault

```bash
vault kv put secret/myapp/db password='S3cr3tP@ssw0rd' username='dbuser'

# read it back
vault kv get secret/myapp/db
```

### 3) Kubernetes + Vault (example flow)

Two common ways:

- **Vault Agent Injector**: Vault mutating webhook injects secrets into pods as files or env vars.
- **Init container / sidecar**: App reads from a local file placed by a sidecar.

Basic steps to use Vault Agent Injector:

1. Deploy Vault with Kubernetes auth enabled.
2. Create a Kubernetes role mapping (Vault role) that trusts a K8s service account.
3. Annotate the Pod to request injection and which secret path to read.

Example Pod annotation snippet:

```yaml
metadata:
  annotations:
    vault.hashicorp.com/agent-inject: "true"
    vault.hashicorp.com/role: "demo-role"
    vault.hashicorp.com/agent-inject-secret-db: "secret/data/myapp/db"
```

When the Pod starts, the injector writes the secret to a file inside the container (e.g., `/vault/secrets/db`). Your app reads that file.

### 4) Dynamic secrets (example)

Vault can create short-lived database credentials on demand. For example, with the database secrets engine you configure Vault to talk to your database; Vault then creates a role which issues credentials with a TTL (time-to-live). Your app asks Vault for DB credentials; Vault returns a username/password valid for a short time. This is more secure than static passwords.

### 5) Vault best practices

- Use TLS and run Vault in HA for production.
- Use Kubernetes auth method with short-lived tokens.
- Audit logs must be enabled.
- Use Vault policies to limit which services can read which secrets.

---

# 🔁 Secret Rotation & Access Patterns

- Rotate secrets regularly (e.g., every 30/90 days) depending on sensitivity.
- For static secrets: store new version and update app to fetch new version on restart or hot reload.
- For dynamic secrets (Vault): configure short TTLs and code your app to refresh credentials when near expiry.

---

# 🔒 Security Checklist (simple)

- Do NOT commit secrets to Git.
- Use RBAC to restrict who can create/read secrets.
- Prefer managed secret stores (GCP Secret Manager) or secret engines (Vault) for production.
- Monitor and audit secret access.
- Use network policies and VPCs to limit where secrets can be accessed from.

---

# ✍️ Troubleshooting tips (basic)

- `kubectl get secrets` shows secret names but not values.
- `gcloud secrets versions access latest --secret=NAME` reads GCP secret if you have permission.
- Vault: check `vault status` and `vault audit` logs if reads fail.
- If a pod can't read a secret, check service account permissions and annotations (Workload Identity) or RBAC.

---

# Example mini-workflow (end-to-end)

1. Put DB password in GCP Secret Manager.
2. Create a K8s ServiceAccount annotated for Workload Identity.
3. Give the GCP service account `secretAccessor` on the secret.
4. App uses Google client library to read the secret at startup.

This removes secrets from k8s objects and centralizes audit/control in GCP.

---

## 🧾 References & next steps (for learning)

- Try the Vault Agent Injector demo from HashiCorp guides.
- Try GCP Workload Identity quickstart.
- Enable encryption at rest for Kubernetes Secret data in your cluster.

---

If you want, I can create downloadable files next (example: `k8s-secret.yaml`, `gcp-secret-steps.sh`, `vault-example.yaml`).

