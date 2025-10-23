# ☸️ Implementing Secure Workload Identity on AWS EKS using IRSA

## Step-01: Introduction
**Goal:**  
We will allow a Pod in EKS to securely access AWS services (like S3, CloudWatch, DynamoDB) using **IAM Roles for Service Accounts (IRSA)**.

**Concept:**  
- Instead of static credentials, EKS uses **OIDC (OpenID Connect)** to connect Kubernetes Service Accounts with IAM Roles.  
- This allows Pods to assume IAM roles dynamically.

---

## Step-02: Pre-requisites
1. EKS Cluster must be running  
2. `kubectl` and `aws` CLI configured  
3. `eksctl` installed (recommended for easy setup)  

Verify setup:
```bash
aws sts get-caller-identity
kubectl get nodes
```

---

## Step-03: Enable OIDC Provider for Your EKS Cluster
```bash
eksctl utils associate-iam-oidc-provider   --cluster surya-eks-cluster   --approve
```

Check if OIDC provider is created:
```bash
aws iam list-open-id-connect-providers
```

---

## Step-04: Create IAM Policy for Access
Example: S3 Read-Only Access Policy for the Pod.

```bash
cat > s3-read-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::surya-demo-bucket",
                "arn:aws:s3:::surya-demo-bucket/*"
            ]
        }
    ]
}
EOF
```

Create policy:
```bash
aws iam create-policy   --policy-name S3ReadOnlyPolicy   --policy-document file://s3-read-policy.json
```

---

## Step-05: Create IAM Role for Kubernetes Service Account (IRSA)
We will create an IAM role that the Pod can assume through the Kubernetes Service Account.

```bash
eksctl create iamserviceaccount   --name s3-access-sa   --namespace irsa-demo   --cluster surya-eks-cluster   --attach-policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/S3ReadOnlyPolicy   --approve   --override-existing-serviceaccounts
```

Verify:
```bash
kubectl get sa s3-access-sa -n irsa-demo -o yaml
```

Look for this annotation:
```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/eksctl-surya-eks-cluster-addon-iamserviceaccount-irsa-demo-s3-access-sa
```

---

## Step-06: Deploy Test Pod with IAM Role
Create a test pod that uses this Service Account.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: irsa-demo-pod
  namespace: irsa-demo
spec:
  serviceAccountName: s3-access-sa
  containers:
  - name: aws-cli
    image: amazon/aws-cli
    command: ["sleep", "infinity"]
```

Deploy:
```bash
kubectl apply -f irsa-demo-pod.yaml
kubectl get pods -n irsa-demo
```

---

## Step-07: Test Access from Pod
```bash
kubectl exec -it irsa-demo-pod -n irsa-demo -- bash
```

List buckets:
```bash
aws s3 ls
```

Try to read objects:
```bash
aws s3 ls s3://surya-demo-bucket/
```

✅ Expected: You should see S3 bucket contents without needing `aws configure`.

---

## Step-08: Negative Test Case
Let’s deploy another pod without the Service Account.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: irsa-demo-no-sa
  namespace: irsa-demo
spec:
  containers:
  - name: aws-cli
    image: amazon/aws-cli
    command: ["sleep", "infinity"]
```

Run:
```bash
kubectl apply -f irsa-demo-no-sa.yaml
kubectl exec -it irsa-demo-no-sa -n irsa-demo -- bash
```

Try listing S3 buckets:
```bash
aws s3 ls
```

❌ Expected: Access Denied (no credentials available).

---

## Step-09: Clean-Up Resources
```bash
kubectl delete pod irsa-demo-pod -n irsa-demo
kubectl delete pod irsa-demo-no-sa -n irsa-demo

eksctl delete iamserviceaccount   --name s3-access-sa   --namespace irsa-demo   --cluster surya-eks-cluster

aws iam delete-policy --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/S3ReadOnlyPolicy
```

---

## Step-10: Summary
✅ You have successfully configured **Workload Identity in AWS EKS using IRSA**.  
Pods now assume IAM roles securely and access AWS services **without credentials**.

---

## References
- [AWS EKS IRSA Official Docs](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [eksctl Documentation](https://eksctl.io/usage/iamserviceaccounts/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
