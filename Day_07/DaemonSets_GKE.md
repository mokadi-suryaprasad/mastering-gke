# 🧩 Day 07 — DaemonSets

## 🧠 Topic: Running Cluster-wide Agents using DaemonSets in GKE

---

## 1️⃣ Why DaemonSets Exist

Some applications or agents need to run **on every node** in the cluster. Examples:

- Monitoring agents (Prometheus node exporter, Datadog agent)  
- Logging agents (Fluentd, Filebeat)  
- Security agents or network tools  

**Problem:** If you use a Deployment, Pods may only run on some nodes. You want **one Pod per node automatically**.  

**Solution:** **DaemonSets**  

- DaemonSets ensure **a copy of a Pod runs on every node** (or selected nodes).  
- When new nodes are added, DaemonSet automatically creates a Pod on them.  
- When nodes are removed, the Pod is deleted automatically.

---

## 2️⃣ Key Features of DaemonSets

| Feature | Description |
|---------|-------------|
| Cluster-wide Deployment | Runs one Pod per node (or per node selector) |
| Auto-scaling with Nodes | When a new node joins, DaemonSet Pod is created automatically |
| Pod Management | Supports updates and deletions similar to Deployments |
| Node Selection | Can restrict Pods to specific nodes using `nodeSelector` or `affinity` |

---

## 3️⃣ Common Use Cases

- **Monitoring:** Prometheus Node Exporter  
- **Logging:** Fluentd, Filebeat  
- **Security & Compliance:** Falco, Sysdig  
- **Networking:** Calico, Cilium agents  

---

## 4️⃣ Example: Fluentd Logging DaemonSet

### 4.1 Namespace (optional)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
```

```bash
kubectl apply -f namespace.yaml
```

---

### 4.2 DaemonSet YAML

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.15-1
        resources:
          limits:
            memory: 200Mi
            cpu: 200m
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

---

### 4.3 Explanation

- `hostPath` allows the Pod to **read logs from the host node**.  
- One Pod is scheduled on **every node automatically**.  
- If a new node joins, Kubernetes adds a Fluentd Pod to that node.  
- When a node is removed, the Pod is deleted automatically.

---

## 5️⃣ Node Selector & Tolerations (Optional)

You can **run DaemonSet only on certain nodes** using `nodeSelector`:

```yaml
spec:
  template:
    spec:
      nodeSelector:
        node-role.kubernetes.io/worker: ""
```

You can also add **tolerations** to schedule on tainted nodes (like master nodes in GKE):

```yaml
tolerations:
- key: "node-role.kubernetes.io/master"
  operator: "Exists"
  effect: "NoSchedule"
```

---

## 6️⃣ Commands to Try

```bash
# Apply namespace
kubectl apply -f namespace.yaml

# Apply DaemonSet
kubectl apply -f fluentd-daemonset.yaml

# Check all Pods (one per node)
kubectl get pods -n logging -o wide

# Describe a Pod
kubectl describe pod fluentd-xxxxx -n logging

# Delete DaemonSet (it deletes Pods automatically)
kubectl delete ds fluentd -n logging
```

---

## 7️⃣ Visual Diagram

```
Cluster Nodes: node1, node2, node3

DaemonSet: fluentd
-------------------------------------
Pod: fluentd-node1  --> runs on node1
Pod: fluentd-node2  --> runs on node2
Pod: fluentd-node3  --> runs on node3
```

- Every node has **one Pod** from the DaemonSet.  
- Automatic scaling with new nodes.  

---

## ✅ Summary

- **DaemonSets** are for running **cluster-wide agents**.  
- Ensure **one Pod per node** (monitoring/logging/security).  
- Supports **node selectors and tolerations** for fine control.  
- Automatically **creates Pods on new nodes** and **removes Pods from deleted nodes**.  
- Ideal for **monitoring, logging, and cluster-level management tools**.
