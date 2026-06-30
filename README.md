# FinOpsIQ Helm Deployment

This repository contains the Helm chart, Argo CD manifests, and AKS deployment workflow used to deploy the FinOpsIQ application.

Application source code and infrastructure code live in separate repositories:

```text
AzureFinOpsIQ/FinOpsIQ-Saas
AzureFinOpsIQ/FinOpsIQ-Infra
```

## What This Repository Manages

- Helm chart for the FinOpsIQ application.
- Environment values for dev and prod deployments.
- Kubernetes Deployments, Services, ServiceAccounts, HPAs, ConfigMap, SecretProviderClass, Namespace, and Ingress resources.
- Argo CD AppProject and Application manifests.
- Manual AKS deployment workflow that calls the centralized workflow repository.

## What This Repository Does Not Manage

- Azure infrastructure provisioning.
- Docker image builds.
- Application source code.
- Microsoft Entra app registration creation.
- Azure RBAC role assignments.
- Managed Identity creation.
- Key Vault secret creation.

Those responsibilities belong to the infrastructure and application repositories.

## Repository Layout

```text
FinOpsIQ-Helm/
  .github/workflows/
    aks-deploy.yml
  argocd/
    README.md
    project.yaml
    finopsiq-dev.yaml
    finopsiq-prod.yaml
    argocd-server-http.yaml
    argocd-ingress.yaml
  charts/
    finopsiq/
      README.md
      Chart.yaml
      values.yaml
      dev-values.yaml
      prod-values.yaml
      deployment-dependency-diagram.md
      templates/
  docs/
    aks-deploy-pipeline.md
```

## Helm Chart

Chart path:

```text
charts/finopsiq
```

The chart deploys these application components:

- frontend
- api-gateway
- auth-service
- collection-service
- processing-service
- ai-service
- notification-service

The chart also renders:

- Namespace
- Deployments
- Services
- ServiceAccounts
- HorizontalPodAutoscalers
- Shared ConfigMap for non-secret environment values
- SecretProviderClass for Key Vault backed secrets
- Ingress resources for frontend and API Gateway

## Values Files

| File | Purpose |
| --- | --- |
| `charts/finopsiq/values.yaml` | Default chart values and shared schema. |
| `charts/finopsiq/dev-values.yaml` | DEV deployment values, image tags, hostnames, and runtime configuration. |
| `charts/finopsiq/prod-values.yaml` | PROD deployment values, image tags, hostnames, and runtime configuration. |

## Runtime Configuration

Shared non-secret values are configured under:

```yaml
config:
  env:
```

These values are rendered into a Kubernetes ConfigMap and consumed by the pods.

Genuine secrets are configured under:

```yaml
config:
  secretKeys:
```

These secrets are synchronized from Azure Key Vault through the CSI Secret Store and SecretProviderClass mechanism.

Current secret keys:

```text
ENTRA_CLIENT_SECRET
API_SESSION_SECRET
```

Do not place static infrastructure configuration such as tenant IDs, service URLs, endpoints, deployment names, or client IDs in Key Vault unless they are true secrets.

## Workload Identity

Each service has a `serviceAccountClientId` value.

This value becomes:

- the Kubernetes ServiceAccount annotation `azure.workload.identity/client-id`;
- the pod environment variable `AZURE_CLIENT_ID`;
- the managed identity selected by Azure Workload Identity.

The pods use Azure Workload Identity with `DefaultAzureCredential`.

Terraform is responsible for creating:

- User Assigned Managed Identities;
- Federated Identity Credentials;
- Azure RBAC role assignments;
- Key Vault access;
- Azure data-plane permissions.

The Helm chart only consumes the client IDs and renders Kubernetes resources.

## Ingress

The chart renders ingress resources for:

- frontend traffic at `/`;
- API Gateway traffic at `/api`.

Ingress is configured for Azure Application Gateway Ingress Controller using:

```yaml
ingress:
  className: azure-application-gateway
```

Hostname and SSL certificate values are supplied through environment values files.

## Argo CD

Argo CD manifests are stored in:

```text
argocd/
```

| File | Purpose |
| --- | --- |
| `project.yaml` | Creates the FinOpsIQ Argo CD project and allowed resource scope. |
| `finopsiq-dev.yaml` | Argo CD Application for the dev namespace. |
| `finopsiq-prod.yaml` | Argo CD Application for the prod namespace. |
| `argocd-server-http.yaml` | Configures Argo CD server for HTTP behind the gateway where required. |
| `argocd-ingress.yaml` | Exposes Argo CD through Application Gateway. |

Dev and prod applications both point to the same chart path and use their environment-specific values files.

## AKS Deployment Workflow

Workflow file:

```text
.github/workflows/aks-deploy.yml
```

Trigger:

```text
workflow_dispatch
```

Inputs:

- `environment`: `dev` or `prod`

The workflow is a thin caller for the centralized reusable workflow:

```text
AzureFinOpsIQ/FinOPsIQ-Workflows/.github/workflows/helm-aks-deploy.yml@main
```

The workflow passes:

- environment
- chart path
- release name
- AKS resource group
- AKS cluster name
- Azure OIDC secrets

It does not use `secrets: inherit`.

See [docs/aks-deploy-pipeline.md](docs/aks-deploy-pipeline.md) for more deployment workflow details.

## Local Validation

Validate the chart:

```bash
helm lint charts/finopsiq
```

Render dev manifests:

```bash
helm template finopsiq charts/finopsiq -f charts/finopsiq/dev-values.yaml
```

Render prod manifests:

```bash
helm template finopsiq charts/finopsiq -f charts/finopsiq/prod-values.yaml
```

Validate Argo CD manifests:

```bash
kubectl apply --dry-run=client -f argocd/project.yaml
kubectl apply --dry-run=client -f argocd/finopsiq-dev.yaml
kubectl apply --dry-run=client -f argocd/finopsiq-prod.yaml
```

## Manual Helm Deployment

Dev example:

```bash
helm upgrade --install finopsiq charts/finopsiq \
  --namespace finopsiq-dev \
  --create-namespace \
  -f charts/finopsiq/dev-values.yaml
```

Prod example:

```bash
helm upgrade --install finopsiq charts/finopsiq \
  --namespace finopsiq-prod \
  --create-namespace \
  -f charts/finopsiq/prod-values.yaml
```

For normal operations, prefer Argo CD sync or the AKS deployment workflow.

## Post-Deployment Checks

Run these checks after deployment:

```bash
kubectl -n finopsiq-dev get pods
kubectl -n finopsiq-dev get svc
kubectl -n finopsiq-dev get ingress
kubectl -n finopsiq-dev get secret
kubectl -n finopsiq-dev get secretproviderclass
```

Check rollout status:

```bash
kubectl -n finopsiq-dev rollout status deployment/frontend
kubectl -n finopsiq-dev rollout status deployment/api-gateway
kubectl -n finopsiq-dev rollout status deployment/auth-service
kubectl -n finopsiq-dev rollout status deployment/collection-service
kubectl -n finopsiq-dev rollout status deployment/processing-service
kubectl -n finopsiq-dev rollout status deployment/ai-service
kubectl -n finopsiq-dev rollout status deployment/notification-service
```

Health checks:

- Frontend should respond on `/`.
- Python services should respond on `/health/live` and `/health/ready`.
- Application Gateway should route `/` to frontend and `/api` to API Gateway.
- Key Vault backed Kubernetes secret should exist before pods start.
- Workload Identity pods should have the correct `AZURE_CLIENT_ID`.

## Related Documentation

- [Chart README](charts/finopsiq/README.md)
- [Argo CD README](argocd/README.md)
- [AKS Deploy Pipeline](docs/aks-deploy-pipeline.md)
- [Deployment Dependency Diagram](charts/finopsiq/deployment-dependency-diagram.md)
