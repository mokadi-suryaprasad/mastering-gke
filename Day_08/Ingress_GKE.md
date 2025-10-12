# 🚪 Day 08 — Ingress in GKE

## 🧠 Topic: Path-Based Routing and TLS/SSL Termination

---

## 1️⃣ Why Ingress Exists

In Kubernetes (GKE), **Services** expose your Pods:

- **NodePort** exposes on every node but requires knowing node IPs  
- **LoadBalancer** creates one IP per service → not scalable  

**Ingress** solves this:

- Expose **multiple services via a single IP**  
- Support **path-based or host-based routing**  
- Handle **SSL/TLS termination** at the Ingress controller

> Think of Ingress as a **smart router** for your cluster.

---

## 2️⃣ Key Features of Ingress

| Feature | Description |
|---------|-------------|
| Path-based routing | `/frontend` → frontend-service, `/backend` → backend-service |
| Host-based routing | `app1.example.com` → service1, `app2.example.com` → service2 |
| SSL/TLS termination | Offload SSL at Ingress, Pods get plain HTTP traffic |
| Single external IP | Multiple services accessible via one IP |

---

## 3️⃣ Live Deployment Example

We will deploy:

1. **Frontend App** (nginx)  
2. **Backend App** (simple Python Flask)  
3. **Ingress** with path-based routing  
4. **TLS Secret** for HTTPS

---

### 3.1 Step 1: Create Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-demo
```

```bash
kubectl apply -f namespace.yaml
```

---

### 3.2 Step 2: Deploy Frontend App

**frontend-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ingress-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
```

**frontend-service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ingress-demo
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

Apply:

```bash
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

---

### 3.3 Step 3: Deploy Backend App

**backend-deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: ingress-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: flask-app
        image: python:3.11-slim
        command: ["python"]
        args: ["-m", "http.server", "5000"]
        ports:
        - containerPort: 5000
```

**backend-service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: ingress-demo
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```

Apply:

```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml
```

---

### 3.4 Step 4: Create TLS Secret

Generate a self-signed certificate:

```bash
openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 -keyout tls.key -out tls.crt \
-subj "/CN=example.com/O=example"
```

Create TLS secret in Kubernetes:

```bash
kubectl create secret tls tls-secret \
--key tls.key --cert tls.crt \
-n ingress-demo
```

---

### 3.5 Step 5: Create Ingress with Path-Based Routing and TLS

**ingress.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
  namespace: ingress-demo
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  tls:
  - hosts:
    - example.com
    secretName: tls-secret
  rules:
  - host: example.com
    http:
      paths:
      - path: /frontend
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /backend
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 80
```

Apply:

```bash
kubectl apply -f ingress.yaml
```

---

### 3.6 Step 6: Verify Ingress

```bash
kubectl get ingress -n ingress-demo
kubectl describe ingress demo-ingress -n ingress-demo
```

- External IP will be shown in `kubectl get ingress`  
- Access in browser (replace IP with your external IP):

```
https://<EXTERNAL_IP>/frontend
https://<EXTERNAL_IP>/backend
```

- HTTPS is terminated at Ingress using TLS secret  
- Path-based routing sends traffic to correct service

---

### 3.7 Step 7: Visual Diagram

```
             External IP (Ingress)
                     |
         --------------------------
         |                        |
     /frontend                 /backend
       |                         |
frontend-service           backend-service
       |                         |
  frontend Pods               backend Pods
```

- One IP serves multiple services  
- TLS terminates at Ingress, Pods receive HTTP

---

## ✅ Summary

- **Ingress** exposes multiple services with **one external IP**  
- Supports **path-based and host-based routing**  
- Enables **TLS/SSL termination** for secure traffic  
- Essential for **production deployments** in GKE  
- Can be combined with **any number of services** using path or host rules

---

## 8️⃣ Commands Overview

```bash
# Apply namespace
kubectl apply -f namespace.yaml

# Apply frontend and backend deployments and services
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml

# Create TLS secret
kubectl create secret tls tls-secret --key tls.key --cert tls.crt -n ingress-demo

# Apply Ingress
kubectl apply -f ingress.yaml

# Check resources
kubectl get pods -n ingress-demo
kubectl get svc -n ingress-demo
kubectl get ingress -n ingress-demo
kubectl describe ingress demo-ingress -n ingress-demo
```

---

This gives you a **live working deployment** with:

- Frontend and backend services  
- Ingress with path-based routing  
- TLS termination for HTTPS traffic  

You can now **test, update, or expand** to host multiple services on the same IP in GKE.

