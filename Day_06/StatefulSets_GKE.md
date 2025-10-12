# 🧱 Day 06 — StatefulSets

## 🧠 Topic: Running Stateful Workloads using PVs/PVCs in GKE

---

## 1️⃣ Why StatefulSets Exist

In Kubernetes (and GKE), **Deployments** are good for **stateless apps** like web servers.

But some apps **require state**, meaning:

- Each instance needs a **unique identity** (`mysql-0`, `mysql-1`)  
- Each instance needs **its own persistent storage**  
- Pods must start **in order** to maintain consistency  

Examples:

- Databases (MySQL, PostgreSQL)  
- Messaging systems (Kafka, RabbitMQ)  

**Solution:** StatefulSets  

- StatefulSets manage **stateful workloads** with **stable pod names, ordered creation, and persistent storage**.

---

## 2️⃣ Key Features of StatefulSets

| Feature | Description |
|---------|-------------|
| Stable Network Identity | Pods get predictable DNS names (`mysql-0.mysql`) |
| Stable Storage | Each Pod has its own PersistentVolumeClaim (PVC) |
| Ordered Deployment & Scaling | Pods are created one by one: `0 → 1 → 2` |
| Ordered Deletion & Updates | Pods are deleted in reverse order: `2 → 1 → 0` |

---

## 3️⃣ StatefulSet vs Deployment

| Aspect | Deployment | StatefulSet |
|--------|-----------|-------------|
| Pod Names | Random | Stable (`app-0`, `app-1`) |
| Storage | Shared or ephemeral | Persistent (one PV per Pod) |
| Pod Creation Order | Parallel | Sequential (`0 → 1 → 2`) |
| Use Case | Stateless apps | Stateful apps (databases, queues) |

---

## 4️⃣ PersistentVolume (PV) and PersistentVolumeClaim (PVC)

- **PersistentVolume (PV):** Storage resource in the cluster.  
- **PersistentVolumeClaim (PVC):** Request for storage by a Pod.  

StatefulSets use **PVC templates** to automatically assign **unique storage** to each Pod.

---

## 5️⃣ Step-by-Step GKE Storage Creation

In GKE, you can use **Dynamic Provisioning** or **Static PV creation**.

### 5.1 Create a PersistentVolume (optional - static)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-0
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  gcePersistentDisk:
    pdName: mysql-disk-0
    fsType: ext4
```

```bash
kubectl apply -f mysql-pv.yaml
kubectl get pv
```

---

### 5.2 Create a PersistentVolumeClaim (PVC)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc-0
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

```bash
kubectl apply -f mysql-pvc.yaml
kubectl get pvc
```

> In StatefulSets, PVC templates automatically create PVCs for each Pod, so you often don’t need to create PV/PVC manually if dynamic provisioning is enabled.

---

### 5.3 Use PVC in StatefulSet

```yaml
volumeClaimTemplates:
- metadata:
    name: mysql-storage
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: 1Gi
```

- Each Pod in the StatefulSet will get a **unique PVC**:  
  `mysql-storage-mysql-0`, `mysql-storage-mysql-1`, `mysql-storage-mysql-2`  

---

## 6️⃣ Example: MySQL StatefulSet

### 6.1 Headless Service

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

### 6.2 StatefulSet YAML

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

---

## 7️⃣ Ordered Creation in StatefulSets

1. Pod `mysql-0` is created first, PVC bound, Pod Ready  
2. Pod `mysql-1` is created next, PVC bound, starts after Pod 0 Ready  
3. Pod `mysql-2` is created last, PVC bound, starts after Pod 1 Ready  

> If Pod 0 fails, Pods 1 and 2 wait to ensure correct stateful behavior.

---

## 8️⃣ Visual Diagram

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

---

## 9️⃣ Commands to Try

```bash
kubectl apply -f mysql-service.yaml
kubectl apply -f mysql-statefulset.yaml
kubectl get pods -w
kubectl get pvc
kubectl describe pod mysql-0
```

---

## ✅ Summary

- StatefulSets are for **stateful applications**.  
- Pods have **stable identities** and **persistent storage**.  
- Pods are **created, scaled, and deleted in order**.  
- PVC templates ensure each Pod gets **unique storage**.  
- Required for **databases, queues, and any app that needs state**.  
- In GKE, PVs can be **dynamically provisioned** or **statically created** for complete control.
