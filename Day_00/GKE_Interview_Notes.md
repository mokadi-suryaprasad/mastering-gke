# GKE Interview Notes 
This document explains **GKE** and **Kubernetes** in very simple English. Good for interviews and beginners.

---

## 1. What is GKE? 

GKE (Google Kubernetes Engine) is a Google Cloud service that helps you run Kubernetes very easily. You do not need to manage complicated things like control plane, master nodes, load balancing, networking setup, etc. Google handles most of the heavy work.

**Think of GKE like this:**

* You bring your Docker images
* You write your Kubernetes YAML files
* GKE runs them in a safe, scalable way
* Google handles updates, upgrades, reliability, and security

### Why GKE is useful:

* Very strong auto‑scaling
* Very stable and secure
* Easy integration with other Google Cloud services
* Google manages the control plane (no headache for you)
* You pay only for the worker nodes or pods (in Autopilot)
  GKE (Google Kubernetes Engine) is a service in Google Cloud that helps you run Kubernetes easily.
  Google manages the control plane. You only manage your applications.

**Why it is useful:**

* No need to manage master nodes.
* Easy upgrades.
* Easy autoscaling.
* Works very well with Google Cloud services.

---

## 2. GKE Architecture

### **Control Plane (Google manages it):**

* **API Server** → Talks to kubectl.
* **Scheduler** → Decides which node runs your pod.
* **etcd** → Stores cluster data.
* **Controllers** → Make sure everything stays healthy.

### **Worker Nodes (You use them):**

* **Kubelet** → Runs your containers.
* **kube-proxy** → Handles networking.
* **Container runtime** → Runs containers (containerd).

---

## 3. Node Pools

A node pool is a group of nodes with the same type.
Example:

* Small nodes for simple apps.
* Large nodes for heavy apps.
* GPU nodes.

---

## 4. Autopilot vs Standard

### **Autopilot Mode**

Google manages nodes also. You pay only for the pod resources.

### **Standard Mode**

You manage nodes and node pools.

---

## 5. Service Accounts

Service Accounts help pods talk to Google Cloud services.

### **Workload Identity**

Best method.
It allows a Kubernetes service account to use a Google Cloud service account **without passwords or keys**.

---

## 6. How to Deploy an App in GKE 

1. Build Docker image and push to Artifact Registry.
2. Create Deployment and Service YAML files.
3. Apply them using:

```
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

4. Check pods:

```
kubectl get pods
```

5. Access app using LoadBalancer or Ingress.

---

## 7. Kubernetes Objects 

### **Deployment**

Runs multiple copies of your app.

### **StatefulSet**

Used for databases. Keeps the same pod name and disk.

### **Service**

Gives a stable IP to reach pods.

### **Ingress**

Handles external traffic and routing.

---

## 8. How to Schedule Pod to a Specific Node

### **nodeSelector**

```
nodeSelector:
  env: prod
```

### **Node Affinity**

More advanced way.

### **Taints and Tolerations**

Use when you want only special pods to run on special nodes.

---

## 9. Service Types 
* **ClusterIP** → Inside cluster only.
* **NodePort** → Open on every node (port 30000+).
* **LoadBalancer** → Cloud Load Balancer.
* **Headless Service** → No cluster IP, used by StatefulSets.

---

## 10. Ingress

Ingress sends traffic from internet → Load Balancer → Service → Pod.
It supports:

* SSL
* Path-based routing
* Host-based routing

---

## 11. Storage 

* **PV** → Actual storage.
* **PVC** → Request storage.
* **StorageClass** → Defines how storage is created.

---

## 12. Autoscaling in GKE

### **HPA (Horizontal Pod Autoscaler)**

Adds more pods when CPU/memory is high.

### **VPA (Vertical Pod Autoscaler)**

Gives more CPU/memory to the same pod.

### **Cluster Autoscaler**

Adds more nodes when cluster is full.

---

## 13. Probes (Very Simple)

### **Liveness Probe** → Restart container if unhealthy.

### **Readiness Probe** → Do not send traffic if pod not ready.

### **Startup Probe** → Helps slow-start apps.

---

## 14. Sidecar & Init Containers (Easy)

### **Sidecar Container**

Helper container in same pod.
Example: logging agent.

### **Init Container**

Runs before main container.
Example: wait for database to start.

---

## 15. DaemonSet

Runs one pod on every node.
Used for monitoring, logging, networking.

---

## 16. Deployment Strategies (Easy)

* **Rolling Update** → Safest. Updates pods slowly.
* **Recreate** → Deletes all, then adds new (downtime).
* **Blue/Green** → Two versions, switch traffic.
* **Canary** → Test new version with small traffic.

---

## 17. Logs & Monitoring

```
kubectl logs -f <pod>
kubectl top pod
kubectl top node
```

Use Google Cloud Logging for full logs.

---

## 18. Very Easy Troubleshooting

### **Pod Pending**

* Not enough resources → add more nodes.
* NodeSelector mismatch.

### **ImagePullBackOff**

* Wrong image name.
* No permission to pull image.

### **CrashLoopBackOff**

* App error.
* Liveness probe killing pod.
* Pod needs more resources.

### **OOMKilled**

* Pod used more memory than limit.

### **Frontend cannot reach backend**

Check:

```
kubectl exec -it frontend -- curl backend:8080
```

Check service name, ports, network policies.

---

## 19. Real-Time Troubleshooting (Very Easy Steps)

1. Check pods:

```
kubectl get pods -A
```

2. Check events:

```
kubectl get events --sort-by=.metadata.creationTimestamp
```

3. Check pod logs:

```
kubectl logs -f <pod>
```

4. Describe pod:

```
kubectl describe pod <pod>
```

5. Check node:

```
kubectl get nodes
kubectl describe node <node>
```

6. Network test:

```
kubectl exec -it <pod> -- curl service-name
```

---

## 20. Namespaces (Easy)

```
kubectl create ns dev
kubectl create ns prod
kubectl apply -f app.yaml -n dev
```

---

## 21. Rollback Deployment

```
kubectl rollout undo deployment app
```

---

## 22. Commands Used Daily

```
kubectl get pods
kubectl get nodes
kubectl logs -f pod
kubectl describe pod
kubectl exec -it pod -- bash
kubectl top pods
kubectl apply -f file.yaml
```

---

## 23. Azure from GKE (Very Easy)

1. Create Azure service principal.
2. Store Azure client ID + secret in GKE secret.
3. Pod uses those values to access Azure service.
4. Test using curl from pod.

---

## 24. GKE Upgrade (Easy)

```
gcloud container clusters upgrade <cluster>
gcloud container node-pools upgrade <pool> --cluster <cluster>
```

---

## 25. Final Notes

* Use probes.
* Always set requests & limits.
* Use Workload Identity.
* Monitor logs.
* Use ingress for real applications.

---

Tell me if you want this:

* As **PDF**
* As **One-page notes**
* As **Interview Q&A style**

---

# Extra Section: Very Easy English Answers for Common K8S & GKE Interview Questions

## 1. Kubernetes Architecture – Easy Explanation

* **Control Plane** → Brain of Kubernetes

  * API Server → Accepts commands
  * etcd → Stores cluster data
  * Scheduler → Chooses node for pod
  * Controller Manager → Keeps cluster healthy
* **Worker Nodes** → Where pods run

  * Kubelet → Runs containers
  * Kube-proxy → Networking
  * Container Runtime → Runs containers (containerd)

**How it works:** You apply YAML → API Server → Scheduler picks node → Kubelet runs pod → Node serves traffic.

---

## 2. Stateless vs StatefulSets (Easy)

* **Stateless (Deployment):** No data saving. New pod can run anywhere.
* **StatefulSet:** Pod name fixed (pod-0, pod-1). Keeps data. Used for databases.

---

## 3. LoadBalancer vs Ingress

* **LoadBalancer:** One external IP for one service.
* **Ingress:** One external IP for many services + HTTPS + routing.

---

## 4. Drain & Cordon

* **Cordon:** Node is marked "No new pods".
* **Drain:** Remove all pods safely from node.

## Cordon and Drain in Kubernetes (GKE)

## Cordon
Cordon marks a Kubernetes node as **Unschedulable**.  
This means **no new pods** will be scheduled on that node, but existing pods continue running.

### Key Points
- Stops new pods from being scheduled.
- Existing pods remain running.
- Used before maintenance, debugging, or upgrades.

### Command
```bash
kubectl cordon <node-name>
```
# Drain in Kubernetes

## Drain
Drain safely evicts all pods from a node, making the node empty and ready for maintenance or replacement.

## What Drain Does
- Evicts pods and reschedules them to other healthy nodes.
- Respects PodDisruptionBudgets (PDB).
- Ignores DaemonSets.
- Can delete unmanaged pods when forced.

## Command
```bash
kubectl drain <node-name> --ignore-daemonsets --force --delete-emptydir-data
```

---

## 5. Deploy Pod on Specific Node

Ways:

* nodeSelector
* nodeAffinity
* Taints/Tolerations
* nodeName

---

## 6. ReplicaSet vs Deployment

* **ReplicaSet:** Only maintains number of pods.
* **Deployment:** Adds rollout, rollback, versioning.

---

## 7. Check Pod Live Logs

```
kubectl logs -f <pod>
kubectl logs -f <pod> -c <container>
```

---

## 8. Commands to Check Nodes

```
kubectl get nodes
kubectl describe node <node>
kubectl top nodes
```

---

## 9. HPA vs VPA

* **HPA:** Adds more pods when CPU/mem high.
* **VPA:** Increases CPU/memory of the same pod.

---

## 10. Pod Disruption Budget (PDB)

Ensures minimum pods stay running during maintenance.

```
minAvailable: 2
```

---

## 11. Health Probes (Simple)

* **Liveness:** Restart if unhealthy.
* **Readiness:** Don’t send traffic until ready.
* **Startup:** Helps slow apps.

---

## 12. Affinity / Anti-Affinity

* **Affinity:** Pods want to be together on same node.
* **Anti-Affinity:** Pods should NOT be on same node.

---

## 13. DaemonSet

Runs 1 pod on each node. Used for logs, monitoring, networking agents.

---

## 14. Check Live Logs of Running App

```
kubectl logs -f pod
```

---

## 15. Troubleshoot Frontend → Backend

1. Check backend service name
2. Test using:

```
kubectl exec -it frontend -- curl backend:8080
```

3. Check port, targetPort
4. Check NetworkPolicy
5. Check logs

---

## 16. Node Down: Will Pods Run?

* Pods on that node stop.
* If Deployment exists → new pods run on other nodes.

---

## 17. Ingress Controller Logs

```
kubectl logs -n ingress-nginx -f <controller-pod>
```

---

## 18. Pod Restarting Continuously (CrashLoopBackOff)

Reasons:

* App crash
* Liveness probe wrong
* Not enough memory
* Wrong env vars

Troubleshoot:

```
kubectl logs pod
kubectl describe pod
```

---

## 19. ImagePullBackOff

Reasons:

* Wrong image/tag
* No pull secret

Fix:

```
kubectl create secret docker-registry...
```

---

## 20. Pod Using High CPU/Memory

Fix:

* Add HPA
* Add VPA
* Increase limits
* Use bigger node

---

## 21. Multiple Namespaces

```
kubectl create ns dev
kubectl create ns prod
```

Deploy:

```
kubectl apply -f app.yaml -n dev
```

---

## 22. GKE → Access Azure Services (Easy Steps)

1. Create Azure AD App
2. Create Secret / Client ID / Client Secret
3. Store in GKE Secret
4. Pod reads secret and connects to Azure service

---

## 23. GKE Service Account

Used by pods to access Google APIs.
Used for Workload Identity.

---

## 24. GKE Cluster Update

```
gcloud container clusters upgrade <cluster>
```

---

## 25. Manifest Files

YAML files used to define:

* Deployment
* Service
* Ingress
* ConfigMap
* Secret
* HPA
* Namespace

---

## 26. Helm Charts (Very Easy)

Helm = Kubernetes package manager.
You run:

```
helm install myapp ./chart
```

It installs many YAML files at once.

---

## 27. Deployment Strategies (Easy)

* Rolling Update → No downtime
* Recreate → Full downtime
* Blue/Green → Two versions
* Canary → Small % traffic to new version

---

## 28. Services in Kubernetes

* ClusterIP → Inside cluster only
* NodePort → Exposed on node
* LoadBalancer → External traffic
* Headless → No cluster IP

---

## 29. Rollback Deployment

```
kubectl rollout undo deployment/app
```

---

## 30. Rollback From v2 → v1

```
kubectl rollout undo deployment/app
```

---

## 31. Check Pod CPU/Memory

```
kubectl top pod
kubectl top node
```

---

## 32. Daily Used K8S Commands

```
kubectl get pods
kubectl get nodes
kubectl logs -f pod
kubectl describe pod
kubectl exec -it pod -- bash
kubectl apply -f file.yaml
kubectl delete pod
kubectl top pods
```

---

