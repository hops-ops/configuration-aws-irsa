# IRSA Config Agent Guide

This repository publishes the `IRSA` configuration package. Use this guide when updating schemas, templates, or automation for IAM Roles for Service Accounts.

## Repository Layout

- `apis/`: CRDs, definitions, and composition for `IRSA`. Treat these files as source of truth for the released package.
- `examples/`: Renderable composite examples that demonstrate both minimal and fully featured specs. Keep them in sync with the schema.
- `functions/render/`: Go-template pipeline. Files execute in lexical order (`00-`, `10-`, `20-`), so leave numeric gaps to simplify future inserts.
- `tests/test*`: KCL-based regression tests executed via `up test`.
- `tests/e2etest*`: KCL-based regression tests executed via `up test` with `--e2e` flag. Expects `aws-creds` file to exist (but gitignored)
- `.github/`: Github workflows
- `.gitops/`: GitOps automation usage.
- `_output/`, `.up/`: Generated artefacts. Remove with `make clean` when needed.

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

## E2E Testing

- Tests live under `tests/e2etest-irsa` and are invoked through `up test ... --e2e`, so the Upbound CLI must be authenticated and able to reach your control plane.
- Provide real AWS credentials via `tests/e2etest-irsa/aws-creds` (gitignored). The file must contain a `[default]` profile understood by the AWS SDK, for example:

  ```ini
  [default]
  aws_access_key_id = <access key>
  aws_secret_access_key = <secret key>
  ```

- Run `make e2e` (or `up test run tests/e2etest-irsa --e2e`) from the repo root to execute the suite. The harness uploads the manifest in `tests/e2etest-irsa/main.k`, injects the `aws-creds` Secret, and provisions a `ProviderConfig` so the test IRSA composition can reach AWS.
- The spec sets `skipDelete: false`, so resources are cleaned up automatically, but double-check for any leaked IAM roles or service accounts in the target account and remove them manually if the test aborts early.
- Never commit the `aws-creds` file; it is ignored on purpose and should contain only disposable test credentials.

## Development Workflow

- `make render` – render the default example.
- `make validate` – run schema validation against the XRD and examples.
- `make test` – execute the regression suite.
- `make e2e` - execute e2e tests.

Document behavioural changes in `README.md` and refresh `examples/` whenever the schema shifts.
