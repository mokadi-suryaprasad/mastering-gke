# 🛡️ Day 23 — Continuous Security: Image Scanning & Policy Enforcement

### Tools: Trivy & Kyverno

Modern Kubernetes deployments need **continuous security**:  
- Scan container images for vulnerabilities  
- Enforce policies for compliance and security best practices  
- Automate remediation before deployment  

---

## 🎯 Learning Objectives
By the end of this session, you will:  
- Scan Docker/K8s images for vulnerabilities using **Trivy**  
- Enforce security policies with **Kyverno**  
- Automate image scanning and policy enforcement in CI/CD pipelines  
- Prevent insecure configurations from being deployed  

---

## ⚙️ 1. Trivy — Container Image Scanning

**Install Trivy:**
```bash
brew install trivy    # macOS
# or Linux
sudo apt install trivy
```

**Scan an image for vulnerabilities:**
```bash
trivy image nginx:1.21
```

**Generate report:**
```bash
trivy image --format json -o trivy-report.json nginx:1.21
```

**Integrate with CI/CD:**  
- Fail the pipeline if critical vulnerabilities exist  
- Use JSON, SARIF, or HTML reports for automation  

---

## 🧱 2. Kyverno — Policy Enforcement

**Install Kyverno in Kubernetes:**
```bash
kubectl create namespace kyverno
kubectl apply -f https://raw.githubusercontent.com/kyverno/kyverno/main/config/release/install.yaml
```

**Example Policy: Disallow containers running as root**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-root-user
spec:
  validationFailureAction: enforce
  rules:
    - name: check-root-user
      match:
        resources:
          kinds:
            - Pod
      validate:
        message: "Running as root is not allowed"
        pattern:
          spec:
            containers:
              - securityContext:
                  runAsNonRoot: true
```

**Test Policy:**
```bash
kubectl apply -f kyverno/pod-with-root.yaml
# Should be rejected by Kyverno
```

---

## 🔄 3. CI/CD Integration

1. **Scan images before deployment** with Trivy  
2. **Enforce Kubernetes policies** with Kyverno  
3. **Fail the pipeline** if checks do not pass  

**Example GitHub Actions step:**
```yaml
- name: Scan Docker image with Trivy
  run: trivy image --exit-code 1 --severity CRITICAL,HIGH myimage:latest
```

Kyverno admission controller automatically **blocks non-compliant resources**.

---

## 🧠 Key Takeaways
- **Trivy** detects vulnerabilities in container images  
- **Kyverno** enforces Kubernetes policies  
- Together, they **prevent insecure workloads** from running  
- Integrates seamlessly into **CI/CD pipelines** for proactive security  

---
