# Service Mesh — Work Flow (Step‑by‑Step)

This file explains, in clear step-by-step sequence, how traffic flows through a Service Mesh (Istio + Envoy sidecars). It covers: Pod startup & sidecar injection, iptables redirection, outgoing request flow, mTLS handshake, incoming request handling, response flow, control-plane config push, telemetry, and basic troubleshooting checks.

---

## 1. Pod Creation & Sidecar Injection

1. Developer deploys a Deployment/Pod manifest to Kubernetes.
2. If automatic injection is enabled (`kubectl label ns default istio-injection=enabled`), the Istio **MutatingAdmissionWebhook** intercepts the Pod creation request.
3. The webhook modifies the Pod spec and adds the Envoy sidecar container and init container (responsible for iptables setup). The modified Pod is persisted to etcd and scheduled.
4. Pod starts: init container runs first and configures iptables rules to redirect traffic to Envoy. Then the application container and Envoy sidecar start.

**Commands to inspect:**

* `kubectl get pods -n <ns>`
* `kubectl get pod <pod> -o yaml` (see `containers` and `initContainers`)
* `kubectl logs <pod> -c istio-proxy -n <ns>`

---

## 2. iptables Redirection (How App Traffic Is Captured)

1. The init container writes iptables rules that redirect pod network traffic to the Envoy's listener ports (commonly `15001` for outbound and `15006` for inbound depending on Istio version).
2. App traffic to external addresses or cluster services is intercepted and delivered to Envoy instead of leaving the pod directly.

**Common checks:**

* `kubectl exec -it <pod> -c istio-proxy -- iptables-save` (view rules)
* `kubectl exec -it <pod> -- netstat -tlnp` (see listening ports)

---

## 3. Outgoing Request Flow (App → Sidecar → Mesh → Remote Sidecar)

1. **App sends request** to `http://service-b:8080` (or an IP).
2. Because of iptables, the request is redirected to **Envoy sidecar A**.
3. Envoy A consults its configuration (pushed by Istiod) to determine routing, retries, and policies.
4. If mTLS is enabled, Envoy A performs a TLS handshake using its workload certificate (issued by Istio CA). It encrypts the request and sends it across the network to the remote sidecar.
5. Envoy A may apply timeouts, header transformations, rate-limiting checks, and load-balancing before sending.

**Commands to observe:**

* `istioctl proxy-status` (shows Envoy connectivity to control plane)
* `kubectl logs <pod> -c istio-proxy` (Envoy logs show routing decisions)

---

## 4. mTLS Handshake & Certificate Use

1. Each Envoy has an identity certificate issued by Istio (from `istiod` or external CA).
2. When Envoy A connects to Envoy B, it initiates a mutual TLS handshake:

   * Both sides present their certificates.
   * Certificates are verified against the trust root.
   * A symmetric session key is negotiated; payloads are encrypted.
3. After successful handshake, encrypted HTTP (usually HTTP/2) flows between Envoys.

**Verify mTLS:**

* `kubectl get peerauthentication -A` (check PeerAuthentication policy)
* Use Kiali or `istioctl authn tls-check <pod>` (older istioctl versions) to inspect TLS status.

---

## 5. Incoming Request Flow (Remote Sidecar → Envoy B → App B)

1. **Envoy B** receives the encrypted request and completes the mTLS handshake if not already done.
2. Envoy B decrypts the request and validates policies (AuthorizationPolicy, RequestAuthentication for JWT, etc.).
3. If valid, Envoy B routes the request to the local application container (App B) via localhost.
4. The application receives a normal, decrypted HTTP request and processes it.

**Checks:**

* `kubectl exec -it <pod-b> -c istio-proxy -- curl -v localhost:<app-port>` (hit app via sidecar)
* Kiali shows traffic flows and mTLS icons between services.

---

## 6. Response Flow (App B → Envoy B → Mesh → Envoy A → App A)

1. App B generates an HTTP response and sends it to its local Envoy B.
2. Envoy B may apply response filters, telemetry, and policy checks, then encrypts the response with mTLS and sends it back to Envoy A.
3. Envoy A decrypts the response, applies any response-level rules, and forwards the result to App A.
4. App A receives the final response as if it came directly from App B.

**Notes:** retries/timeouts are applied on the request path by the caller’s Envoy; Envoy will retry upstream when configured.

---

## 7. Control Plane: Config Distribution & Policy Enforcement

1. `istiod` (control plane) holds the desired configuration: VirtualServices, DestinationRules, AuthorizationPolicies, PeerAuthentication, EnvoyFilters.
2. Istiod converts Kubernetes CRDs into Envoy xDS configuration and pushes them to sidecars over a secure channel (xDS API).
3. Envoy hot-reloads configuration without restarting the proxy; new routing/policies take effect quickly.

**Commands:**

* `kubectl get virtualservice,destinationrule,authorizationpolicy -A`
* `istioctl proxy-config routes <pod> -n <ns>` (view route config on a sidecar)

---

## 8. Telemetry: Metrics, Logs, Traces

1. Envoy exports stats and traces to Prometheus, Grafana, Jaeger, and Kiali (depending on installation).
2. Traces include the entire request path (typically using distributed tracing headers such as `x-request-id`, `x-b3-*`, or `traceparent`).
3. Logs and metrics are gathered from Envoy and application containers for observability.

**Check telemetry:**

* `kubectl port-forward svc/kiali -n istio-system 20001:20001` then open Kiali.
* Use Prometheus and Grafana dashboards for latency/error metrics.

---

## 9. Common Troubleshooting Steps

1. **No traffic observed**: Ensure sidecar injection is enabled for the namespace and pods have `istio-proxy` container.

   * `kubectl get pods -n <ns> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].name}{"\n"}{end}'`
2. **mTLS failures**: Check PeerAuthentication and DestinationRule settings; verify workload certs.

   * `kubectl describe secret istio.<workload>-cert -n <ns>` (certificate secrets)
3. **Routing not applied**: Check VirtualService/DestinationRule and `istioctl proxy-config` on the sidecar.
4. **Rate-limiting or policies blocking traffic**: Inspect Envoy logs and Istio AuthorizationPolicy.
5. **Envoy control plane issues**: `istioctl proxy-status` and `kubectl logs -n istio-system deploy/istiod`.

---

## 10. Useful Commands Summary

* `kubectl get pods -n <ns>`
* `kubectl get pod <pod> -o yaml -n <ns>`
* `kubectl logs <pod> -c istio-proxy -n <ns>`
* `kubectl exec -it <pod> -c istio-proxy -- iptables-save`
* `istioctl proxy-status`
* `istioctl proxy-config clusters <pod> -n <ns>`
* `istioctl authn tls-check <pod> -n <ns>` (may vary by istioctl version)
* `kubectl port-forward svc/kiali -n istio-system 20001:20001`

---

✅ FULL SERVICE MESH TRAFFIC FLOW

``` text

                    ┌──────────────────────────────────────────┐
                    │                Client / User              │
                    └───────────────┬──────────────────────────┘
                                    │ 1. Hit DNS / LB IP
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │     External Load Balancer (GCLB/ELB)    │
                    └───────────────┬──────────────────────────┘
                                    │ 2. Forward request
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │       Istio Ingress Gateway (Envoy)      │
                    └───────────────┬──────────────────────────┘
                                    │ 3. Apply Gateway + VS rules
                                    ▼
                      Incoming Traffic to UI Service
             ┌────────────────────────────────────────────────────────┐
             │                        Namespace                       │
             └───────────────────────┬────────────────────────────────┘
                                     │ 4. Routed to UI
                                     ▼
                    ┌──────────────────────────────────────────┐
                    │         UI Pod (2 containers)            │
                    │ ┌──────────────────────────────────────┐ │
                    │ │        UI Sidecar (Envoy Proxy)      │ │
                    │ └──────────────────────────────────────┘ │
                    │ ┌──────────────────────────────────────┐ │
                    │ │        UI App Container              │ │
                    │ └──────────────────────────────────────┘ │
                    └───────────────┬──────────────────────────┘
                                    │ 5. UI app → UI sidecar
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │       UI Sidecar (Envoy Proxy)           │
                    └───────────────┬──────────────────────────┘
                                    │ 6. mTLS → Cart sidecar
                                    ▼
                      Internal Mesh Traffic to Cart Service
                    ┌──────────────────────────────────────────┐
                    │        Cart Pod (2 containers)           │
                    │ ┌──────────────────────────────────────┐ │
                    │ │     Cart Sidecar (Envoy Proxy)        │ │
                    │ └──────────────────────────────────────┘ │
                    │ ┌──────────────────────────────────────┐ │
                    │ │        Cart App Container            │ │
                    │ └──────────────────────────────────────┘ │
                    └───────────────┬──────────────────────────┘
                                    │ 7. Request delivered
                                    ▼
                          ┌──────────────────────┐
                          │   Cart Container     │
                          └──────────────────────┘
                                    │
                        OUTGOING RESPONSE FLOW (Reverse)
                                    │ 8. Response → Cart sidecar
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │       Cart Sidecar (Envoy Proxy)         │
                    └───────────────┬──────────────────────────┘
                                    │ 9. mTLS → UI sidecar
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │        UI Sidecar (Envoy Proxy)          │
                    └───────────────┬──────────────────────────┘
                                    │ 10. Response → UI App
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │          UI Container                    │
                    └───────────────┬──────────────────────────┘
                                    │ 11. UI App renders page
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │        UI Sidecar (Envoy Proxy)          │
                    └───────────────┬──────────────────────────┘
                                    │ 12. Response → Gateway
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │         Istio Ingress Gateway            │
                    └───────────────┬──────────────────────────┘
                                    │ 13. To LoadBalancer
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │        External Load Balancer            │
                    └───────────────┬──────────────────────────┘
                                    │ 14. Return to client
                                    ▼
                    ┌──────────────────────────────────────────┐
                    │               Client/User                 │
                    └──────────────────────────────────────────┘

```

## Service Mesh Traffic Workflow (Step-by-Step)

Below is the clear, numbered, production-accurate workflow that matches the text diagram you provided. This explains exactly how traffic flows **from Client → UI → Cart → UI → Client** inside an Istio Service Mesh.

---

### ✅ 1. Client hits DNS / LoadBalancer

The user enters the application URL. DNS resolves it to a public LoadBalancer IP.

* Browser sends HTTP/HTTPS request to LoadBalancer.

---

### ✅ 2. LoadBalancer forwards request to Ingress Gateway

Cloud LB (GCLB/ELB) forwards traffic to the Istio Ingress Gateway Service.

---

### ✅ 3. Istio Ingress Gateway receives request and applies routing rules

Ingress Gateway Envoy applies:

* Gateway rules
* VirtualService routing
* TLS termination
* JWT policies
* Rate-limiting

If valid → forwarded to UI Service.

---

### ✅ 4. Request routed to UI Pod (Envoy Sidecar first)

Request is forwarded to the UI Pod **Envoy sidecar**, not directly to the app container.

---

### ✅ 5. UI Sidecar → UI Application

UI sidecar validates, decrypts (if mTLS), and sends request to UI app container on localhost.

---

### ✅ 6. UI Application wants to call Cart Service

UI app sends an HTTP request to Cart.
iptables inside pod **redirects all traffic to the UI sidecar**.

---

### ✅ 7. UI Sidecar → Cart Sidecar (mTLS encrypted)

UI sidecar opens an mTLS session to Cart sidecar.

* Identity verified
* Traffic encrypted
* Routing rules applied

---

### ✅ 8. Cart Sidecar → Cart Application

Cart Envoy decrypts and forwards the request to Cart app container.

---

### ✅ 9. Cart Application processes request and returns response

Cart app prepares response and sends it to local Envoy sidecar.

---

### ✅ 10. Cart Sidecar → UI Sidecar (response path)

Cart Envoy encrypts (mTLS) and sends the response back to UI sidecar.

---

### ✅ 11. UI Sidecar → UI Application

UI Envoy decrypts the response and passes it to the UI app.

UI app generates final HTML/JSON page for the user.

---

### ✅ 12. UI Application → UI Sidecar (egress)

UI app cannot send response directly to the outside.
iptables → sends all outbound traffic to UI sidecar.

---

### ✅ 13. UI Sidecar → Istio Ingress Gateway

UI Envoy forwards response to Ingress Gateway.

---

### ✅ 14. Ingress Gateway → LoadBalancer → Client

Finally, the response is:

* Sent to LoadBalancer
* Returned to the client browser

User receives page/API response.

---


