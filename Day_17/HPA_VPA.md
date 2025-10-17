# ☸️ Day 17 — Kubernetes Autoscaling (HPA & VPA)

Autoscaling in Kubernetes means automatically adjusting resources (Pods or CPU/Memory) based on the load and performance of your application.
This helps your app stay fast, stable, and cost-efficient — even when traffic changes.

## ⚙️ 1. What is Autoscaling?

**Autoscaling = “Scale up when busy, scale down when idle.”**

There are three main types of scaling in Kubernetes:

```text
| Type                                | Scales             | Example                       |
| ----------------------------------- | ------------------ | ----------------------------- |
| **HPA (Horizontal Pod Autoscaler)** | Number of Pods     | Adds/removes Pods             |
| **VPA (Vertical Pod Autoscaler)**   | CPU/Memory per Pod | Increases Pod resources       |
| **Cluster Autoscaler**              | Number of Nodes    | Adds/removes Nodes in cluster |
```

---

## 🚀 2. Horizontal Pod Autoscaler (HPA)

### Concept

HPA automatically changes the number of Pod replicas in a Deployment, ReplicaSet, or StatefulSet based on CPU, memory, or custom metrics.

- **Example:**
  - If CPU usage > 70%, HPA increases Pod count.
  - If CPU usage < 50%, HPA reduces Pod count.

### Prerequisites

Before using HPA:

1. **Metrics Server must be installed**

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. **Pods must have CPU/Memory requests defined** in their YAML.

### Example: HPA Setup for NGINX Deployment

#### Step 1: Create a Deployment

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
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
        image: nginx
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

#### Step 2: Expose the Deployment

```bash
kubectl expose deployment nginx-deployment --port=80 --type=LoadBalancer
```

#### Step 3: Create the HPA

```bash
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
```

Apply it:

```bash
kubectl apply -f hpa.yaml
```

#### Step 4: Load Testing

Run a simple load generator:

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
```

Inside the Pod:

```bash
while true; do wget -q -O- http://nginx-deployment; done
```

Now watch HPA in action:

```bash
kubectl get hpa -w
kubectl get pods
```

> You’ll see Pods increasing as CPU load rises!

---

## ⚙️ 3. Vertical Pod Autoscaler (VPA)

### Concept

VPA automatically adjusts CPU and memory requests/limits for your Pods based on usage.

It helps when your app’s load pattern changes (e.g., a service sometimes needs more CPU).  
Instead of scaling Pods, VPA changes each Pod’s **resource allocation**.

### VPA Modes

```text
| Mode        | Description                               |
| ----------- | ----------------------------------------- |
| **Off**     | Only gives recommendations                |
| **Auto**    | Automatically updates Pods                |
| **Initial** | Applies recommendations only at Pod start |
```

### Example: VPA for NGINX Deployment

#### Step 1: Install VPA (once per cluster)

```bash
kubectl apply -f https://github.com/kubernetes/autoscaler/releases/latest/download/vertical-pod-autoscaler.yaml
```

#### Step 2: Create VPA YAML

```bash
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: nginx-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: nginx-deployment
  updatePolicy:
    updateMode: "Auto"
```

Apply it:

```bash
kubectl apply -f vpa.yaml
```

#### Verify VPA Recommendations

```bash
kubectl get vpa
kubectl describe vpa nginx-vpa
```

> You’ll see suggested or applied CPU/Memory values.

---

## ⚖️ 4. HPA vs VPA

```text
| Feature      | HPA                  | VPA                            |
| ------------ | -------------------- | ------------------------------ |
| Scales       | Number of Pods       | CPU/Memory per Pod             |
| Metric       | CPU/Memory/Custom    | Historical resource usage      |
| Use Case     | Varying load/traffic | Constant load but wrong sizing |
| Common Setup | Web servers          | Databases, back-end APIs       |
```

---

## 🧠 5. Best Practices

✅ Always define CPU and memory requests.  
✅ Use **HPA + Cluster Autoscaler** together for full elasticity.  
⚠️ Avoid running **HPA + VPA** on the same resource unless tested.  
📊 Monitor with:

```bash
kubectl get hpa
kubectl top pods
kubectl describe vpa
```

---

## 🧩 6. Diagram (Simple View)

```plaintext
        +--------------------+
        |   Users / Traffic  |
        +---------+----------+
                  |
                  v
          +---------------+
          | HPA Controller | --> Adds/Removes Pods
          +---------------+
                  |
                  v
          +---------------+
          | Cluster Autoscaler | --> Adds/Removes Nodes
          +---------------+
                  |
                  v
          +---------------+
          | VPA Controller | --> Adjusts Pod Resources
          +---------------+
```

---

## 🚀 Summary Table

```text
| Autoscaler             | Purpose               | Works On   | Example Trigger    |
| ---------------------- | --------------------- | ---------- | ------------------ |
| **HPA**                | Adjusts Pod Count     | Deployment | High CPU           |
| **VPA**                | Adjusts Pod Resources | Container  | Memory pressure    |
| **Cluster Autoscaler** | Adjusts Node Count    | Cluster    | Unschedulable Pods |
```
