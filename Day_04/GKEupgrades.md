# GKE Upgrades — End‑to‑End, Interview‑Ready Guide

This guide explains **how GKE upgrades work** (control plane and node pools), **safe rollout patterns**, **commands**, **troubleshooting**, and **what to say in interviews**. It is **release‑channel agnostic** (Stable/Regular/Rapid) and applies to **GKE Standard and Autopilot** (noting key differences).

> TL;DR: Upgrade **control plane first**, then **node pools**, using **surge upgrades** (or **blue/green pools**) and **PodDisruptionBudgets** to protect workload SLOs. Validate, then roll forward. Use **maintenance windows/exclusions** and **release channels** to pace change.

---

## 1) Key Concepts

- **Control plane vs node pools**
  - *Control plane (masters)*: Google‑managed; you pick the version (within channel) and trigger/allow the upgrade.
  - *Node pools*: Your worker nodes. You choose upgrade strategy (surge, blue‑green), taints, and drain behavior.
- **Release channels**: **Stable** (slower, safest), **Regular**, **Rapid** (fastest). Channels auto‑offer newer patch/minor versions.
- **Version skew (rule of thumb)**: Nodes must **not be newer** than the control plane, and should be kept **within one minor** version of it.
- **Upgrade order**: **Control plane ➜ system/node pools ➜ app node pools.**
- **Disruption control**: Use **PodDisruptionBudget (PDB)**, **readiness probes**, **HPA**, **graceful termination**, and **surge/blue‑green** strategies.

---

## 2) Planning an Upgrade

### 2.1 Decide your target version
- Pick from your **release channel’s** available versions.
- Prefer **latest patch** of your current minor (e.g., `1.31.x → 1.31.y`), then plan **minor bumps** (e.g., `1.31 → 1.32`). Avoid skipping multiple minors in one jump.

### 2.2 Check compatibility
- **APIs & deprecations**: Scan for removed APIs, `policy/v1beta1` → `policy/v1`, Ingress `extensions/v1beta1` → `networking.k8s.io/v1`, PodSecurity vs legacy PSP, etc.
- **Images & OS**: Verify **COS/Ubuntu** image families, GPU/TPU drivers, Windows node pools.
- **Add‑ons**: CSI drivers, CNI, Gateway/Ingress, NetworkPolicy controllers, service meshes (Istio), and admission webhooks.
- **Version skew**: Ensure add‑ons and controllers support target minor.

### 2.3 Schedule & guardrails
- Configure **maintenance windows** (allowed times) and **exclusions/freeze** (blackout) periods.
- Consider **zonal vs regional** clusters (regional control planes upgrade across zones one by one).

---

## 3) Upgrade Strategies (Node Pools)

### 3.1 Surge Upgrade (in‑place replacement)
- GKE cordons & drains a node, creates **surge** nodes (temporary capacity), schedules pods onto new nodes, then deletes old ones.
- Tune with:
  - `--max-surge-upgrade=<N>`: extra nodes during upgrade (more capacity, faster, costs briefly more).
  - `--max-unavailable-upgrade=<N>`: how many nodes can be unavailable at once.
- Pros: Simple, fast; minimal infra change.  
- Cons: Some scheduling churn; relies on PDBs to avoid over‑drain.

### 3.2 Blue/Green Node Pools (a.k.a. canary pool → cutover)
- Create **new node pool** at target version (green), **cordon/taint** it for **canary workloads**, validate, then **migrate** remaining workloads and delete old pool (blue).
- Pros: Strong isolation, easy rollback (keep blue temporarily).  
- Cons: More capacity needed; extra ops.

### 3.3 Autopilot
- Google manages nodes. You still choose **control plane** version window; **node upgrades** are coordinated for you with SLO‑aware disruption limits. Use **PDBs** and **readiness** as usual.

---

## 4) Commands You’ll Actually Use

> Replace `<CLUSTER>`, `<REGION|ZONE>`, `<POOL>` as needed.

### 4.1 Inspect versions & channels
```bash
gcloud container clusters list
gcloud container clusters describe <CLUSTER> --region <REGION>

# See available versions for your location & channel
gcloud container get-server-config --region <REGION> \
  --format="yaml(validMasterVersions, validNodeVersions, channels)"
```

### 4.2 Set or change release channel
```bash
# During create
gcloud container clusters create <CLUSTER> --release-channel=stable --region <REGION>

# For existing cluster
gcloud container clusters update <CLUSTER> --release-channel=stable --region <REGION>
```

### 4.3 Control plane upgrade
```bash
# To a specific version (recommended: latest patch in your channel)
gcloud container clusters upgrade <CLUSTER> \
  --master \
  --cluster-version=<TARGET_VERSION> \
  --region <REGION>
```

### 4.4 Node pool surge upgrade
```bash
# Optional: tune surge/unavailable before upgrade
gcloud container node-pools update <POOL> \
  --cluster <CLUSTER> --region <REGION> \
  --max-surge-upgrade=2 --max-unavailable-upgrade=0

# Upgrade node pool
gcloud container node-pools upgrade <POOL> \
  --cluster <CLUSTER> --region <REGION> \
  --node-version=<TARGET_NODE_VERSION>
```

### 4.5 Blue/green node pool
```bash
# Create green pool
gcloud container node-pools create green-pool \
  --cluster <CLUSTER> --region <REGION> \
  --num-nodes=3 --image-type=COS_CONTAINERD \
  --node-version=<TARGET_NODE_VERSION>

# (Optional) Taint as canary first
kubectl taint nodes -l cloud.google.com/gke-nodepool=green-pool role=canary:NoSchedule

# Migrate workloads gradually:
# - remove taint for specific namespaces or pods using tolerations
# - or change nodeSelector / topology / preferredDuringScheduling
# After validation, drain blue then delete it:
kubectl drain <BLUE_NODE> --ignore-daemonsets --delete-emptydir-data
gcloud container node-pools delete blue-pool --cluster <CLUSTER> --region <REGION>
```

### 4.6 Maintenance windows & exclusions
```bash
# Allow upgrades only 01:00–03:00 IST daily
gcloud container clusters update <CLUSTER> \
  --maintenance-window-start 01:00 \
  --maintenance-window-end 03:00 \
  --maintenance-window-recurrence "FREQ=DAILY"

# Add a freeze (exclusion) for a release blackout
gcloud container clusters update <CLUSTER> \
  --add-maintenance-exclusion-name "Festive-Freeze" \
  --add-maintenance-exclusion-start "2025-12-15T00:00:00+05:30" \
  --add-maintenance-exclusion-end   "2026-01-05T23:59:59+05:30"
```

---

## 5) Protecting Availability (PDBs & Probes)

### 5.1 PodDisruptionBudget (example)
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: prod
spec:
  minAvailable: 4        # or use maxUnavailable: 1
  selector:
    matchLabels:
      app: api
```

### 5.2 Readiness & graceful shutdown
- Set **readinessProbe** and **livenessProbe** (HTTP/TCP/Command).
- Handle **SIGTERM** and use `terminationGracePeriodSeconds` to flush requests.
- For stateful sets, confirm **PodManagementPolicy** and **orderedReady**.

---

## 6) Safe Rollout Checklist

- [ ] Control plane upgraded and healthy
- [ ] System add‑ons compatible (CNI/CSI, gateways, webhooks)
- [ ] Staging upgrade completed and tested
- [ ] PDBs present for critical deployments
- [ ] Surge or blue/green strategy decided and configured
- [ ] Error rate, latency, saturation SLOs monitored
- [ ] Runbook & rollback plan defined

---

## 7) Validation Steps

1. **Pre‑flight**
   - `kubectl api-resources` / `kubectl explain` for removed fields.
   - Dry‑run apply of manifests: `kubectl apply --server-dry-run -f ...`
2. **Smoke tests**: health endpoints, synthetic checks, e2e happy paths.
3. **Load tests** (if possible) against staging at target version.
4. **Post‑upgrade**: confirm SLOs, logs, and HPA behavior for 24–48h.

---

## 8) Troubleshooting Upgrades

- **Pods stuck terminating** → check finalizers, preStop hooks, long drains.
- **PDB blocks drain** → temporarily lower `minAvailable` (with caution) or increase surge capacity.
- **Webhook timeouts** → raise webhook timeouts; ensure webhooks are HA and compatible.
- **CNI/CSI failures** → verify DaemonSets on new nodes; check image pull & permissions.
- **Node not ready after upgrade** → review GCE instance logs, kubelet, and cloud‑init; verify image type.

---

## 9) Example: Real‑World Minor Upgrade Plan

**Scenario**: Stable channel cluster currently on **v1.31.x**, target **v1.32.y (latest patch)**.

1. **Stage** on non‑prod: control plane ➜ node pools (surge `2/0`), validate for 48h.
2. **Prod**
   - Maintenance window: 01:00–03:00 IST.
   - Upgrade control plane to **1.32.y**.
   - Update add‑ons if needed (CNI/CSI/webhooks).
   - Upgrade **infra/system pools** first (ingress/metrics/istio).
   - Upgrade **app pools** with surge or blue/green. Watch SLOs.
   - Keep old pool for 24h; delete after stability confirmed.
3. **Document** findings and update runbooks.

---

## 10) Interview‑Style Q&A (use these verbatim)

**Q: Which version to which version did you upgrade?**  
A: “In production we moved from **GKE 1.31.x to 1.32.y** on the **Stable** channel. We upgraded the **control plane first**, then **node pools** using **surge upgrade** (`max-surge=2`, `max-unavailable=0`). We protected uptime with **PDBs**, readiness probes, and a **blue/green canary pool** for critical workloads. Post‑upgrade we validated SLOs for **48 hours** before removing the old pool.”

**Q: How did you minimize downtime?**  
A: “We used **surge upgrades** and strict **PDBs**, plus **maintenance windows** at 01:00–03:00 IST. Critical namespaces had a **blue/green pool** for fast rollback.”

**Q: How do you decide target versions?**  
A: “We stay on **Stable channel**, take the **latest patch** on our current minor first, then plan **minor upgrades** after staging validation. We check **API deprecations**, add‑on compatibility, and version skew.”

**Q: What if something breaks?**  
A: “Rollback to the previous node pool (blue), or reduce surge and halt upgrades. For control plane issues we open Google support and keep nodes at the prior minor while we mitigate. All changes happen inside a maintenance window with alerts.”

**Q: Autopilot vs Standard upgrades?**  
A: “Autopilot coordinates node upgrades for us; we still manage control‑plane cadence, **PDBs**, and validation. In Standard we tune **surge** and can do **blue/green** for fine‑grained control.”

---

## 11) Templates

### 11.1 Surge settings (per pool)
```bash
gcloud container node-pools update <POOL> \
  --cluster <CLUSTER> --region <REGION> \
  --max-surge-upgrade=2 --max-unavailable-upgrade=0
```

### 11.2 PDB (copy‑paste)
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <app>-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: <app>
```

### 11.3 Blue/green cutover checklist
- [ ] Green pool created at target version
- [ ] Canary namespaces scheduled on green (via taints/tolerations)
- [ ] SLOs healthy 24–48h
- [ ] Drain blue, delete pool
- [ ] Capacity & autoscaling re‑checked

---

## 12) Post‑Upgrade Hygiene
- Rotate **COS/Ubuntu** images regularly (security fixes).
- Update **cluster autoscaler**, **metrics**, and **ingress/gateway** charts/operators to versions aligned with the new minor.
- Keep a **CHANGELOG** with dates, versions, and lessons learned.

---

### One‑liner you can say in interviews
> “We upgraded **GKE Stable** from **1.31.x → 1.32.y**: control plane first, then node pools with **surge 2/0**, protected by **PDBs** and **maintenance windows**, validated SLOs for **48h**, and kept a **blue/green** fallback.”
