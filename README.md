# ResolveOps AI — Infrastructure Repository

Centralized infrastructure scripts and IaC definitions for the ResolveOps AI platform.

---

## Repository Structure

```
scripts/
  build-and-push-acr.sh    # Build all Docker images and push to ACR
  deploy-to-aks.sh         # Deploy all services to AKS
terraform/
  modules/
    aks/                   # AKS cluster module (scaffold)
    acr/                   # Azure Container Registry module (scaffold)
    networking/            # VNet + subnets module (scaffold)
  environments/
    dev/                   # Dev environment Terraform config (scaffold)
    prod/                  # Prod environment Terraform config (scaffold)
```

---

## Scripts

### `scripts/build-and-push-acr.sh`

Builds all service Docker images locally and pushes them to Azure Container Registry.

```bash
# Set required variables
export ACR_LOGIN_SERVER=resolveopsai.azurecr.io
export ACR_USERNAME=<your-acr-username>
export ACR_PASSWORD=<your-acr-password>

chmod +x scripts/build-and-push-acr.sh
./scripts/build-and-push-acr.sh
```

### `scripts/deploy-to-aks.sh`

Deploys all Kubernetes manifests from the `resolveops-config` repo to AKS.

```bash
chmod +x scripts/deploy-to-aks.sh
./scripts/deploy-to-aks.sh
```

---

## Terraform

> ⚠️ **Scaffold Only**
>
> The Terraform directories define the intended IaC structure for the ResolveOps AI infrastructure.
> **No actual Terraform code currently exists in this repository.**
> Full Terraform implementation (AKS cluster provisioning, ACR setup, networking, RBAC)
> is a **future infrastructure milestone**, separate from the Phase 1 repo split and
> the Phase 2 service extraction work.

### Planned Terraform Modules

| Module | Purpose |
|---|---|
| `terraform/modules/aks` | AKS cluster with workload identity and OIDC |
| `terraform/modules/acr` | Azure Container Registry with geo-replication |
| `terraform/modules/networking` | VNet, subnets, NSGs |

### Planned Environments

| Environment | Namespace | Purpose |
|---|---|---|
| `dev` | `resolveops-ai-dev` | Development + testing |
| `prod` | `resolveops-ai-prod` | Production |

---

## ACR Login Server

All scripts reference `$ACR_LOGIN_SERVER` — never hardcode the registry URL.

```bash
# Set in your shell or CI secrets:
export ACR_LOGIN_SERVER=resolveopsai.azurecr.io
```
