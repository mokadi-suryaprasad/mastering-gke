# 🧩 Day 07 — DaemonSets, Prometheus, Grafana, EFK, and Jaeger

---

## 🎯 Learning Objectives

By the end of this lesson, you will clearly understand:

- What is a **DaemonSet** in Kubernetes.
- How **Prometheus** and **Grafana** help in monitoring.
- How the **EFK Stack (Elasticsearch, Fluentd, Kibana)** helps in logging.
- How **Jaeger** helps in distributed tracing.
- How all these tools work together in a real Kubernetes environment.

---

## 🌀 1. What is a DaemonSet?

A **DaemonSet** ensures that **one copy of a Pod runs on every node** in the Kubernetes cluster.  
If new nodes are added, Kubernetes automatically schedules the DaemonSet Pod on them too.  
If nodes are removed, the Pods are automatically cleaned up.

### ✅ Example Use Cases

- **Fluentd** – for collecting logs from every node.  
- **Node Exporter** – for collecting metrics from every node.  
- **Jaeger Agent** – for tracing requests in each node.  
- **Security Agents** – like Falco for runtime security.

### 🧩 Diagram: DaemonSet Concept

+---------------------------------------------+
| Kubernetes Cluster |
+---------------------------------------------+

| Node 1                                          | Node 2 | Node 3 | Node 4 |
| ----------------------------------------------- | ------ | ------ | ------ |
| Pod                                             | Pod    | Pod    | Pod    |
| (DS)                                            | (DS)   | (DS)   | (DS)   |
| +---------------------------------------------+ |        |        |        |


👉 **DaemonSet automatically ensures one Pod per node.**

---

## 📊 2. Prometheus and Grafana — Monitoring Stack

Monitoring is one of the most important parts of DevOps and cloud management.

### 🔍 What is Prometheus?

**Prometheus** is an open-source **monitoring system**.  
It collects **metrics** (numbers and statistics) from your applications, pods, and nodes.  
It uses a **pull-based model**, meaning it **pulls metrics** from applications that expose data on `/metrics` endpoints.

Prometheus stores this data in a **time-series database** — data stored over time, like:
- CPU usage over time  
- Memory usage over time  
- Request rate per second

### 📈 What is Grafana?

**Grafana** is a **visualization and dashboard tool**.  
It connects to Prometheus (and other data sources) and shows the metrics in beautiful charts and dashboards.

You can create graphs, alerts, and dashboards to visualize what’s happening inside your system.

---

### ⚙️ Prometheus + Grafana Working Flow

1. **Applications** or **Node Exporters** expose metrics on `/metrics`.
2. **Prometheus** scrapes those metrics at regular intervals.
3. **Grafana** connects to Prometheus to show the data in graphs.

---

### 🧩 Prometheus + Grafana Architecture Diagram

+-----------------------------+
| Grafana UI |
| (Dashboards & Alerts) |
+-------------+---------------+
|
v
+-------------+---------------+
| Prometheus |
| (Collects & Stores Metrics) |
+-------------+---------------+
|
v
+-------------+---------------+
| Node Exporters / App Metrics|
| (Expose /metrics endpoints) |
+-----------------------------+


---

### 🧠 Example Metrics You Can Monitor

| Type | Example |
|------|----------|
| Node | CPU, Memory, Disk, Network |
| Pod | Container restarts, resource usage |
| Application | Request rate, errors, latency |

---

## 🪵 3. EFK Stack — Logging Solution

The **EFK Stack** is used to collect, store, and view logs in Kubernetes.  
It includes:

| Tool | Description |
|------|--------------|
| **Elasticsearch** | Stores and indexes logs so you can search them. |
| **Fluentd** | Collects logs from each Pod and sends them to Elasticsearch. |
| **Kibana** | Visual tool to view and analyze the logs. |

---

### 🔧 How It Works

1. **Fluentd** runs as a **DaemonSet** on every node.  
2. It reads container logs from `/var/log/containers/`.  
3. Fluentd sends those logs to **Elasticsearch**.  
4. **Kibana** connects to Elasticsearch and shows logs in the web UI.

---

### 🧩 EFK Stack Architecture Diagram

+------------------------------+
| Kibana |
| (Visualize & Search Logs) |
+--------------+---------------+
|
v
+--------------+---------------+
| Elasticsearch |
| (Stores and Indexes Logs) |
+--------------+---------------+
^
|
+--------------+---------------+
| Fluentd DaemonSet |
| (Collect Logs from Nodes) |
+--------------+---------------+
^
|
+--------------+---------------+
| Kubernetes Nodes & Pods |
| (Generate Application Logs) |
+------------------------------+


---

### 🧠 Example Use Cases

- View Pod logs in Kibana instead of using `kubectl logs`.
- Filter logs by namespace, service, or error keywords.
- Monitor failed pods or error trends over time.

---

## 🔍 4. Jaeger — Distributed Tracing

### 🌐 What is Jaeger?

**Jaeger** is a **distributed tracing system**.  
It helps track the flow of requests across multiple **microservices**.  
This is very useful when one request passes through many services — for example:

> Frontend → Auth Service → Payment Service → Notification Service

You can use Jaeger to **trace how long each service took** and find **bottlenecks** or **failures**.

---

### 🧩 Jaeger Architecture Diagram

+------------------------------+
| Jaeger UI |
| (View Traces) |
+--------------+---------------+
|
v
+--------------+---------------+
| Query Service |
| (Fetch trace data) |
+--------------+---------------+
|
v
+--------------+---------------+
| Collector Service |
| (Receives spans & traces) |
+--------------+---------------+
^
|
+--------------+---------------+
| Jaeger Agent DaemonSet |
| (Receives traces from Apps) |
+--------------+---------------+
^
|
+--------------+---------------+
| Instrumented Applications |
| (Send Trace Data) |
+------------------------------+


---

### 🧠 Example Use Cases

- Find which microservice is slowing down your request.  
- Check if all services are working properly in a chain.  
- Visualize request flow between services.

---

## ⚙️ 5. How DaemonSets Are Used in Monitoring and Logging

| Tool | Role in DaemonSet |
|------|-------------------|
| **Fluentd** | Runs as DaemonSet to collect logs from all nodes. |
| **Node Exporter** | Runs as DaemonSet to collect system metrics. |
| **Jaeger Agent** | Runs as DaemonSet to collect traces from local services. |

DaemonSets ensure that **every node** has a **collector agent**, so **no logs or metrics are missed**.

---

## 🌐 6. Combined Architecture (High-Level Overview)

                        +------------------------+
                        |       Grafana          |
                        | (Visualize Metrics)    |
                        +-----------+------------+
                                    |
                                    v
                        +-----------+------------+
                        |       Prometheus       |
                        | (Scrape Metrics)       |
                        +-----------+------------+
                                    |
                 +------------------+------------------+
                 |   Node Exporters / App Metrics       |
                 |   (DaemonSet on all nodes)           |
                 +------------------+------------------+
                                    |
                                    |
    +------------------------------------------------------------+
    |                      Kubernetes Cluster                    |
    |                                                            |
    |  +----------------+     +----------------+   +-------------+|
    |  |   Fluentd DS   | --> | Elasticsearch  | <-|   Kibana    ||
    |  +----------------+     +----------------+   +-------------+|
    |                                                            |
    |    ↑ Collect Logs                              Show Logs ↓  |
    +------------------------------------------------------------+
                                    |
                                    v
                        +------------------------+
                        |        Jaeger          |
                        | (Distributed Tracing)  |
                        +------------------------+


---

## 🧠 7. Summary

| Concept | Description |
|----------|-------------|
| **DaemonSet** | Ensures one Pod per node for monitoring/logging/tracing. |
| **Prometheus** | Collects and stores metrics. |
| **Grafana** | Visualizes metrics in dashboards. |
| **Fluentd** | Collects logs from all nodes. |
| **Elasticsearch** | Stores logs and makes them searchable. |
| **Kibana** | Visualizes logs in a web UI. |
| **Jaeger** | Traces requests across microservices. |

---

## 🚀 8. Practical Example (Typical Setup)

In a real Kubernetes cluster:
- **Fluentd** DaemonSet → Collects logs  
- **Prometheus** → Collects metrics  
- **Grafana** → Displays dashboards  
- **Jaeger** → Traces requests across services  

Together, they provide **Complete Observability**:
> **Metrics + Logs + Traces**

---

## 🧩 Conclusion

- **DaemonSets** are powerful for running agents on every node.  
- **Prometheus + Grafana** monitor the health and performance of your cluster.  
- **EFK Stack** manages and visualizes logs easily.  
- **Jaeger** provides complete visibility into microservice request flows.  

👉 These tools together help DevOps teams **detect issues faster**, **improve system reliability**, and **maintain healthy clusters**.

---

