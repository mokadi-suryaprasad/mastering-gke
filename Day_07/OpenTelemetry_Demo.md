# ☁️ OpenTelemetry Demo on GKE with Full Observability

This guide explains how to deploy the **OpenTelemetry Microservices Demo** on **Google Kubernetes Engine (GKE)** with complete observability using **Prometheus**, **Grafana**, **Jaeger**, and optional **EFK Stack**.  
It also includes **Node Exporter** and **Kube-State-Metrics** for node and cluster-level insights.

---

## 🧩 Overview

The OpenTelemetry Demo is a microservice-based distributed application that helps demonstrate observability concepts in a real-world environment.

### 🧠 Components in the Demo:
| Component | Purpose |
|------------|----------|
| OpenTelemetry Collector | Collects and exports traces, metrics, and logs |
| Prometheus | Collects metrics from apps and nodes |
| Grafana | Visualizes metrics and dashboards |
| Jaeger | Traces distributed transactions |
| Web Store | Sample microservice app |
| Load Generator | Simulates traffic for observability |
| Feature Flags | Enables dynamic features |
| Node Exporter | Collects node-level metrics (CPU, Memory, Disk) |
| Kube-State-Metrics | Monitors cluster objects |
| EFK Stack (Optional) | Collects and visualizes logs |

---

## 🚀 Step 1 — Install OpenTelemetry Demo

Add the Helm repository and install the demo:

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm install my-otel-demo open-telemetry/opentelemetry-demo
```

Verify that all pods are running:

```bash
kubectl get pods
```

---

## 🌐 Step 2 — Access the Application and Dashboards

Forward the frontend proxy service:

```bash
kubectl port-forward svc/my-otel-demo-frontendproxy 8080:8080
```

Now open the following URLs in your browser:

| Component | URL |
|------------|-----|
| Web Store (Main App) | http://localhost:8080 |
| Grafana | http://localhost:8080/grafana |
| Jaeger | http://localhost:8080/jaeger/ui |
| Feature Flags UI | http://localhost:8080/feature |
| Load Generator UI | http://localhost:8080/loadgen |

Expose the OTLP receiver to collect spans:

```bash
kubectl port-forward svc/my-otel-demo-otelcol 4318:4318
```

---

## ⚙️ Step 3 — Add Node and Cluster Metrics

### Install Node Exporter

To get node-level CPU, memory, disk, and network metrics:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install node-exporter prometheus-community/prometheus-node-exporter
```

### Install Kube-State-Metrics

To collect Kubernetes resource-level metrics:

```bash
helm install kube-state-metrics prometheus-community/kube-state-metrics
```

Check that both services are running:

```bash
kubectl get pods | grep exporter
kubectl get pods | grep metrics
```

---
hen open Grafana in browser:  
👉 http://localhost:3000  
Default credentials:  
```
Username: admin
Password: admin
```

---

## 📈 Step 4: Import Grafana Dashboards

### 🔹 Method 1: Import via Dashboard ID
1. Go to **Grafana → Dashboards → Import**  
2. Enter an **official dashboard ID** (e.g., `1860` for Node Exporter)  
3. Choose your **Prometheus data source**  
4. Click **Import**

### 🔹 Common Dashboard IDs
| Tool | Dashboard ID | Description |
|------|--------------|--------------|
| Node Exporter | 1860 | Node Exporter Full Dashboard |
| Kubernetes Cluster Monitoring | 6417 | Cluster & Pod Metrics |
| OpenTelemetry Collector | 15991 | Collector Metrics |
| Jaeger | 14842 | Distributed Tracing Overview |

### 🔹 Method 2: Import via JSON
1. Export or download a dashboard JSON file  
2. In Grafana, go to **Dashboards → Import → Upload JSON File**  
3. Select the JSON file and your Prometheus data source  
4. Click **Import**

You can find prebuilt dashboards here:  
👉 [https://grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards)

---
## 🪵 Step 4 — (Optional) Enable Logging with EFK Stack

Add the Elastic Helm repo:

```bash
helm repo add elastic https://helm.elastic.co
```

Then install Elasticsearch, Kibana, and Fluent Bit:

```bash
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
helm install fluent-bit fluent/fluent-bit
```

Once done, you can visualize logs in Kibana at:

**http://localhost:5601**

---

## 📊 Step 5 — Common PromQL Queries for Monitoring

Use these queries in **Grafana → Explore → Prometheus**:

| Metric | PromQL Query | Description |
|--------|---------------|-------------|
| **CPU Usage per Node** | `rate(node_cpu_seconds_total{mode!="idle"}[5m])` | CPU utilization per node |
| **Memory Usage** | `node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes` | Used memory |
| **Disk Usage (%)** | `(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100` | Disk utilization percentage |
| **Pod Restarts** | `rate(kube_pod_container_status_restarts_total[5m])` | Pods restarting frequently |
| **Pod Count per Namespace** | `count(kube_pod_info) by (namespace)` | Number of pods in each namespace |
| **HTTP Requests/sec** | `rate(http_server_duration_seconds_count[1m])` | Application request rate |
| **Error Rate (5xx)** | `rate(http_server_duration_seconds_count{status_code=~"5.."}[1m])` | Server error rate |
| **Latency (P95)** | `histogram_quantile(0.95, sum(rate(http_server_duration_seconds_bucket[5m])) by (le))` | 95th percentile latency |
| **Network Usage** | `rate(node_network_receive_bytes_total[5m])` | Network bytes received per node |
| **App Availability** | `sum(up{job="frontend"}) / count(up{job="frontend"})` | Percentage of app instances up |

---

## 🧠 Step 6 — Observability Architecture Diagram

```mermaid
graph TD
    subgraph GKE Cluster
        A[User Traffic] --> B[Frontend Service]
        B --> C[Backend Microservices]
        C --> D[OpenTelemetry Collector]
        D --> E[Prometheus]
        D --> F[Jaeger]
        E --> G[Grafana]
        subgraph Optional
            H[EFK Stack (Elasticsearch + FluentBit + Kibana)]
        end
    end
    G -->|Visualizes Metrics| User1[Grafana UI]
    F -->|Traces Distributed Requests| User2[Jaeger UI]
    H -->|Shows Logs| User3[Kibana UI]
```

---

## ✅ Summary

| Tool | Role | Installed By Default |
|------|------|----------------------|
| **OpenTelemetry Collector** | Collects metrics, logs, and traces | ✅ |
| **Prometheus** | Metrics collection | ✅ |
| **Grafana** | Metrics visualization | ✅ |
| **Jaeger** | Distributed tracing | ✅ |
| **Node Exporter** | Node-level metrics | ❌ (Add manually) |
| **Kube-State-Metrics** | Kubernetes resource metrics | ❌ (Add manually) |
| **EFK Stack** | Centralized logging | ❌ (Optional) |

---

## 🎯 Final Goal

You will have a **complete observability setup** running inside your GKE cluster:

- 🧩 **Traces** from OpenTelemetry → Jaeger  
- 📊 **Metrics** from Prometheus → Grafana  
- 🪵 **Logs** from Fluent Bit → Elasticsearch → Kibana  
- 🔍 **Full visibility** into your microservices performance, reliability, and user behavior.

---

## 📚 References
- [OpenTelemetry Helm Charts](https://github.com/open-telemetry/opentelemetry-helm-charts)
- [Prometheus Community Charts](https://github.com/prometheus-community/helm-charts)
- [Elastic Helm Charts](https://github.com/elastic/helm-charts)
