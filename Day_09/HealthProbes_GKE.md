# ❤️ Day 09 — Health Probes in GKE

## 🧠 Topic: Startup, Liveness & Readiness Probes

---

## 1️⃣ Why Health Probes Exist

In Kubernetes (GKE), Pods may **fail, crash, or take time to start**.  

Health probes help Kubernetes:

- Detect if a container is **alive** (Liveness)  
- Determine if a container is **ready to accept traffic** (Readiness)  
- Handle **slow-starting containers** (Startup)  

> Using probes makes your application **more stable, reliable, and production-ready**.

---

## 2️⃣ Types of Probes

| Probe Type       | Purpose | Action on Failure |
|-----------------|---------|-----------------|
| **Startup Probe**  | Checks if container has **successfully started** | If fails, Pod is killed and restarted |
| **Liveness Probe** | Checks if container is **alive** | If fails, Pod is restarted |
| **Readiness Probe** | Checks if container is **ready to serve traffic** | If fails, Pod is removed from Service endpoints (no restart) |

---

## 3️⃣ Easy Explanation

1. **Startup Probe**
   - For containers that **take a long time to initialize** (like databases).  
   - Prevents **Liveness Probe from killing the container too early**.  
   - Only runs **until the container successfully starts**.

2. **Liveness Probe**
   - Monitors if a container is **healthy and alive**.  
   - If unhealthy → **Pod is restarted automatically**.

3. **Readiness Probe**
   - Monitors if a container is **ready to accept traffic**.  
   - If not ready → **Pod is removed from Service endpoints**, but **not restarted**.

---

## 4️⃣ Live Example: Deployment with All Probes

**health-probes-demo.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: health-probes-demo
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: health-demo
  template:
    metadata:
      labels:
        app: health-demo
    spec:
      containers:
      - name: myapp
        image: nginx:stable
        ports:
        - containerPort: 80

        # Startup Probe: waits for nginx to fully start
        startupProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 12  # wait up to 1 minute

        # Liveness Probe: restart if unhealthy
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3

        # Readiness Probe: remove from service if not ready
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 3
```

---

## 5️⃣ Explanation of Example

- **Startup Probe**  
  - Ensures container finishes **initial startup** before Liveness starts checking.  
  - Prevents **false restarts** for slow-starting apps.

- **Liveness Probe**  
  - After startup, checks if container is **alive** every 10 seconds.  
  - Restart occurs if probe fails 3 times.

- **Readiness Probe**  
  - Checks if container can **serve traffic** every 5 seconds.  
  - If fails, container is **temporarily removed from Service endpoints**.  

---

## 6️⃣ Commands to Apply & Test

```bash
# Apply Deployment
kubectl apply -f health-probes-demo.yaml

# Watch Pods
kubectl get pods -w

# Describe Pod for probes
kubectl describe pod <pod-name>

# Check Service endpoints
kubectl get endpoints
```

### Simulate Failure

1. Exec into Pod:

```bash
kubectl exec -it <pod-name> -- /bin/bash
```

2. Stop nginx:

```bash
nginx -s stop
```

- **Liveness Probe** → Pod restarts automatically  
- **Readiness Probe** → Pod removed from Service endpoints until nginx starts again  

---

## 7️⃣ Visual Diagram

```
Pod (myapp)
  |
  +-- Startup Probe: wait for container to initialize
  |
  +-- Liveness Probe: restart Pod if fails
  |
  +-- Readiness Probe: remove Pod from Service if fails
```

---

## ✅ Summary

- **Startup Probe** → Ensures slow containers finish initialization  
- **Liveness Probe** → Detects crashes/unhealthy Pods → restarts them  
- **Readiness Probe** → Controls traffic routing → healthy Pods serve traffic only  
- Using all three probes ensures **high availability and stability** in GKE  

---

### 8️⃣ Quick Commands Summary

```bash
kubectl apply -f health-probes-demo.yaml
kubectl get pods -w
kubectl describe pod <pod-name>
kubectl get endpoints
```

> Combine probes in **any application** (nginx, databases, APIs, microservices) to make your deployments **production-ready**.  
