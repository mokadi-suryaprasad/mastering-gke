
# 🧱 Day 06 — StatefulSets

## 🧠 Topic: Running Stateful Workloads using PVs/PVCs in GKE

## 1️⃣ Why StatefulSets Exist

In Kubernetes (and GKE), Deployments are good for stateless apps like web servers.

But some apps require state, meaning:
- Each instance needs a unique identity (mysql-0, mysql-1)
- Each instance needs its own persistent storage
- Pods must start in order to maintain consistency

Examples:
- Databases (MySQL, PostgreSQL)
- Messaging systems (Kafka, RabbitMQ)

Solution: StatefulSets
StatefulSets manage stateful workloads with stable pod names, ordered creation, and persistent storage.

## 2️⃣ Key Features of StatefulSets

| Feature | Description |
|---------|-------------|
| Stable Network Identity | Pods get predictable DNS names (mysql-0.mysql) |
| Stable Storage | Each Pod has its own PersistentVolumeClaim (PVC) |
| Ordered Deployment & Scaling | Pods are created one by one: 0 → 1 → 2 |
| Ordered Deletion & Updates | Pods are deleted in reverse order: 2 → 1 → 0 |

## 3️⃣ StatefulSet vs Deployment

| Aspect | Deployment | StatefulSet |
|--------|-----------|-------------|
| Pod Names | Random | Stable (app-0, app-1) |
| Storage | Shared or ephemeral | Persistent (one PV per Pod) |
| Pod Creation Order | Parallel | Sequential (0 → 1 → 2) |
| Use Case | Stateless apps | Stateful apps (databases, queues) |

## 4️⃣ PersistentVolume and PersistentVolumeClaim

- PersistentVolume (PV): Storage in the cluster.
- PersistentVolumeClaim (PVC): Request for storage by a Pod.

StatefulSets use PVC templates to automatically assign unique storage to each Pod.

## 5️⃣ Example: MySQL StatefulSet

### 5.1 Headless Service (required)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
    - port: 3306
      name: mysql
  clusterIP: None
  selector:
    app: mysql
```

### 5.2 StatefulSet YAML

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: "mysql"
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

## 6️⃣ Ordered Creation in StatefulSets

When creating 3 replicas:
1. Pod mysql-0 is created first, PVC mysql-storage-mysql-0 is bound, Pod becomes Ready.
2. Pod mysql-1 is created next, PVC mysql-storage-mysql-1 is bound, Pod starts after Pod 0 is Ready.
3. Pod mysql-2 is created last, PVC mysql-storage-mysql-2 is bound, Pod starts after Pod 1 is Ready.

If Pod 0 fails, Pods 1 and 2 wait to ensure correct stateful behavior.

## 7️⃣ Visual Diagram

```
StatefulSet: mysql (replicas: 3)
Ordered Creation: 0 -> 1 -> 2

Pod 0: mysql-0
  PVC: mysql-storage-mysql-0
  DNS: mysql-0.mysql

Pod 1: mysql-1
  PVC: mysql-storage-mysql-1
  DNS: mysql-1.mysql

Pod 2: mysql-2
  PVC: mysql-storage-mysql-2
  DNS: mysql-2.mysql
```

## 8️⃣ Commands to Try

```bash
kubectl apply -f mysql-service.yaml
kubectl apply -f mysql-statefulset.yaml
kubectl get pods -w
kubectl get pvc
kubectl describe pod mysql-0
```

## ✅ Summary

- StatefulSets are for stateful applications.
- Pods have stable identities and persistent storage.
- Pods are created, scaled, and deleted in order.
- PVC templates ensure each Pod gets unique storage.
- Required for databases, queues, and any app that needs state.
