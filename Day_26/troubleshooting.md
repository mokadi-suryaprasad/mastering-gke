# Filestore + GKE Troubleshooting Guide

This document explains the exact issue you faced, why it happened, and how to troubleshoot it in the future.

---

## ✅ **Problem Summary**

Your Filestore-based application pod (`filestore-writer-app`) was in **ImagePullBackOff** state.

Later the issue was solved and the pod started running.

But you said your **LoadBalancer IP is not showing the application output**.

This document covers both issues.

---

# 1️⃣ IMAGEPULLBACKOFF ISSUE

### ✅ **Root Cause**

You used the image:

```
docker.io/library/centos:latest
```

But **CentOS no longer provides `latest` tag on Docker Hub**, so Kubernetes could not pull the image.

### ✅ Fix

Use a valid, existing image:

```
image: centos:7
```

Or use Ubuntu:

```
image: ubuntu:20.04
```

---

# 2️⃣ APPLICATION NOT WORKING BEHIND LOAD BALANCER

Your Filestore demo works, but your app behind LoadBalancer is not showing expected output.

### ✅ Possible Causes

### **Cause 1: No application running on port 80**

Your CentOS container only runs:

```
while true; do echo ... >> /data/myapp1.txt; done
```

This **does NOT run a web server**.
There is **nothing to serve HTTP traffic**, so the LoadBalancer returns empty page or connection reset.

### ✅ Fix

Use a simple webserver:

```
image: nginx
```

Mount the Filestore volume inside `/usr/share/nginx/html`.

---

# 3️⃣ VERIFY FILESTORE IS WORKING

Exec into the pod:

```
kubectl exec -it filestore-writer-app -- sh
```

Check file content:

```
cat /data/myapp1.txt
```

If file is updating every 5 sec → Filestore is working.

---

# 4️⃣ VERIFY MULTIPLE PODS CAN READ SAME FILE

```
kubectl exec -it <pod-name> -- cat /data/myapp1.txt
```

If both pods see same file → RWX working.

---

# 5️⃣ FIXING YOUR LOADBALANCER DEPLOYMENT

Use this Deployment:

```yaml\apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-filestore-web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: web
        image: nginx
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: filestore-vol
      volumes:
      - name: filestore-vol
        persistentVolumeClaim:
          claimName: gke-filestore-pvc
```

Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-lb
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 80
```

Check LB:

```
kubectl get svc webapp-lb
```

Hit the external IP → You should now see the Filestore text in browser.

---

# ✅ Final Notes

✅ Filestore worked properly (RWX shared storage)
✅ Issue was **not** with Filestore
❌ Issue was with container not running a web server

Fix → Use nginx and mount Filestore path to HTML folder.

---

# ✅ Troubleshooting Checklist

* [ ] PVC bound successfully
* [ ] Pod mounts volume (`kubectl describe pod`)
* [ ] Container image exists (no ImagePullBackOff)
* [ ] Application listens on correct port
* [ ] Service `selector` matches pod labels
* [ ] LoadBalancer external IP is assigned
* [ ] Logs show no crashloop

---