# Istio Bookinfo Deployment - Step-by-Step Guide (steps.md)

## ✅ 01 - Install Istio

```bash
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.27.3
export PATH="$PWD/bin:$PATH"
```

Install Istio using demo profile:

```bash
istioctl install --set profile=demo -y
```

Verify installation:

```bash
kubectl get pods -n istio-system
```

---

## ✅ 02 - Enable Sidecar Injection

Enable injection for the default namespace:

```bash
kubectl label namespace default istio-injection=enabled
```

Verify:

```bash
kubectl get ns --show-labels
```

---

## ✅ 03 - Deploy Bookinfo Application

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

Verify pods:

```bash
kubectl get pods -n default
```

---

## ✅ 04 - Deploy Istio Gateway

```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

Check gateway:

```bash
kubectl get gateway -n default
```

---

## ✅ 05 - Deploy VirtualService

```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-virtual-service.yaml
```

Check VS:

```bash
kubectl get virtualservice -n default
```

---

## ✅ 06 - Port Forward Gateway

Forward port 8080 to access Bookinfo locally:

```bash
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
```

Or if using your own gateway svc:

```bash
kubectl port-forward svc/bookinfo-gateway-istio 8080:80 -n default
```

---

## ✅ 07 - Test Endpoints

Open in browser:

```
http://localhost:8080/productpage
```

Or test using curl:

```bash
curl http://localhost:8080/productpage -I
```

---

## ✅ 08 - Apply Traffic Rules

### ✅ Route 100% traffic to reviews-v1

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-v1.yaml
```

### ✅ Split traffic 50% v1 and 50% v2

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v1-v2.yaml
```

### ✅ Send traffic to v2 only for user "jason"

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-jason-v2.yaml
```

---

## ✅ Verification

```bash
kubectl get virtualservice reviews -n default -o yaml
```

Keep refreshing:

```
http://localhost:8080/productpage
```

You should see routing changes (stars, no stars, red stars depending on version).

---

## ✅ Cleanup

```bash
kubectl delete -f samples/bookinfo/networking/
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
```
