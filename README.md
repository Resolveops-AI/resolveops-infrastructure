# ResolveOps AI — Infrastructure Repository

Centralized infrastructure scripts and IaC definitions for the ResolveOps AI platform and QuickHaul monitored workload.

> [!WARNING]
> The `terraform/environments/dev` and `terraform/environments/prod` directories are **deprecated** and have been superseded by the unified platform layout in `terraform/platform`. Do not use them for new deployments.

---

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                   resolveops-aks-01                    │
│                                                        │
│  namespace: resolveops                                 │
│  ┌──────────────────────┐   namespace: quickhaul-dev   │
│  │ frontend             │   namespace: quickhaul-prod  │
│  │ api-gateway          │   namespace: argocd          │
│  │ auth-service         │   namespace: monitoring      │
│  │ github-intelligence  │   ┌──────────────────────┐   │
│  │ azure-intelligence   │   │ QuickHaul frontend   │   │
│  │ aws-intelligence     │   │ backend services     │   │
│  │ ai-rca-service       │   │ MongoDB (in-cluster) │   │
│  │ notification-service │   │ Redis (in-cluster)   │   │
│  └──────────────────────┘   └──────────────────────┘   │
│                                                        │
│  Ingress: Application Gateway with AGIC                │
│  Domains: resolveops-ai.sathvikdevops.online           │
│           quickhaul.sathvikdevops.site                 │
└────────────────────────────────────────────────────────┘
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

  environments/          # [DEPRECATED] Former env structure, superseded by terraform/platform
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

### Shared Cluster (`terraform/platform`)

Due to Azure quota and resource limitations, both ResolveOps and QuickHaul applications run inside one shared AKS cluster (`resolveops-aks-01`). Isolation is achieved using Kubernetes namespaces. Ingress is handled by a single Application Gateway via AGIC.

- **Cluster**: `resolveops-aks-01`
- **Namespaces**: `resolveops`, `quickhaul-dev`, `quickhaul-prod`, `argocd`, `monitoring`
- **ACR**: Shared registry for all applications
- **Key Vault**: Shared key vault for platform secrets
- **Workload Identity**: Federated to the `resolveops` namespace
- **Argo CD**: Installed in `argocd` namespace for GitOps
- **Ingress**: One Application Gateway with AGIC used for both `resolveops-ai.sathvikdevops.online` and `quickhaul.sathvikdevops.site`

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

### 2. Deploy Infrastructure Platform

```bash
cd terraform/platform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Variables

See the [IAC Implementation Report](IAC_IMPLEMENTATION_REPORT.md) for the full output-to-variable mapping.

---

## Deploying to a Different Azure Account

To deploy the same architecture to a new Azure subscription/tenant without modifying the Terraform architecture:

1. **Authenticate**:
   ```bash
   az login
   az account show
   ```
   Confirm your subscription ID and tenant ID.

2. **Bootstrap the Terraform Backend**:
   Run the bootstrap script to create the new remote state storage:
   ```bash
   chmod +x scripts/bootstrap-tfstate.sh
   ./scripts/bootstrap-tfstate.sh rg-resolveops-tfstate-dev stresolveopstfstate<unique> tfstate centralindia
   ```
   *Note: Ensure your storage account name is globally unique and only contains lowercase letters and numbers.*

3. **Export Local Authentication Variables**:
   ```bash
   export ARM_USE_AZUREAD=true
   export ARM_USE_CLI=true
   ```

4. **Update Configuration**:
   ```bash
   cd terraform/platform
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` and update only the account-specific values. 

5. **Deploy**:
   ```bash
   terraform fmt
   terraform init \
     -backend-config="resource_group_name=rg-resolveops-tfstate-dev" \
     -backend-config="storage_account_name=stresolveopstfstate<unique>" \
     -backend-config="container_name=tfstate" \
     -backend-config="key=resolveops-platform-dev.tfstate"
   
   terraform validate
   terraform plan
   terraform apply
   ```

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

  ---

  ## Deployment to Private AKS via GitHub Actions

  Because the AKS clusters are configured as **Private Clusters** (`private_cluster_enabled = true`), the Kubernetes API server is completely isolated from the public internet. Standard GitHub Actions runners (which run on public IPs) **cannot** run `kubectl` or `helm` commands directly against the cluster.

  To deploy to the private AKS clusters via GitHub Actions, you must use one of the following approaches:

  1. **Self-Hosted Runner in the VNet (Recommended):** Deploy a GitHub Actions self-hosted runner on a VM inside the `vnet-resolveops-platform` Virtual Network. The runner will have private network line-of-sight to the AKS API.
  2. **GitOps via Argo CD (Implemented for QuickHaul):** Argo CD runs *inside* the private cluster and pulls changes directly from the GitHub repository. GitHub Actions only needs to update the Kubernetes manifests in the repository, and Argo CD handles the actual deployment.
  3. **Azure Bastion Jumpbox:** For manual administrative tasks and troubleshooting, use Azure Bastion to securely SSH into the internal `resolveops-jumpbox` VM. From the jumpbox, you can run `kubectl` commands against the private clusters. You can retrieve the Jumpbox SSH private key from the Terraform output: `terraform output -raw jumpbox_ssh_private_key`.

## Messaging and Asynchronous Workflows
* **Service Bus**: Used for durable asynchronous workflows. It is an Azure-managed durable messaging service.
  * **Cost Control**: Service Bus Standard SKU is used to control costs.
  * **Private Link**: Service Bus private endpoint is not configured because Private Link requires the Premium tier.
  * **Production Recommendation**: For production, upgrade Service Bus to Premium, enable Private Endpoint, and link "privatelink.servicebus.windows.net".
  * **Queues used**:
    * Notification service: "notification-requested"
    * AI RCA flow: "rca-requested", "rca-completed"
    * Sync flows: "github-sync-requested", "azure-sync-requested", "aws-sync-requested"
* **RabbitMQ**: Used for fast internal worker queues inside AKS.
