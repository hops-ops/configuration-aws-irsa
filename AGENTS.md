# IRSA Config Agent Guide

This repository publishes the `XIRSA` configuration package. Use this guide when updating schemas, templates, or automation for IAM Roles for Service Accounts.

## Repository Layout

- `apis/`: CRDs, definitions, and composition for `XIRSA`. Treat these files as source of truth for the released package.
- `examples/`: Renderable composite examples that demonstrate both minimal and fully featured specs. Keep them in sync with the schema.
- `functions/render/`: Go-template pipeline. Files execute in lexical order (`00-`, `10-`, `20-`), so leave numeric gaps to simplify future inserts.
- `tests/`: KCL-based regression tests executed via `up test`.
- `.github/` / `.gitops/`: CI and GitOps automation. Maintain structural parity across the two directories.
- `_output/`, `.up/`: Generated artefacts. Remove with `make clean` when needed.

## XIRSA Contract

- Required spec fields: `accountId`, `name`, `oidc`, `policy`, and `serviceAccount.{namespace,name}`. The schema enforces these to fail fast on missing inputs.
- `clusterName` seeds provider config fallbacks and resource name alignment. Leave it empty only in advanced scenarios.
- `awsProviderConfig` takes priority. If unset, `aws.providerConfig` is respected; otherwise the templates fall back to `clusterName`, then `"default"`.
- `rolePrefix` and `policyPrefix` are optional. The templates join `[clusterName, name]` with `-` and prepend the prefixes when present.
- All IAM resources merge user tags with the default `{"hops": "true"}` map.
- OIDC issuers may be provided with or without a scheme. Templates strip `https://` / `http://` and trailing slashes so the value can be re-used in ARNs and `StringEquals` statements.

## Rendering Guidelines

- Declare every reused value in `00-variables.yaml.gotmpl` with sensible defaults. Avoid direct field access in later templates.
- Stick to simple string concatenation. For example, inline role names instead of building nested maps; this keeps templates legible and works well with Renovate.
- Resource templates must reference only previously declared variables. If you add new variables, hoist them into the `00-` file.
- Default IAM tags to `{"hops": "true"}` and merge caller-provided tags afterwards.
- Favour readability over micro-templating—duplicated strings for clarity (for example, ARN segments) are acceptable.

## Testing

- Regression tests live in `tests/test-render/main.k` and cover:
  - A full example asserting provider-config precedence, prefix handling, OIDC normalisation, and permissions boundaries.
  - A minimal example confirming default provider-config selection and the default `hops` tag.
- Use `assertResources` to lock the behaviour you care about. Provide only the fields under test so future changes remain flexible elsewhere.
- Run `make test` (or `up test run tests/*`) after touching templates or examples.

## Development Workflow

- `make render` – render the default example.
- `make validate` – run schema validation against the XRD and examples.
- `make test` – execute the regression suite.
- `make publish tag=<version>` – build and push the package image.
- Keep `.github/` and `.gitops/` automation aligned when updating workflows.

Document behavioural changes in `README.md` and refresh `examples/` whenever the schema shifts.
