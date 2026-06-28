# FinsOpsIQ Helm Charts

This repository contains only Helm deployment assets for FinsOpsIQ.

Application source code lives in:

```text
AzureFinOpsIQ/FinOpsIQ-App
```

Terraform infrastructure code lives in:

```text
AzureFinOpsIQ/FinOpsIQ-Infra
```

## Chart

```text
charts/finopsiq
```

## Validate locally

```bash
helm lint charts/finopsiq
helm template finopsiq charts/finopsiq -f charts/finopsiq/dev-values.yaml
```

## Deploy

Deployment should be handled by a dedicated Helm/application pipeline. Do not deploy workloads from the Terraform infrastructure pipeline.
