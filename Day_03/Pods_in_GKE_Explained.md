# 🧩 Day 03 — Pods in Kubernetes (GKE)

## 📘 What is a Pod?

A **Pod** is the **smallest and simplest unit in Kubernetes**.  
It represents **one running instance of your application** — just like a wrapper around one or more containers.

- A **Pod** can run:
  - **Single container** (most common)
  - **Multiple containers** that work together (for example, one main app container and one helper container for logging or monitoring)

Each Pod:
- Has its own **unique IP address** inside the cluster.
- Shares **storage volumes** and **network** among its containers.
- Is **temporary** — it can die, restart, or be replaced by Kubernetes.

---

## 🧠 Why Pods are Important in GKE

In **Google Kubernetes Engine (GKE)**, Pods are the **core execution units** where your containers actually run.  
Kubernetes doesn’t run containers directly — it always wraps them inside Pods.

### 🧩 Key Reasons Pods Matter

1. **Encapsulation**  
   A Pod groups one or more containers that need to share resources (network, storage).  
   This makes communication between containers fast and simple.

2. **Isolation**  
   Each Pod has its own network namespace and IP, keeping applications secure and independent.

3. **Scalability**  
   GKE can scale Pods automatically using **Horizontal Pod Autoscaler (HPA)** — adding more Pods when traffic increases.

4. **Scheduling & Load Balancing**  
   GKE places Pods smartly across nodes for high availability and performance.

5. **Health Monitoring**  
   GKE continuously checks Pod health using **liveness** and **readiness probes**.

---

## 🚀 Creating Pods in Kubernetes

There are **two main ways** to create Pods in Kubernetes:
1. **Imperative way** — using direct commands.
2. **Declarative way** — using YAML manifests.

---

### ⚙️ 1️⃣ Imperative Way (Direct Command)

This method uses the `kubectl run` command.

#### 🧩 Example:
```bash
kubectl run my-nginx-pod --image=nginx --port=80
```

#### 📖 What happens:
- Kubernetes creates a Pod named **my-nginx-pod**.
- It pulls the **nginx** image from Docker Hub.
- The Pod runs a container listening on port 80.

#### 🧠 To verify:
```bash
kubectl get pods
kubectl describe pod my-nginx-pod
kubectl logs my-nginx-pod
```

#### 🗑️ To delete the Pod:
```bash
kubectl delete pod my-nginx-pod
```

> 💬 The **imperative approach** is quick and good for testing, but not recommended for production since it doesn’t provide version control or reusability.

---

### 🧾 2️⃣ Declarative Way (Using YAML File)

In this method, we define Pod specifications in a YAML file and apply it using `kubectl apply`.

#### 🧩 Example: `nginx-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

#### 📖 Apply the file:
```bash
kubectl apply -f nginx-pod.yaml
```

#### 🧠 To verify:
```bash
kubectl get pods
kubectl describe pod nginx-pod
kubectl logs nginx-pod
```

#### 🗑️ To delete:
```bash
kubectl delete -f nginx-pod.yaml
```

> 💬 The **declarative approach** is preferred for production because you can store the YAML in Git, reuse it, and manage changes easily.

---

## 🚫 Why We Don’t Create Pods Directly

Creating Pods directly (imperatively or declaratively) works,  
but it’s **not ideal for production** environments.

| Problem | Explanation |
|----------|--------------|
| ❌ **No Auto Healing** | If a Pod crashes, it won’t restart automatically. |
| ❌ **No Scaling** | You can’t easily scale Pods manually. |
| ❌ **No Rolling Updates** | You can’t roll out new versions smoothly. |
| ❌ **No Version History** | You can’t track changes over time. |

---

## ✅ Why We Use Deployments and ReplicaSets

### 1️⃣ **ReplicaSet**
A **ReplicaSet** ensures that a certain number of identical Pods are always running.

- Example: You want **3 Pods** of your app running.
- If one Pod fails, ReplicaSet **automatically creates** a new one.
- If there are extra Pods, it **removes** them.

➡️ **ReplicaSet = Auto-healing + Scaling**

---

### 2️⃣ **Deployment**
A **Deployment** is a higher-level object that manages ReplicaSets.

It provides:
- **Rolling Updates** — update your app with zero downtime.
- **Rollbacks** — go back to an old version easily.
- **Scaling** — increase or decrease Pods automatically.
- **Version Control** — tracks changes between deployments.

➡️ **Deployment = Smart Controller for ReplicaSets**

---

## 🏗️ How It All Connects

Here’s how Kubernetes components connect to run your containers 👇

```
+---------------------------------------------------+
|                   Deployment                      |
|  (Manages rollout, scaling, version history)      |
+-------------------------+-------------------------+
                          |
                          v
                +-------------------+
                |     ReplicaSet    |
                | (Ensures N Pods)  |
                +---------+---------+
                          |
          +---------------+----------------+
          |               |                |
          v               v                v
   +-----------+   +-----------+   +-----------+
   |   Pod 1   |   |   Pod 2   |   |   Pod 3   |
   | (Container)|  | (Container)|  | (Container)|
   +-----------+   +-----------+   +-----------+

Each Pod runs on a Node inside the GKE Cluster
```

---

## 💡 Example: Simple Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:latest
        ports:
        - containerPort: 80
```

### 🔍 What Happens Here
1. Deployment creates a ReplicaSet.  
2. ReplicaSet creates 3 Pods with the NGINX container.  
3. If one Pod crashes, ReplicaSet replaces it.  
4. You can scale up using:
   ```bash
   kubectl scale deployment frontend-deployment --replicas=5
   ```
5. You can update the image safely using:
   ```bash
   kubectl set image deployment/frontend-deployment frontend=nginx:1.27
   ```

---
