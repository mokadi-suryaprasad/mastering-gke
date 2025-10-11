# 🌐 Day_05 — Kubernetes Services

In this Day_05, we will focus on **three important aspects of Kubernetes Services**:

1️⃣ **Load Balancing** — distribute traffic across multiple Pod replicas to ensure high availability.

2️⃣ **Service Discovery** — provide a stable endpoint (IP/DNS) so Pods can find and communicate with each other, even when individual Pod IPs change.

3️⃣ **Expose to the World** — allow external users or other teams to access your application securely.

---

## 1️⃣ Load Balancing

**What is it?**

* Distribute traffic across multiple Pods.
* Ensure high availability and performance.

**How it works:**

* A **Service** automatically balances traffic to all Pods matching its **selector labels**.
* Even if a Pod fails, traffic is routed to healthy Pods.

---

## 2️⃣ Service Discovery

**What is it?**

* Pods may restart and get new IPs.
* Other Pods need a stable endpoint to communicate.

**Solution:**

* Kubernetes **Service** provides a stable DNS name or IP.
* Other Pods can use `http://<service-name>:<port>` to communicate reliably.

---

## 3️⃣ Expose to the World

**What is it?**

* Provide access to the application from outside the cluster.

**Service types:**

1. **NodePort** — Exposes service on each Node IP at a static port.
2. **LoadBalancer** — Cloud provider assigns public IP and load balances traffic.
3. **Ingress** — Routes HTTP/S traffic based on hostname or path.

---

## 🏗️ Real-Time Example: Frontend Application

**Requirements:**

* 3 replicas of frontend app
* Load balancing
* Internal service discovery
* External access

### Step 1: Deployment (3 replicas)

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
        image: nginx:1.23
        ports:
        - containerPort: 80
```

### Step 2: Service (Load Balancing + Discovery)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
  type: LoadBalancer
```

### What happens:

1. **Load Balancing:** Requests to service IP are distributed across all Pods.
2. **Service Discovery:** Other Pods can reach the frontend via `http://frontend-service:80`.
3. **Expose to the World:** Cloud assigns external IP for user access.

---

## 🔹 Problem 1: Auto-Healing Pods and Changing IPs

When a Pod goes down and Kubernetes creates a new Pod (auto-healing via ReplicaSet), the **new Pod gets a new IP address**.

### Question: How do users know about the new IP?

**Solution:** Kubernetes uses **Services** to provide a **stable endpoint (IP/DNS)**. Pods come and go, but the Service IP remains constant.

### Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

* **ClusterIP** provides a **stable internal IP** inside the cluster.
* Even if Pods restart and get new IPs, the Service ensures traffic is always routed to **available Pods**.

**Key Concept:** Service acts as a **load balancer and stable endpoint** inside the cluster.

---

## 🔹 Problem 2: Multiple Pod Replicas, Single Access Point

If your app has multiple replicas of a Pod, each has a **unique IP**, but users need **one IP/DNS** to access the app (like google.com).

**Solution:** Kubernetes Service provides:

* **ClusterIP** — internal access
* **NodePort** — access via node IP + port
* **LoadBalancer** — external cloud LB with public IP

### Example: LoadBalancer Service for production

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-loadbalancer
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

* Cloud provider assigns a **public IP**.
* Users can access the application using this IP.
* Service automatically **routes traffic to all available replicas**.

**Key Concept:** One stable Service IP or DNS can reach **all pods** behind it, solving the multi-replica access problem.

---

## 🔹 Problem 3: External Access by People Outside Cluster

Other teams or external users may need to access the application but **don’t have cluster access**.

**Solution:** Kubernetes Services expose Pods outside the cluster:

1. **NodePort** — exposes service on all cluster nodes at a static port.
2. **LoadBalancer** — cloud provider assigns public IP and load balances.
3. **Ingress** — routes HTTP/S traffic with hostname and paths.

### Example: NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-nodeport
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30036
  type: NodePort
```

* Access the app via `NodeIP:30036`.

### Example: External LoadBalancer (GCP/AWS)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-lb
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
  type: LoadBalancer
```

* Cloud provider automatically creates **external IP**.
* Can be accessed by anyone with internet access (firewall rules permitting).

---

## 🔹 Headless Service

* Sometimes we want **service discovery without load balancing**.
* **Headless Service** is used for databases, StatefulSets, or direct Pod access.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-headless
spec:
  selector:
    app: frontend
  clusterIP: None
  ports:
    - port: 80
      targetPort: 80
```

* **DNS** returns **all pod IPs**.
* Useful for applications needing **direct Pod communication**.

---

## 🔹 Summary of Service Types

| Service Type | Use Case                       | Example                          |
| ------------ | ------------------------------ | -------------------------------- |
| ClusterIP    | Internal access within cluster | Default internal service         |
| NodePort     | External access via node IP    | `NodeIP:Port`                    |
| LoadBalancer | Cloud public IP access         | Production apps on GCP/AWS/Azure |
| Headless     | Service discovery without LB   | Stateful apps, DB clusters       |
| ExternalName | Map service to external DNS    | Connect to external DB           |

---

## 🔹 Real-Time Example: Frontend Deployment

1. **Deploy frontend Pods**:

```bash
kubectl apply -f frontend-deployment.yaml
```

2. **Expose via LoadBalancer**:

```bash
kubectl apply -f frontend-loadbalancer.yaml
```

3. **Check Service IP**:

```bash
kubectl get svc frontend-loadbalancer
```

4. **Access application**:

* Use `EXTERNAL-IP` from above command in browser.
* Service routes traffic to all running Pods automatically.

---
