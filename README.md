# ☸️ Mastering GKE — 23+ Days Hands-On Learning Series

![GKE](https://img.shields.io/badge/GKE-Kubernetes-blue?logo=google-cloud)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?logo=terraform)
![CI/CD](https://img.shields.io/badge/CI/CD-GitHub%20Actions-black?logo=githubactions)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-orange?logo=grafana)

A complete **hands-on learning journey** to master **Google Kubernetes Engine (GKE)** — from Kubernetes fundamentals to advanced production operations.
Each day covers a key concept with **labs**, **YAML manifests**, and **real GCP implementations**.

---

## 🧭 Introduction

This repository is designed for **DevOps Engineers**, **Cloud Architects**, and **Kubernetes enthusiasts** who want to:

* Deploy and manage production workloads on **Google Kubernetes Engine (GKE)**
* Automate infrastructure with **Terraform**
* Implement **GitOps** with **ArgoCD**
* Monitor, log, and secure clusters using **Prometheus, Grafana, EFK, Jaeger, and Cloud-native tools**
* Manage secrets securely using **Kubernetes Secrets, GCP Secret Manager, and HashiCorp Vault**

🎯 By the end of this series, you’ll be able to design, deploy, and operate **production-grade clusters on GCP** confidently.

---

## 📅 Learning Roadmap

| Day            | Topic                                    | Description                                                                 |
| -------------- | ---------------------------------------- | --------------------------------------------------------------------------- |
| 🧠 **Day 00**  | Why Container Orchestration              | Why Docker alone isn’t enough — need for orchestration                      |
| 🏗️ **Day 01** | Kubernetes Architecture                  | Control Plane, Node Components, Scheduler, Controller Manager               |
| ☁️ **Day 02**  | GKE Private Cluster                      | Secure private GKE with Terraform, VPC, Cloud NAT, IAM                      |
| 🧩 **Day 03**  | Pods                                     | Core execution unit — single & multi-container pods                         |
| ⚙️ **Day 04**  | Deployments                              | Rolling updates, rollbacks, and ReplicaSets                                 |
| 🌐 **Day 05**  | Services                                 | ClusterIP, NodePort, LoadBalancer explained                                 |
| 🧱 **Day 06**  | StatefulSets                             | Running stateful workloads using PVs/PVCs                                   |
| 🧩 **Day 07**  | DaemonSets                               | Cluster-wide agents (monitoring/logging)                                    |
| 🚪 **Day 08**  | Ingress                                  | Path-based routing, SSL termination                                         |
| ❤️ **Day 09**  | Health Probes                            | Liveness & Readiness probes                                                 |
| 📂 **Day 10**  | Namespaces                               | Logical separation of environments (dev, staging, prod)                     |
| 💾 **Day 11**  | Resource Quotas & Limits                 | Manage CPU/memory quotas for teams/projects                                 |
| 💾 **Day 12**  | Storage                                  | Persistent Volumes and PersistentVolumeClaims                               |
| 🗄️ **Day 13** | Cloud SQL Integration                    | Connect GKE Pods securely to Cloud SQL                                      |
| 📍 **Day 14**  | Node Affinity & NodeSelector             | Schedule Pods intelligently using node labels                               |
| 📊 **Day 15**  | Taints and Tolerations                   | Control Pod scheduling using node restrictions                              |
| 🧾 **Day 16**  | Pod Priority & Preemption                | How Kubernetes decides which Pods are more important when resources are low |
| 🔍 **Day 17**  | Autoscaling                              | Horizontal & Vertical Pod Autoscalers                                       |
| ⚡ **Day 18**   | GKE Cluster Autoscaler                   | Node-level scaling for cost & performance optimization                      |
| 🔐 **Day 19**  | Secrets Management                       | Kubernetes Secrets, GCP Secret Manager, HashiCorp Vault                     |
| 🧱 **Day 20**  | Network Policies                         | Restrict pod-to-pod communication                                           |
| 🚀 **Day 21**  | GitOps with ArgoCD                       | Continuous delivery for GKE workloads                                       |
| 🎯 **Day 22**  | Progressive Delivery with Argo Rollouts  | Canary & Blue/Green deployments with Argo Rollouts                          |
| 🛡️ **Day 23** | Continuous Security with Trivy & Kyverno | Image scanning and policy enforcement for secure deployments                |

---

## 🧰 Tech Stack

| Category                   | Tools / Technologies                                    |
| -------------------------- | ------------------------------------------------------- |
| **Cloud Platform**         | Google Cloud Platform (GCP)                             |
| **Orchestration**          | Kubernetes (GKE)                                        |
| **Infrastructure as Code** | Terraform                                               |
| **Containerization**       | Docker                                                  |
| **GitOps / CI-CD**         | ArgoCD, GitHub Actions                                  |
| **Monitoring**             | Prometheus, Grafana                                     |
| **Logging**                | EFK Stack (Elasticsearch, Fluentd, Kibana)              |
| **Tracing**                | Jaeger                                                  |
| **Security**               | Trivy, Kyverno, OPA, GCP IAM, Cloud Armor, Cloud IAP    |
| **Secrets Management**     | Kubernetes Secrets, GCP Secret Manager, HashiCorp Vault |

---

## 🧪 Hands-On Labs

Each day includes:

* ✅ Step-by-step implementation
* 📘 YAML manifests
* ☁️ GCP integration examples
* 🧩 Real-world DevOps use cases

---

## 👨‍💻 Author

**M Surya Prasad**
DevOps Engineer @ TCS | Cloud (GCP & AWS) | Kubernetes | Terraform | CI/CD | ArgoCD

🔗 [GitHub Profile](https://github.com/mokadi-suryaprasad)

---

## ⭐ Contribute

Fork this repo, explore, and raise PRs for improvements or new topics.
Let’s build the ultimate GKE learning resource together 🚀

---
