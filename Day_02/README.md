# ☸️ Google Kubernetes Engine (GKE)

## 🧠 What is Google Kubernetes Engine?

**Google Kubernetes Engine (GKE)** is a service in **Google Cloud Platform (GCP)** that helps you run **containers** using **Kubernetes** easily.  
It is a **managed service**, which means Google takes care of most of the setup and maintenance work.

Google handles:
- Creating and managing clusters  
- Scaling applications automatically  
- Updating and fixing servers  
- Monitoring and security  

You only need to focus on your **applications**, not the servers.

---

## ⚙️ Why Use GKE?

- You can **run containers** easily in the cloud.  
- It can **automatically scale** your app when traffic increases.  
- It has **built-in security** using Google IAM and VPC.  
- It connects smoothly with other **Google Cloud services**.  
- It includes **Cloud Monitoring** for logs and metrics.  

---

## 🏗️ Types of Clusters in GKE

GKE has **two main types of clusters**:

### 1. Standard Cluster
- You manage the **nodes (VMs)** and choose their size and settings.  
- Gives you **more control** over the cluster.  
- Mostly used for **production environments**.  
- You pay for both the **VMs** and the **control plane**.

**Example:**  
If you want full control over your setup — like choosing node size, upgrades, and network settings — use a **Standard Cluster**.

---

### 2. Autopilot Cluster
- Google manages **everything**, including nodes and control plane.  
- You only deploy your **pods**, and GKE handles everything else.  
- Best for **developers** who don’t want to manage infrastructure.  
- You pay only for the **pods** you use, not the full VMs.

**Example:**  
If you want an easy setup for testing or small projects — use an **Autopilot Cluster**.

---

## 🌐 Public vs Private Clusters in GKE

You can create either a **Public Cluster** or a **Private Cluster** in GKE.

---

### 🔓 Public Cluster
- The **control plane** has a **public IP address**.  
- The **nodes** can also have **public IPs**.  
- You can **access the cluster** from the internet using permissions.  
- Easier to set up — good for **testing or learning**.

**Example:**  
If you want to connect from your laptop using `kubectl`, use a **Public Cluster**.

**Key Points:**
- Easy to access  
- Less secure  
- Best for **development or testing**

---

### 🔒 Private Cluster
- The **control plane** and **nodes** use **private IPs only**.  
- No access from the public internet.  
- You can connect only from **authorized networks** or **VPN**.  
- Offers **high security** — best for production apps.

**Example:**  
If you are deploying a banking or secure app, use a **Private Cluster**.

**Key Points:**
- High security  
- Access limited to VPC  
- Best for **production environments**

---

## 🧩 Summary: Public vs Private

| Feature | Public Cluster | Private Cluster |
|----------|----------------|-----------------|
| Control Plane Access | Public IP | Private IP |
| Node Access | Can have public IPs | Only private IPs |
| Security | Medium | High |
| Setup | Easy | More secure setup |
| Best For | Dev/Test | Production |

---

## 🌐 Primary and Secondary IP Ranges in GKE

When you create a **VPC-native GKE cluster**, GKE uses **IP ranges** from your VPC network for **Pods** and **Services**.  
These ranges are called **Primary** and **Secondary IP ranges**.

---

### 🩵 Primary IP Range
- The **Primary IP range** is used for **Nodes (VMs)** in your cluster.  
- Each node gets an IP address from this range.  
- It belongs to your **VPC subnet**.

**Example:**
If your subnet is `10.0.0.0/16`, nodes might get:


**Used For:**  
Node (VM) communication — connecting to other GCP services or the internet.

---

### 💙 Secondary IP Range
The **Secondary IP range** is used for **Pods** and **Services** inside Kubernetes.

There are two types:
1. **Pod IP Range** — for Pods  
2. **Service IP Range** — for Services (like ClusterIP, LoadBalancer, etc.)

You must define both when creating a **VPC-native cluster**.

**Example:**
- **Pods Range:** `10.4.0.0/14`  
- **Services Range:** `10.8.0.0/20`

So, Pods get IPs from `10.4.0.0/14`  
and Services get IPs from `10.8.0.0/20`.

---

### 🧩 Why Use These IP Ranges?

| Purpose | IP Range | Used For |
|----------|-----------|----------|
| Primary Range | Subnet range | Node (VM) IPs |
| Secondary Range 1 | Example: `10.4.0.0/14` | Pod IPs |
| Secondary Range 2 | Example: `10.8.0.0/20` | Service IPs |

This prevents **IP conflicts** between:
- Nodes  
- Pods  
- Services  

---

### 💡 Example Setup

| Type | Example Range | Description |
|------|----------------|-------------|
| Subnet (Primary Range) | `10.0.0.0/16` | For Nodes |
| Pods Secondary Range | `10.4.0.0/14` | For Pods |
| Services Secondary Range | `10.8.0.0/20` | For Services |

---

### 🔐 Benefits

- No IP overlap between Nodes, Pods, and Services.  
- Easier to manage networking in the VPC.  
- Better visibility and control.  
- Supports **Alias IPs** for faster routing.

---

### 🧠 Summary

- **Primary Range** → For **Nodes (VMs)**  
- **Secondary Range** → For **Pods and Services**  
- Used in **VPC-native clusters**  
- Helps prevent IP conflicts and improves cluster networking

---