# FinsOpsIQ AKS Deployment Pipeline

Workflow: `.github/workflows/aks-deploy.yml`

This repository owns the AKS deployment trigger only. The implementation is centralized in `AzureFinOpsIQ/FinOPsIQ-Workflows`:

```text
AzureFinOpsIQ/FinOPsIQ-Workflows/.github/workflows/helm-aks-deploy.yml@main
```

The Helm repository workflow is a thin caller and passes named inputs/secrets explicitly. It does not use `secrets: inherit`.

Responsibilities:

1. Authenticate to Azure using GitHub OIDC.
2. Fetch AKS credentials.
3. Run `helm upgrade --install`.
4. Validate Kubernetes rollouts.
5. Run smoke tests.
6. Notify Slack.

Current behavior:

- Manual `workflow_dispatch` only.
- Accepts `dev` or `prod` as the target environment.
- Reads image repositories and tags from `values-dev.yaml` or `values-prod.yaml`.
- Runs Helm lint.
- Runs `helm upgrade --install`.
- Verifies rollout status.
- Verifies pod health.
- Shows ingress health.

This keeps application release automation separate from AKS deployment automation.

Image tags are never hardcoded in the workflow. Helm values are the deployment source of truth.
