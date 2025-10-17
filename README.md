
# config-irsa

A Crossplane Configuration Package for effortless Cert-Manager deployment with Let's Encrypt integration.

## Overview

The `config-irsa` project is a Crossplane Configuration package that simplifies the deployment and management of [Cert-Manager](https://irsa.io/) on Kubernetes clusters. It automatically provisions an initial ClusterIssuer for Let's Encrypt (staging and production), with seamless AWS integration for DNS-01 challenges using Route53 and secure IAM role-based access via IRSA (IAM Roles for Service Accounts).

This package provides the `XCertManager` composite resource definition (XRD) to configure Cert-Manager installations with AWS-specific settings including hosted zones, OIDC providers, and IAM roles. Designed for Kubernetes clusters running on AWS EKS.

## Features

- **Automated Cert-Manager Installation**: Deploys Cert-Manager via Helm with fully customizable configurations
- **Let's Encrypt Integration**: Pre-configures ClusterIssuers for both staging and production environments
- **AWS Route53 DNS-01**: Native support for DNS-01 challenges with Route53
- **IRSA Integration**: Secure IAM role-based access for service accounts
- **Dynamic Composition**: Uses Crossplane's composition pipeline with Go templating for resource rendering
- **CI/CD Ready**: Complete GitHub Actions workflows for quality checks, testing, and automated publishing
- **Dependency Automation**: Renovate-powered automatic Helm chart dependency updates
- **GitOps Compatible**: Includes Helm chart templates for GitOps deployments
- **Comprehensive Testing**: Crossplane beta validation and composition testing pipelines

## Prerequisites

To use this package:

- **Kubernetes cluster** (e.g., AWS EKS)
- **[Crossplane](https://crossplane.io/)** installed on the cluster
- **Crossplane providers**:
  - `provider-kubernetes` (≥v1.0.0)
  - `provider-helm` (≥v1.0.2)
  - `provider-aws-iam` (≥v2.1.1)
- **Crossplane function**:
  - `function-auto-ready` (≥v0.5.1)
- **AWS credentials** with permissions to manage Route53 and IAM roles
- **Access to GHCR** for pulling the configuration package

## Quick Start

### 1. Install Crossplane

Follow the [official Crossplane installation guide](https://docs.crossplane.io/latest/getting-started/install-configure/) to install Crossplane in your Kubernetes cluster.

### 2. Install Required Providers

Apply the provider configurations:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.upbound.io/upbound/provider-kubernetes:v1.0.0
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-helm
spec:
  package: xpkg.upbound.io/upbound/provider-helm\v1.0.2
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-iam
spec:
  package: xpkg.upbound.io/upbound/provider-aws-iam:v2.1.1
---
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-auto-ready
spec:
  package: xpkg.upbound.io/crossplane-contrib/function-auto-ready:v0.5.1
```

### 3. Install the Configuration Package

Install the `config-irsa` package:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Configuration
metadata:
  name: config-irsa
spec:
  package: ghcr.io/hops-ops/config-irsa:latest
  packagePullSecrets:
    - name: ghcr
  skipDependencyResolution: true
```

> **Note**: Ensure you have a pull secret named `ghcr` configured for GitHub Container Registry authentication.

### 4. Create an XCertManager Resource

Deploy Cert-Manager with Let's Encrypt integration:

```yaml
apiVersion: hops.ops.com.ai/v1alpha1
kind: XCertManager
metadata:
  name: irsa
spec:
  clusterName: my-cluster
  deletionPolicy: Delete

  helm:
    certManager:
      extraValues: {}
      overrideValues: {}

  aws:
    enabled: true
    providerConfig: aws-account-x
    config:
      accountId: "123456789012"
      hostedZone: example.com
      region: us-east-1
      oidc: "https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E2E1B6B6B1AE520"
      permissionsBoundary: "arn:aws:iam::123456789012:policy/eks-permissions-boundary"
      tags:
        owner: admin@example.com
        service: test
        repo: test
```

This creates:
- Cert-Manager deployment in the `irsa` namespace
- IAM role for the Cert-Manager service account via IRSA
- Let's Encrypt ClusterIssuers (staging and production) configured for Route53 DNS-01 challenges

## Project Structure

```
config-irsa/
├── .github/workflows/               # GitHub Actions CI/CD automation
│   ├── quality.yaml                 # Composition validation and testing
│   ├── on-push-main.yaml            # Versioning and tagging on main branch
│   ├── on-pr.yaml                   # Pull request quality checks
│   ├── on-version-tagged.yaml       # Release publishing and promotion
│   └── publish.yaml                 # Package publishing to GHCR
├── .gitops/deploy/                  # GitOps deployment manifests
│   ├── Chart.yaml                   # Helm chart specification
│   ├── templates/config.yaml        # Configuration package template
│   └── values.yaml                  # Helm values for GitOps
├── apis/xirsas/              # XRD and Composition definitions
│   ├── configuration.yaml           # Package configuration metadata
│   ├── definition.yaml              # XCertManager XRD schema
│   └── composition.yaml             # Composition pipeline logic
├── examples/xirsas/          # Usage examples
│   └── example.yaml                 # Complete XCertManager example
├── functions/render/                # Go template rendering functions
│   ├── 00-prelude.yaml.gotmpl       # Variable extraction and setup
│   ├── release.yaml.gotmpl          # Cert-Manager Helm release
│   ├── irsa.yaml.gotmpl             # IAM role and service account
│   ├── cluster-issuer-le-staging.yaml.gotmpl    # Staging ClusterIssuer
│   └── cluster-issuer-le-production.yaml.gotmpl # Production ClusterIssuer
├── tests/                           # Test suite and validation
│   ├── README.md                    # Testing documentation
│   └── test-render/                 # Composition rendering tests
└── Configuration files
    ├── renovate.json                # Dependency update automation
    ├── upbound.yaml                 # Project metadata and dependencies
    ├── .gitignore                   # Git ignore patterns
    └── Makefile                     # Build and validation commands
```

## Development

### Prerequisites

- [Upbound CLI](https://docs.upbound.io/cli/)
- [Crossplane CLI](https://docs.crossplane.io/latest/cli/)

### Building

Build the package locally:

```bash
make build
```

### Testing & Validation

Run the complete test suite:

```bash
make test          # Run composition rendering tests
make validate      # Validate compositions and examples
```

### Publishing

Publish a tagged release to GHCR:

```bash
make publish TAG=v1.0.0
```

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
crossplane beta validate apis/xirsas examples/xirsas
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

- **Issues**: [GitHub Issues](https://github.com/unbounded-tech/config-irsa/issues)
- **Discussions**: [GitHub Discussions](https://github.com/unbounded-tech/config-irsa/discussions)

## Maintainer

- **Patrick Lee Scott** <pat@patscott.io>

## Links

- **GitHub Repository**: [github.com/unbounded-tech/config-irsa](https://github.com/unbounded-tech/config-irsa)
- **Container Registry**: [ghcr.io/hops-ops/config-irsa](ghcr.io/hops-ops/config-irsa)
- **Documentation**: [docs.crossplane.io](https://docs.crossplane.io/)
- **Cert-Manager**: [irsa.io](https://irsa.io/)
