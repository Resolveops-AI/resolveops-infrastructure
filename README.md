# ResolveOps AI — Infrastructure Repository

Centralized infrastructure scripts and IaC definitions for the ResolveOps AI platform.

---

## Repository Structure

```text
scripts/
  bootstrap-tfstate.sh     # Set up Terraform remote backend
  build-and-push-acr.sh    # Build all Docker images and push to ACR
  deploy-to-aks.sh         # Deploy all services to AKS
terraform/
  modules/
    aks/                   # AKS cluster with Workload Identity and OIDC
    acr/                   # Azure Container Registry
    networking/            # VNet + subnets module
    key-vault/             # Key Vault with RBAC
    storage-account/       # Storage Account
    log-analytics/         # Log Analytics Workspace
    workload-identity/     # User Assigned Managed Identity + Fed Credential
    role-assignments/      # Role assignments for Workload Identity and AKS
    service-bus/           # Azure Service Bus
  environments/
    dev/                   # Dev environment Terraform config
    prod/                  # Prod environment Terraform config
```

---

## Infrastructure as Code (Terraform)

The infrastructure for ResolveOps AI is fully managed via Terraform, utilizing Azure as the cloud provider. 

### Environments

- **`dev`**: Configured for low cost and testing. Uses Basic SKUs where possible, small VM sizes, and disabled expensive features.
- **`prod`**: Configured for production readiness with geo-redundancy, larger VM sizes, and Premium SKUs where required.

### CI/CD

A GitHub Actions workflow (`.github/workflows/terraform.yml`) runs on PRs and pushes to `main`. It enforces:
- `terraform fmt -check`
- `terraform validate`
- **Checkov Static Code Analysis** (blocking failure for any violations)
- `terraform plan` and `terraform apply`

### Outputs and Application Integration

See the [IAC Implementation Report](IAC_IMPLEMENTATION_REPORT.md) for details on the deployed resources and how Terraform outputs map to GitHub variables in the `resolveops-application` repository.

---

## Scripts

### `scripts/bootstrap-tfstate.sh`
Used to provision the Azure Resource Group, Storage Account, and Blob Container needed for Terraform's remote state backend. See [scripts/README.md](scripts/README.md).

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
Deploys all Kubernetes manifests to AKS.

```bash
chmod +x scripts/deploy-to-aks.sh
./scripts/deploy-to-aks.sh
```
