# CrashLoopBackOff (Super Easy Explanation)

## ✅ What is CrashLoopBackOff?

CrashLoopBackOff means your container is **starting → crashing → restarting → crashing again**.

Kubernetes keeps trying… but the app keeps failing.

So Kubernetes goes into **BackOff mode** (waits before trying again).

---

## ✅ Why Does CrashLoopBackOff Happen? (Very Simple)

### ✅ 1. Wrong Configuration

Examples:

* Missing environment variable
* Wrong port
* Wrong file path
* Missing config file

App can’t start → crashes immediately.

---

### ✅ 2. Liveness Probe Killing Your Pod

If Kubernetes health-check hits the wrong endpoint, it thinks your app is unhealthy.

So it kills it again and again → loop.

---

### ✅ 3. Not Enough Memory (OOMKilled)

If the app uses more RAM than you gave:

* Kubernetes kills it
* It restarts
* Dies again

CrashLoopBackOff begins.

---

### ✅ 4. Wrong Command / Startup Script

Example:

```
python wrong.py
```

If the file doesn’t exist → container exits instantly.

---

### ✅ 5. App Bug

Your application crashes during startup.
Examples:

* NullPointerException (Java)
* Unhandled exception (Node/Python)
* Syntax error

Every time it starts → same error → crash loop.

---

## ✅ How to Fix CrashLoopBackOff (Super Easy Steps)

### ✅ Step 1: Check Logs

```
kubectl logs <pod>
```

If it restarts too fast:

```
kubectl logs <pod> --previous
```

---

### ✅ Step 2: Describe the Pod

```
kubectl describe pod <pod>
```

Look for:

* **OOMKilled** (memory issue)
* **Liveness probe failed**
* **Bad command**
* **Exit code 1**

---

### ✅ Step 3: Fix the Root Issue Based on Logs

Examples:

* Missing env → **add correct env**
* Wrong probe → **fix probe endpoint**
* Low memory → **increase memory limit**
* App crash → **fix code**
* Wrong command → **fix entrypoint**

---

## ✅ Simple Summary

CrashLoopBackOff = container keeps crashing because of bad config, app bug, wrong probe, wrong command, or low memory.

Fix it by checking **logs**, **describe**, and correcting the root cause.

---