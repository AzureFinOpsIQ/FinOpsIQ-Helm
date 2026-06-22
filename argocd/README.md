# FinsOpsIQ ArgoCD GitOps Setup

This folder contains ArgoCD manifests for managing FinsOpsIQ deployments through GitOps.

Nothing in this folder deploys workloads by itself. Apply these manifests only after ArgoCD is installed and configured in the target AKS cluster.

## Files

```text
argocd/
├── project.yaml
├── finopsiq-dev.yaml
├── finopsiq-prod.yaml
└── README.md
```

## ArgoCD Project

`project.yaml` creates a dedicated ArgoCD `AppProject` named `finopsiq`.

The project allows:

- Git repository: `https://github.com/AzureFinOpsIQ/FinOpsIQ-Helm.git`
- Cluster: `https://kubernetes.default.svc`
- Namespaces:
  - `finopsiq-dev`
  - `finopsiq-prod`

Allowed workload resources:

- Deployments
- Services
- Ingresses
- ConfigMaps
- Secrets
- HorizontalPodAutoscalers
- ServiceAccounts
- NetworkPolicies
- PodDisruptionBudgets

The chart currently renders a Namespace manifest, so the project also allows the cluster-scoped `Namespace` kind.

## Dev Application

`finopsiq-dev.yaml` creates the `finopsiq-dev` ArgoCD Application.

It uses:

- Project: `finopsiq`
- Branch: `main`
- Chart path: `charts/finopsiq`
- Values file: `dev-values.yaml`
- Destination namespace: `finopsiq-dev`
- Automated sync with prune and self-heal
- `CreateNamespace=true`

## Prod Application

`finopsiq-prod.yaml` creates the `finopsiq-prod` ArgoCD Application.

It uses:

- Project: `finopsiq`
- Branch: `main`
- Chart path: `charts/finopsiq`
- Values file: `prod-values.yaml`
- Destination namespace: `finopsiq-prod`
- Automated sync with prune and self-heal
- `CreateNamespace=true`

## Dev GitOps Flow

```text
Developer
  ↓
PR → dev
  ↓
SonarCloud
  ↓
Snyk
  ↓
Merge → main
  ↓
Build image
  ↓
Trivy scan
  ↓
Push SHA image to ACR
  ↓
Update dev-values.yaml
  ↓
Commit to FinOpsIQ-Helm
  ↓
ArgoCD auto sync
  ↓
finopsiq-dev
```

## Prod GitOps Flow

```text
GitHub Release
(v1.0.0)
  ↓
Retag existing SHA image
  ↓
Push semantic tag to ACR
  ↓
Update prod-values.yaml
  ↓
Commit to FinOpsIQ-Helm
  ↓
ArgoCD auto sync
  ↓
finopsiq-prod
```

## Validation Commands

Run from the repository root:

```bash
helm template finopsiq-dev charts/finopsiq -f charts/finopsiq/dev-values.yaml
helm template finopsiq-prod charts/finopsiq -f charts/finopsiq/prod-values.yaml
```

If the ArgoCD CLI is available:

```bash
argocd app lint argocd/finopsiq-dev.yaml
argocd app lint argocd/finopsiq-prod.yaml
```

If the ArgoCD CLI is not available, validate YAML structure and API fields in CI before applying.
