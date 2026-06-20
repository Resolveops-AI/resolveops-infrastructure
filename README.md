# ResolveOps AI — Infrastructure Repository

Centralized infrastructure scripts and IaC definitions for the ResolveOps AI platform and QuickHaul monitored workload.

---

## Architecture

```
┌──────────────────────────────┐     monitors     ┌──────────────────────────────┐
│       resolveops-aks         │ ───────────────▶ │        quickhaul-aks         │
│                              │                  │  namespace: argocd           │
│  namespace: resolveops       │                  │  namespace: monitoring       │
│  ┌──────────────────────┐    │                  │  ┌──────────────────────┐    │
│  │ frontend             │    │                  │  │ QuickHaul frontend   │    │
│  │ api-gateway          │    │                  │  │ backend services     │    │
│  │ auth-service         │    │                  │  │ MongoDB (in-cluster) │    │
│  │ github-intelligence  │    │                  │  │ Redis (in-cluster)   │    │
│  │ azure-intelligence   │    │                  │  └──────────────────────┘    │
│  │ aws-intelligence     │    │                  │                              │
│  │ ai-rca-service       │    │                  │  GitOps: Argo CD in argocd   │
│  │ notification-service │    │                  │  Monitors: Prometheus/Grafana in monitoring │
│  └──────────────────────┘    │                  │                              │
└──────────────────────────────┘                  └──────────────────────────────┘
        Cluster 1                                          Cluster 2
   (ResolveOps Platform)                             (QuickHaul Workload)
```

---

## Repository Structure

```text
scripts/
  bootstrap-tfstate.sh     # Set up Terraform remote backend
  build-and-push-acr.sh    # Build Docker images and push to ACR
  deploy-to-aks.sh         # Deploy services to AKS

terraform/
  modules/
    aks/                   # AKS cluster (reused for both clusters)
    acr/                   # Azure Container Registry (shared)
    networking/            # VNet + subnets
    key-vault/             # Key Vault with RBAC
    storage-account/       # Storage Account
    log-analytics/         # Log Analytics Workspace
    workload-identity/     # User Assigned Managed Identity + Federated Credential
    role-assignments/      # RBAC: AcrPull, KV Secrets User, Storage Contributor
    service-bus/           # Azure Service Bus (optional)
    kubernetes-namespaces/ # [NEW] Kubernetes namespace bootstrap module

  environments/
    dev/   → resolveops-aks cluster
             - namespace: resolveops
             - ACR, Key Vault, Storage, Workload Identity owned here

    prod/  → quickhaul-aks cluster
             - namespaces: quickhaul-dev, quickhaul-prod, argocd, monitoring
             - reads shared ACR via data source
             - Argo CD bootstrapped in argocd namespace by Helm
```

---

## Infrastructure as Code (Terraform)

### Cluster 1 — ResolveOps Platform (`environments/dev`)

- **Cluster**: `resolveops-aks` — Standard_B2s nodes, autoscale 1–3
- **Namespace**: `resolveops` — all ResolveOps microservices run here
- **ACR**: Shared registry — owned and managed in this environment
- **Key Vault**: ResolveOps platform secrets
- **Workload Identity**: Federated to the `resolveops` namespace

### Cluster 2 — QuickHaul Workload (`environments/prod`)

- **Cluster**: `quickhaul-aks` — Standard_B2s nodes, autoscale 1–3
- **Namespaces**: `quickhaul-dev`, `quickhaul-prod`, `argocd`, `monitoring`
- **ACR**: Shared registry — read via `data.azurerm_container_registry` (not managed here)
- **Key Vault**: QuickHaul app secrets
- **Workload Identity**: Federated to `quickhaul-dev` namespace
- **Argo CD**: Namespace bootstrapped by Terraform; installed by Helm

### Ownership Boundaries

| Layer | Owner | Examples |
|---|---|---|
| Azure infrastructure | **Terraform** | AKS, ACR, VNet, Key Vault, Role Assignments |
| Kubernetes namespaces | **Terraform** | `resolveops`, `quickhaul-dev`, `quickhaul-prod`, `argocd`, `monitoring` |
| Platform applications | **Helm (CI/CD)** | ResolveOps microservices chart |
| QuickHaul application | **Argo CD** | QuickHaul Helm chart, env promotion |
| Secrets values | **Key Vault + Workload Identity** | DB connections, API keys |

### CI/CD

A GitHub Actions workflow (`.github/workflows/terraform.yml`) runs on PRs and pushes to `main`. It enforces:
- `terraform fmt -check`
- `terraform validate`
- **Checkov Static Code Analysis** (hard fail on violations)
- `terraform plan` and `terraform apply`

---

## Quick Start

### 1. Bootstrap Terraform State Backend

```bash
chmod +x scripts/bootstrap-tfstate.sh
./scripts/bootstrap-tfstate.sh
```

### 2. Deploy ResolveOps Platform Cluster

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### 3. Deploy QuickHaul Cluster

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set acr_name and acr_resource_group_name to match step 2
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Variables

See the [IAC Implementation Report](IAC_IMPLEMENTATION_REPORT.md) for the full output-to-variable mapping.

---

## Scripts

### `scripts/build-and-push-acr.sh`

```bash
export ACR_LOGIN_SERVER=acrresolveops123.azurecr.io
chmod +x scripts/build-and-push-acr.sh
./scripts/build-and-push-acr.sh
```

### `scripts/deploy-to-aks.sh`

```bash
chmod +x scripts/deploy-to-aks.sh
./scripts/deploy-to-aks.sh
```
