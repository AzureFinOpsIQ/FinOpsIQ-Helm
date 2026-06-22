# FinsOpsIQ AKS Deployment Pipeline Scaffold

Workflow: `.github/workflows/aks-deploy.yml`

This workflow deploys the existing Helm chart to AKS using the selected environment values file.

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
