# ⚙️ ReplicaSet and Deployment in Kubernetes

## 📚 Introduction

In Kubernetes, **ReplicaSets** and **Deployments** are used to ensure your application is **always running**, **scalable**, and **recoverable** from failures.

Think of them like this:

* **ReplicaSet** ensures that a specific number of Pod copies (replicas) are always running.
* **Deployment** manages ReplicaSets and adds **rollout**, **rollback**, and **version control** capabilities.

---

## 🧩 1. ReplicaSet

### 🔹 What is a ReplicaSet?

A **ReplicaSet (RS)** ensures that a **specified number of identical Pods** are running at any time.
If a Pod crashes, the ReplicaSet **creates a new one automatically**.

### 🔹 Why use ReplicaSet?

* To maintain **high availability**.
* To scale Pods **horizontally** (add/remove replicas).
* To auto-recover Pods in case of node or Pod failure.

---

### ⚙️ Example: ReplicaSet YAML

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### 🧠 Explanation:

* `replicas: 3` → 3 Pods will be created.
* `selector` → tells which Pods this ReplicaSet manages.
* `template` → defines how each Pod should look.

---

### 🧪 Commands:

```bash
kubectl apply -f replicaset.yaml         # Create ReplicaSet
kubectl get replicaset                   # List ReplicaSets
kubectl get pods                         # Check running Pods
kubectl scale replicaset nginx-replicaset --replicas=5   # Scale Pods
kubectl delete replicaset nginx-replicaset               # Delete RS and Pods
```

---

## 🧩 2. Deployment

### 🔹 What is a Deployment?

A **Deployment** is a higher-level controller that **manages ReplicaSets** and allows you to:

* Deploy new versions of your app
* Rollback to previous versions
* Scale Pods easily
* Perform rolling updates

> You **rarely create ReplicaSets directly** — you define a Deployment, and it creates/manages ReplicaSets internally.

---

### ⚙️ Example: Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### 🧠 Explanation:

* `Deployment` creates a ReplicaSet under the hood.
* When you **update** the image, a **new ReplicaSet** is created.
* The **old ReplicaSet** is scaled down gradually.

---

### 🧪 Commands:

```bash
# Create Deployment
kubectl apply -f deployment.yaml

# View Deployment, ReplicaSet, and Pods
kubectl get deploy,rs,pods
kubectl describe deployment nginx-deployment
kubectl rollout status deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
```

---

## 🚀 3. Deployment Strategies (With Production Examples)

Kubernetes supports different **deployment strategies** to control how updates are released into production.

---

### 🟢 1. **Recreate Strategy**

* Deletes all old Pods before creating new ones.
* **Downtime occurs**, so not used in production often.

```yaml
spec:
  strategy:
    type: Recreate
```

**🧠 Example Use Case:**
Used when your app **cannot handle two versions** running at the same time.
Example: Database migrations that change schema.

**⚠️ Drawback:**
Your app will have **downtime** during rollout.

---

### 🔵 2. **RollingUpdate Strategy (Default)**

* Gradually replaces old Pods with new ones.
* Ensures **zero downtime** during deployment.

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

**🧠 Example Use Case:**
Used for most **production web apps** or **APIs** where availability is critical.

**✅ Benefit:**
Ensures smooth transitions between versions.

**⚙️ Example Commands:**

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.26
kubectl rollout status deployment/nginx-deployment
```

---

### 🟣 3. **Blue-Green Deployment (Manual Strategy)**

* You run **two environments**:

  * **Blue (current)**: live version
  * **Green (new)**: new version
* After testing the new version (Green), switch traffic to it.

**🧠 Example Use Case:**
Used in **high-risk production environments** (e.g., banking apps).

**⚙️ Example Steps:**

1. Deploy new version under a **different Deployment name**.
2. Test it internally.
3. Update Service to point to the new Deployment.
4. Delete the old one if everything works.

---

### 🟠 4. **Canary Deployment**

* Gradually send **a small percentage of traffic** to the new version.
* Observe behavior and **increase traffic slowly**.

**🧠 Example Use Case:**
Used by **Netflix**, **Google**, **Facebook**, etc. for safe rollouts.

**⚙️ Steps:**

1. Create a new Deployment with a smaller number of replicas (e.g., 1 out of 10).
2. Use **Ingress or Service weights** to route 10% traffic to new version.
3. Increase replicas if stable.

**✅ Benefit:**
If issues occur, rollback immediately with minimal user impact.

---

## 🔁 4. Rollback Example

```bash
kubectl rollout undo deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
```

---

## 📊 Summary Table

| Feature            | ReplicaSet                      | Deployment                    |
| ------------------ | ------------------------------- | ----------------------------- |
| Purpose            | Maintain a fixed number of Pods | Manage ReplicaSets & versions |
| Rollback Support   | ❌ No                            | ✅ Yes                         |
| Rolling Updates    | ❌ No                            | ✅ Yes                         |
| Scaling            | ✅ Yes                           | ✅ Yes                         |
| Version Control    | ❌ No                            | ✅ Yes                         |
| Used In Production | ⚠️ Rarely                       | ✅ Always                      |

---

## 🧠 Quick Recap

* **ReplicaSet** keeps Pods running.
* **Deployment** adds versioning, rollout, rollback, and easier updates.
* **RollingUpdate** = most common production strategy.
* **Canary** & **Blue-Green** are advanced safe rollout methods.

---

## 🎯 Hands-On Practice

```bash
# Step 1: Create Deployment
kubectl apply -f deployment.yaml

# Step 2: Update image version
kubectl set image deployment/nginx-deployment nginx=nginx:1.26

# Step 3: Watch rollout progress
kubectl rollout status deployment/nginx-deployment

# Step 4: Rollback if needed
kubectl rollout undo deployment/nginx-deployment
```

---

## 🖼️ Visual Diagram

```
+------------------------+
|      Deployment        |
|------------------------|
|  manages ReplicaSets   |
|  ↳ each RS manages Pods|
+------------------------+
         ↓
  +---------------+
  | ReplicaSet v1 | --> Pods (v1)
  +---------------+
         ↓
  +---------------+
  | ReplicaSet v2 | --> Pods (v2)
  +---------------+
```

---