# ☁️ Workload Identity in GKE — Step-by-Step Guide

This guide explains how to securely grant a **GKE Pod** access to **Google Cloud resources** (like Compute Engine and Cloud DNS) using **Workload Identity** — without storing any JSON key files.

---

## 🧭 Step-01: Introduction

We will perform the following steps:

1. Create a **GCP IAM Service Account**
2. Add IAM Roles to GCP IAM Service Account (`add-iam-policy-binding`)
3. Create a **Kubernetes Namespace**
4. Create a **Kubernetes Service Account**
5. Associate **GCP IAM Service Account** with **Kubernetes Service Account**
6. Annotate **Kubernetes Service Account** with GCP IAM SA email address
7. Create sample Pods (with and without Service Account)
8. Verify **Workload Identity functionality** in the GKE cluster

---

## 🔍 Step-02: Verify Workload Identity Enabled on GKE Cluster

Go to:
> **Kubernetes Engine → Clusters → surya-gke-cluster → DETAILS**

Check under **Security → Workload Identity**  
✅ It should be in **Enabled** state.

---

## 🏗️ Step-03: Create GCP IAM Service Account

```bash
# List IAM Service Accounts
gcloud iam service-accounts list

# List Google Cloud Projects
gcloud projects list

# Create IAM Service Account
gcloud iam service-accounts create wid-gcpiam-sa --project=gcp-zero-to-hero-467513

# Verify
gcloud iam service-accounts list
```

---

## 🔐 Step-04: Add IAM Roles to GCP IAM Service Account

We will start by giving the service account **Compute Viewer** access, so it can list Compute Engine instances from inside a Pod.

```bash
gcloud projects add-iam-policy-binding gcp-zero-to-hero-467513   --member="serviceAccount:wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com"   --role="roles/compute.viewer"   --condition=None
```

---

## 🧩 Step-05: Create Kubernetes Namespace and Service Account

```bash
# Create Namespace
kubectl create namespace wid-kns

# Create Service Account inside the Namespace
kubectl create serviceaccount wid-ksa --namespace wid-kns
```

---

## 🔗 Step-06: Associate GCP IAM Service Account with Kubernetes Service Account

This step allows the **Kubernetes Service Account** to impersonate the **GCP Service Account** using Workload Identity.

```bash
gcloud iam service-accounts add-iam-policy-binding   wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com   --role roles/iam.workloadIdentityUser   --member "serviceAccount:gcp-zero-to-hero-467513.svc.id.goog[wid-kns/wid-ksa]"
```

---

## 🏷️ Step-07: Annotate Kubernetes Service Account

Annotate the Kubernetes Service Account with the **GCP Service Account email**.

```bash
kubectl annotate serviceaccount wid-ksa   --namespace wid-kns   iam.gke.io/gcp-service-account=wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com

# Verify Annotation
kubectl describe sa wid-ksa -n wid-kns
```

---

## 🧱 Step-08: Pod Without Service Account

File: `01-wid-demo-pod-without-sa.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wid-demo-without-sa
  namespace: wid-kns
spec:
  containers:
  - image: google/cloud-sdk:slim
    name: wid-demo-without-sa
    command: ["sleep", "infinity"]
  nodeSelector:
    iam.gke.io/gke-metadata-server-enabled: "true"
```

---

## 🧱 Step-09: Pod With Service Account

File: `02-wid-demo-pod-with-sa.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wid-demo-with-sa
  namespace: wid-kns
spec:
  containers:
  - image: google/cloud-sdk:slim
    name: wid-demo-with-sa
    command: ["sleep", "infinity"]
  serviceAccountName: wid-ksa
  nodeSelector:
    iam.gke.io/gke-metadata-server-enabled: "true"
```

---

## 🚀 Step-10: Deploy Kubernetes Manifests

```bash
kubectl apply -f kube-manifests/
kubectl -n wid-kns get pods
```

---

## ❌ Step-11: Test Pod Without Service Account

```bash
kubectl -n wid-kns exec -it wid-demo-without-sa -- /bin/bash
gcloud auth list
gcloud compute instances list
exit
```

---

## ✅ Step-12: Test Pod With Service Account

```bash
kubectl -n wid-kns exec -it wid-demo-with-sa -- /bin/bash
gcloud auth list
gcloud compute instances list
exit
```

---

## ⚠️ Step-13: Negative Test — Cloud DNS (Before Permission)

```bash
kubectl -n wid-kns exec -it wid-demo-with-sa -- /bin/bash
gcloud dns record-sets list 
exit
```

---

## 🔧 Step-14: Grant Cloud DNS Admin Role

```bash
gcloud projects add-iam-policy-binding gcp-zero-to-hero-467513   --member="serviceAccount:wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com"   --role="roles/dns.admin"   --condition=None
```

---

## ✅ Step-15: Verify DNS Access After Role Grant

```bash
kubectl -n wid-kns exec -it wid-demo-with-sa -- /bin/bash
gcloud dns record-sets list 
gcloud compute instances list
exit
```

---

## 🧹 Step-16: Clean Up Kubernetes Resources

```bash
kubectl delete -f kube-manifests/
kubectl delete ns wid-kns
```

---

## 🧽 Step-17: Clean Up GCP IAM Resources

```bash
gcloud projects remove-iam-policy-binding gcp-zero-to-hero-467513   --member="serviceAccount:wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com"   --role="roles/compute.viewer"

gcloud projects remove-iam-policy-binding gcp-zero-to-hero-467513   --member="serviceAccount:wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com"   --role="roles/dns.admin"

gcloud iam service-accounts delete   wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com --project=gcp-zero-to-hero-467513
```

---

## 📚 References
- [GKE — Using Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GCP IAM Roles for Cloud DNS](https://cloud.google.com/iam/docs/understanding-roles#dns-roles)
- [IAM Policy Binding Commands](https://cloud.google.com/sdk/gcloud/reference/projects/add-iam-policy-binding)

---

✅ **Summary:**
You successfully:
- Enabled Workload Identity on your GKE cluster  
- Linked GCP SA → K8s SA securely  
- Verified Compute & Cloud DNS access from inside a Pod  
- Followed least-privilege IAM practices  

---
**Author:** *M Surya Prasad*  
**Project:** `gcp-zero-to-hero-467513`  
**Namespace:** `wid-kns`  
**Service Account:** `wid-ksa`  
**GCP IAM SA:** `wid-gcpiam-sa@gcp-zero-to-hero-467513.iam.gserviceaccount.com`  
**Cluster:** `surya-gke-cluster`
