
# configuration-aws-irsa

`configuration-aws-irsa` is a Crossplane configuration package that provisions IAM Roles for Service Accounts (IRSA) so Kubernetes workloads can assume AWS roles without shipping static credentials. It publishes the `XIRSA` composite resource definition that standardises how teams request IAM access for a given service account.

## Features

- Creates IAM roles with the correct web identity trust policy for an EKS OIDC issuer.
- Attaches caller-supplied IAM policies and supports optional `rolePrefix`, `policyPrefix`, and permissions boundaries.
- Accepts AWS provider configs via `awsProviderConfig` or `aws.providerConfig`, defaulting to the composite's `clusterName`.
- Automatically merges the `hops: "true"` tag with any caller-provided tags.
- Ships with validation, testing, and publishing automation.

## Prerequisites

- An Amazon EKS cluster and OIDC provider for your workload.
- Crossplane installed in the target cluster.
- Crossplane providers:
  - `provider-aws-iam` (≥ v2.1.1)
- Crossplane functions:
  - `function-auto-ready` (≥ v0.5.1)
- Access to GitHub Container Registry (GHCR) for pulling the package image.

## Installing the Package

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: configuration-aws-irsa
spec:
  package: ghcr.io/hops-ops/configuration-aws-irsa:latest
  packagePullSecrets:
    - name: ghcr
  skipDependencyResolution: true
```

## Example Composite

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: XIRSA
metadata:
  name: example-irsa
spec:
  clusterName: cluster-x
  deletionPolicy: Orphan
  awsProviderConfig: shared-aws
  accountId: "123456789012"
  name: loki
  oidc: "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE1234567890"
  permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-boundary"
  rolePrefix: irsa-
  policyPrefix: irsa-
  tags:
    team: platform
    service: logging
  serviceAccount:
    namespace: loki
    name: loki
  policy: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "LokiStorage",
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
          ],
          "Resource": [
            "arn:aws:s3:::example-loki-chunks",
            "arn:aws:s3:::example-loki-chunks/*",
            "arn:aws:s3:::example-loki-ruler",
            "arn:aws:s3:::example-loki-ruler/*"
          ]
        }
      ]
    }
```

## Local Development

- `make render` – render the default example composite.
- `make validate` – run Crossplane schema validation against the XRD and examples.
- `make test` – execute `up test` regression tests.
- `make publish tag=<version>` – build and push the configuration package.

Keep `.github/` and `.gitops/` workflows aligned when making automation changes.

## License

Apache-2.0. See [LICENSE](LICENSE) for details.

> **Note**: Ensure you are authenticated with GitHub Container Registry.

### Local Rendering

Preview the composed resources without applying them:

```bash
make render
```

This renders the example composition using the Go template functions.

## CI/CD Pipelines

Automated workflows handle quality assurance, testing, and publishing:

- **`quality.yaml`**: Comprehensive validation of compositions and examples
- **`on-push-main.yaml`**: Quality checks and semantic versioning on main branch pushes
- **`on-pr.yaml**: Pull request validation and preview package publishing
- **`on-version-tagged.yaml`**: Production releases with GitOps chart updates
- **`publish.yaml`**: Package publishing to GitHub Container Registry

### Quality Gates

Before release, the pipeline validates:
- XRD schema compliance
- Composition rendering
- Crossplane beta validation for examples
- Helm chart dependency versions

### Automated Releases

- **Preview packages** on pull requests for testing
- **Semantic versioning** based on conventional commits
- **GitOps-ready artifacts** published to Helm repository

## Dependency Management

Automated dependency updates using [Renovate](https://docs.renovatebot.com/):

### Configured for:

- **Helm charts** in Go template files (`.yaml.gotmpl`)
- **Crossplane providers and functions** in YAML configurations
- **Cert-Manager app versions** in GitOps Chart.yaml

### Custom Managers:

The `renovate.json` defines custom regex managers to parse and update:
- Cert-Manager Helm chart versions in template files
- Provider version constraints
- Function version requirements

### Pull Request Automation:

Renovate creates dependency update PRs with:
- Version bump commits
- Regression testing via CI
- Dependency dashboard tracking

## Testing

The project includes comprehensive testing infrastructure:

### Crossplane Beta Validation

Validates XRD schemas and compositions against examples:

```bash
crossplane beta validate apis/irsas examples/irsas
```

### Composition Rendering Tests

Tests pipeline execution and resource generation:

```bash
up test run tests/*
```

### Manual Testing

Render compositions to verify outputs:

```bash
make render    # Preview composed resources
```

## License

Apache-2.0 License. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes:
   ```bash
   make validate
   make test
   ```
4. Submit a pull request

## Support

- **Issues**: [GitHub Issues](https://github.com/hops-ops/configuration-aws-irsa/issues)
- **Discussions**: [GitHub Discussions](https://github.com/hops-ops/configuration-aws-irsa/discussions)

## Maintainer

- **Patrick Lee Scott** <pat@patscott.io>

## Links

- **GitHub Repository**: [github.com/hops-ops/configuration-aws-irsa](https://github.com/hops-ops/configuration-aws-irsa)
- **Container Registry**: [ghcr.io/hops-ops/configuration-aws-irsa](ghcr.io/hops-ops/configuration-aws-irsa)
- **Documentation**: [docs.crossplane.io](https://docs.crossplane.io/)
- **Cert-Manager**: [irsa.io](https://irsa.io/)
