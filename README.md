# aws-irsa

Provisions IAM Roles for Service Accounts (IRSA) so Kubernetes workloads can assume AWS roles without static credentials.

## Why IRSA?

**Without IRSA:**
- Static AWS credentials stored in Kubernetes Secrets
- Credentials shared across pods, hard to audit
- Manual rotation of access keys
- Overly broad permissions to avoid complexity
- Security risk if credentials leak

**With IRSA:**
- No static credentials - pods assume IAM roles via OIDC
- Fine-grained, per-service-account permissions
- Automatic credential rotation by AWS
- Full CloudTrail audit trail
- Follows AWS security best practices

## The Journey

### Stage 1: Getting Started (Single Service)

Minimal configuration for a single service needing AWS access.

**Why start here?**
- Establishes secure credential-free pattern from day one
- No migration pain when you scale
- Each service gets exactly the permissions it needs

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IRSA
metadata:
  name: my-app
  namespace: production
spec:
  clusterName: my-cluster
  accountId: "123456789012"
  oidc: oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE123
  policy:
    document: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": ["s3:GetObject", "s3:PutObject"],
            "Resource": ["arn:aws:s3:::my-bucket/*"]
          }
        ]
      }
  serviceAccount:
    namespace: production
    name: my-app
```

### Stage 2: Growing (Multiple Services)

Add naming conventions and permissions boundaries as your team grows.

**Why expand?**
- Consistent naming across services
- Permissions boundaries prevent privilege escalation
- Custom labels for cost allocation and ownership tracking

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IRSA
metadata:
  name: loki
  namespace: logging
spec:
  clusterName: prod-cluster
  providerConfigRef:
    name: shared-aws
  accountId: "123456789012"
  oidc: oidc.eks.us-west-2.amazonaws.com/id/CLUSTER123
  permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-boundary"
  role:
    namePrefix: irsa-
  policy:
    namePrefix: irsa-
    document: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": [
              "arn:aws:s3:::loki-chunks",
              "arn:aws:s3:::loki-chunks/*"
            ]
          }
        ]
      }
  labels:
    team: platform
    service: logging
  tags:
    team: platform
    cost-center: infrastructure
  serviceAccount:
    namespace: logging
    name: loki
```

### Stage 3: Enterprise Scale

Standardized patterns across multiple clusters and accounts.

**Why this matters at scale?**
- Exact name control for cross-account role assumptions
- Consistent tagging for compliance and cost allocation
- Integration with organizational governance policies

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IRSA
metadata:
  name: cross-account-reader
  namespace: data-platform
spec:
  clusterName: analytics-cluster
  providerConfigRef:
    name: data-account-aws
  accountId: "987654321098"
  oidc: oidc.eks.us-east-1.amazonaws.com/id/ANALYTICS
  permissionsBoundary: "arn:aws:iam::987654321098:policy/strict-boundary"
  role:
    nameOverride: "analytics-cross-account-reader"
  policy:
    nameOverride: "analytics-cross-account-policy"
    document: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": ["sts:AssumeRole"],
            "Resource": ["arn:aws:iam::123456789012:role/data-reader"]
          }
        ]
      }
  labels:
    compliance: pci-dss
    data-classification: confidential
  tags:
    compliance: pci-dss
    environment: production
  serviceAccount:
    namespace: data-platform
    name: data-reader
```

### Stage 4: Import Existing

Bring existing IAM roles under Crossplane management without recreation.

**Why import?**
- Preserve existing role ARNs referenced by other systems
- Gradual adoption path
- No disruption to running workloads

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: IRSA
metadata:
  name: legacy-service
  namespace: production
spec:
  # Use orphan policy to manage without deletion rights
  managementPolicies: ["Create", "Observe", "Update", "LateInitialize"]
  clusterName: my-cluster
  accountId: "123456789012"
  oidc: oidc.eks.us-east-1.amazonaws.com/id/CLUSTER
  role:
    externalName: existing-irsa-role
  policy:
    externalName: existing-irsa-policy
    document: |
      {
        "Version": "2012-10-17",
        "Statement": [...]
      }
  serviceAccount:
    namespace: production
    name: legacy-app
```

## Using IRSA

Reference the role ARN in your pod's service account annotation:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: production
  annotations:
    # Get this from IRSA status
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/my-cluster-my-app
```

Or query the status programmatically:

```bash
kubectl get irsa my-app -n production -o jsonpath='{.status.role.arn}'
```

## Status

The IRSA resource exposes typed status fields from the created AWS resources:

| Field | Description |
|-------|-------------|
| `ready` | Whether all composed resources are ready |
| `role.arn` | ARN of the IAM role - use for ServiceAccount annotations |
| `role.name` | Name of the IAM role in AWS |
| `policy.arn` | ARN of the IAM policy |
| `policy.name` | Name of the IAM policy in AWS |
| `attachment.id` | ID of the role-policy attachment in AWS |

Example:
```yaml
status:
  ready: true
  role:
    arn: "arn:aws:iam::123456789012:role/cluster-x-loki"
    name: "cluster-x-loki"
  policy:
    arn: "arn:aws:iam::123456789012:policy/cluster-x-loki"
    name: "cluster-x-loki"
  attachment:
    id: "cluster-x-loki-20240115123456789"
```

## Composed Resources

This XRD creates:

- **IAM Role** - With web identity trust policy for the OIDC provider
- **IAM Policy** - Contains the permissions you define
- **RolePolicyAttachment** - Links the policy to the role
- **Usage** (2x) - Deletion protection for Role and Policy

## Development

```bash
make render          # Render all examples
make validate        # Validate all examples against schemas
make test            # Run unit tests
make e2e             # Run E2E tests (requires AWS credentials)
make publish tag=v1  # Build and push package
```

## License

Apache-2.0
