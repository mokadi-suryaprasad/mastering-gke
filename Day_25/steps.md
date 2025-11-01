# Istio Bookinfo Full Working Setup

## ✅ 1. Download & Install Istio CLI

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.27.3 sh -
cd istio-1.27.3
export PATH="$PATH:$(pwd)/bin"
```

---

## ✅ 2. Install Istio Control Plane

```bash
istioctl install --set profile=demo -y
```

Verify:

```bash
kubectl get pods -n istio-system
```

---

## ✅ 3. Enable Sidecar Injection

```bash
kubectl label namespace default istio-injection=enabled --overwrite
```

---

## ✅ 4. Deploy Bookinfo Sample Application

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

Verify:

```bash
kubectl get pods -n default
kubectl get svc -n default
```

---

## ✅ 5. Apply Bookinfo Gateway

```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl get gateway -n default
```

---

## ✅ 6. Delete Auto-Created VirtualServices (To Avoid Conflict)

```bash
kubectl delete virtualservice details productpage reviews ratings -n default || true
kubectl get virtualservice -n default
```

---

## ✅ 7. Apply Consolidated VirtualService (All v1)

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl get virtualservice -n default
```

---

## ✅ 8. Create DestinationRule for Reviews

Create file: `destinationrule-reviews.yaml`

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: reviews
  namespace: default
spec:
  host: reviews
  subsets:
    - name: v1
      labels:
        version: v1
    - name: v2
      labels:
        version: v2
```

Apply:

```bash
kubectl apply -f destinationrule-reviews.yaml
kubectl get destinationrule -n default
```

---

## ✅ 9. Create VirtualService for Reviews 80/20 Traffic Split

Create file: `virtualservice-reviews-80-20.yaml`

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
  namespace: default
spec:
  hosts:
    - reviews
  gateways:
    - bookinfo-gateway
  http:
    - route:
        - destination:
            host: reviews
            subset: v1
          weight: 80
        - destination:
            host: reviews
            subset: v2
          weight: 20
```

Apply:

```bash
kubectl apply -f virtualservice-reviews-80-20.yaml
kubectl get virtualservice reviews -n default
```

---

## ✅ 10. Test App Using Port Forward

```bash
kubectl port-forward svc/bookinfo-gateway-istio 8080:80 -n default
```

Open in browser:

```
http://localhost:8080/productpage
```

---

## ✅ 11. Optional: Redirect `/` to `/productpage`

Create file: `root-redirect.yaml`

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: root-redirect
  namespace: default
spec:
  hosts:
    - "*"
  gateways:
    - bookinfo-gateway
  http:
    - match:
        - uri:
            exact: /
      redirect:
        uri: /productpage
```

Apply:

```bash
kubectl apply -f root-redirect.yaml
```

---

## ✅ 12. Troubleshooting Commands

Check VS/Gateway binding:

```bash
kubectl get virtualservice -n default -o wide
kubectl get gateway -n default -o wide
```

Check from inside pod:

```bash
POD=$(kubectl get pod -n default -l app=productpage -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n default $POD -- curl -sS http://reviews:9080
```

---

## ✅ 13. Cleanup

```bash
kubectl delete -f virtualservice-reviews-80-20.yaml
kubectl delete -f destinationrule-reviews.yaml
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
istioctl x uninstall --purge -y
kubectl delete namespace istio-system --force --grace-period=0 || true
```

---


