# 🏗️ Day 01 — Kubernetes Architecture

## 🧠 What is Kubernetes?

Kubernetes (K8s) is a **container orchestration tool**.  
It helps you **deploy, scale, and manage** containerized applications automatically.

It has two main parts:

- **Control Plane** 🧩 — Brain of the cluster (manages everything)
- **Nodes (Workers)** ⚙️ — Machines where applications actually run

---

## 🏗️ Kubernetes Architecture Diagram

```plaintext
                 +------------------------------------------------+
                 |                Control Plane                   |
                 |------------------------------------------------|
                 | API Server | Scheduler | Controller Manager    |
                 | Cloud Controller Manager | etcd (Database)     |
                 +------------------------------------------------+
                                 |
                                 |
                   -------------------------------------
                   |                                   |
         +-------------------+              +-------------------+
         |     Worker Node   |              |     Worker Node   |
         |-------------------|              |-------------------|
         | Kubelet | Kube-Proxy | Container Runtime |
         |   (Pod Management)   |   (Networking)    |
         +-------------------+              +-------------------+
```

---

## 🧩 Control Plane Components

| Component | Description |
|------------|-------------|
| **API Server** | Acts as the **front door** for Kubernetes. All commands from `kubectl` go here. |
| **etcd** | A **key-value database** that stores cluster data like pods, nodes, and configs. |
| **Scheduler** | Decides **which node** will run a new pod. |
| **Controller Manager** | Keeps an eye on the cluster and **maintains the desired state** (e.g., restarting crashed pods). |
| **Cloud Controller Manager** | Connects Kubernetes with **cloud provider APIs** (like AWS, GCP, Azure). It manages cloud-specific tasks such as: <br> → Creating Load Balancers <br> → Attaching Storage Volumes <br> → Managing Node lifecycle in the cloud. |

---

## ⚙️ Node Components

| Component | Description |
|------------|-------------|
| **Kubelet** | Talks to the Control Plane and **runs pods** on the node. |
| **Kube-Proxy** | Manages **network rules** to allow communication between pods and services. |
| **Container Runtime** | The engine that actually **runs containers** (like Docker or containerd). |

---

## 💡 Example Flow

1. You run `kubectl apply -f app.yaml`.  
2. The **API Server** receives the request.  
3. The **Scheduler** picks the best worker node.  
4. The **Kubelet** on that node runs the container.  
5. The **Controller Manager** ensures everything stays healthy.  
6. The **Cloud Controller Manager** talks to the cloud provider (if using one) to create necessary resources like load balancers or volumes.

---

## 🏁 Summary

- **Control Plane** = Brain  
- **Nodes** = Workers  
- **API Server** = Entry point  
- **Scheduler** = Decides placement  
- **Controller Manager** = Maintains state  
- **Cloud Controller Manager** = Manages cloud integrations  
- **Kubelet & Kube-Proxy** = Run and connect pods  

Kubernetes makes managing containers **easy, automated, and scalable**! ☁️🚀
