# Infrastructure as Code (IaC) Implementation Report

This document describes the Terraform infrastructure for the ResolveOps AI + QuickHaul Transits
two-cluster AKS architecture and explains how outputs map to GitHub Actions variables.

---

## Architecture Overview

ResolveOps AI uses **two dedicated AKS clusters**:

| Cluster | Name | Purpose |
|---|---|---|
| ResolveOps Platform | `resolveops-aks` | Hosts all ResolveOps AI microservices |
| QuickHaul Workload | `quickhaul-aks` | Hosts QuickHaul Transits app (monitored workload) |

### Why Two Clusters?

| Concern | Reason |
|---|---|
| **Blast radius isolation** | A broken ResolveOps deploy cannot take down the monitored QuickHaul cluster |
| **Monitoring independence** | ResolveOps monitors QuickHaul cross-cluster via Azure Monitor and Prometheus remote_write |
| **RBAC isolation** | Each cluster has its own RBAC; QuickHaul team cannot access ResolveOps secrets |
| **GitOps clarity** | Argo CD runs in `quickhaul-aks` and manages only QuickHaul. ResolveOps CI/CD is separate |
| **Demo cost** | Both clusters use `Standard_B2s` with min 1 node — minimal cost |

---

## Namespace Design

| Cluster | Namespace | Managed By | Purpose |
|---|---|---|---|
| `resolveops-aks` | `resolveops` | Terraform creates · Helm deploys | All ResolveOps AI platform services |
| `quickhaul-aks` | `quickhaul-dev` | Terraform creates · Argo CD deploys | QuickHaul dev environment |
| `quickhaul-aks` | `quickhaul-prod` | Terraform creates · Argo CD deploys | QuickHaul prod environment |
| `quickhaul-aks` | `argocd` | Terraform creates · Helm bootstraps | Argo CD GitOps controller |

### Why ResolveOps Has One Namespace

ResolveOps is an **operations platform**, not a customer-facing application with stages.
It does not need dev/prod namespace separation — it is always "the monitoring platform."
Separating it would add complexity with no operational benefit.

### Why QuickHaul Has Two Namespaces

QuickHaul is the **monitored workload**. Argo CD manages separate GitOps environments
(`quickhaul-dev` and `quickhaul-prod`) from the same cluster so developers can promote
changes through environments with full isolation.

---

## What Terraform Owns

- Azure Resource Groups
- Virtual Networks and Subnets
- Azure Container Registry (ACR) — one shared registry
- AKS Clusters (`resolveops-aks`, `quickhaul-aks`)
- Log Analytics Workspaces
- Key Vaults
- Storage Accounts
- User Assigned Managed Identities (Workload Identity)
- Azure Role Assignments (AcrPull, Key Vault Secrets User, Storage Blob Data Contributor)
- Kubernetes Namespace objects (bootstrap only — no workloads)

## What Helm / Argo CD Owns

- All Kubernetes Deployments
- All Kubernetes Services
- All Kubernetes ConfigMaps and Secrets
- Argo CD installation (via Helm into the `argocd` namespace)
- QuickHaul application charts (deployed by Argo CD from `quickhaul-dev` and `quickhaul-prod`)
- ResolveOps microservice charts (deployed by Helm CI/CD into `resolveops`)

---

## How ResolveOps Monitors QuickHaul

ResolveOps AI monitors the QuickHaul cluster cross-cluster using:

1. **Azure Monitor / Container Insights** — both clusters ship metrics/logs to their respective
   Log Analytics Workspaces. ResolveOps reads these via Azure Monitor APIs.
2. **Prometheus remote_write** (future) — QuickHaul's in-cluster Prometheus can be configured
   to remote_write to the ResolveOps Prometheus/Thanos endpoint.
3. **GitHub Intelligence Service** — ResolveOps reads QuickHaul GitHub events (commits, PRs, incidents)
   to correlate deployments with anomalies.

---

## Terraform Structure

```text
terraform/
  modules/
    aks/                        # AKS cluster — reused for both clusters
    acr/                        # Azure Container Registry
    networking/                 # VNet + subnets
    key-vault/                  # Key Vault with RBAC
    storage-account/            # Storage Account
    log-analytics/              # Log Analytics Workspace
    workload-identity/          # User Assigned Managed Identity + Fed Credential
    role-assignments/           # RBAC role assignments
    service-bus/                # Azure Service Bus (optional)
    kubernetes-namespaces/      # [NEW] Creates K8s namespaces — used by both envs
  environments/
    dev/   → resolveops cluster # resolveops-aks + resolveops namespace + ACR + KV
    prod/  → quickhaul cluster  # quickhaul-aks + quickhaul-dev/prod/argocd namespaces
```

---

## GitHub Variables Mapping

### ResolveOps Environment (`terraform/environments/dev`)

| Terraform Output | GitHub Variable | Description |
|---|---|---|
| `resolveops_aks_name` | `AKS_CLUSTER_NAME` | ResolveOps AKS cluster name |
| `acr_name` | `ACR_NAME` | Shared ACR name |
| `acr_login_server` | `ACR_LOGIN_SERVER` | Shared ACR login server URL |
| `resource_group_name` | `AZURE_RESOURCE_GROUP` | ResolveOps resource group |
| `resolveops_namespace` | `AKS_NAMESPACE` | Kubernetes namespace for ResolveOps |
| `workload_identity_client_id` | `WORKLOAD_IDENTITY_CLIENT_ID` | Workload Identity Client ID |
| `key_vault_name` | `KEY_VAULT_NAME` | ResolveOps Key Vault |
| `tenant_id` | `AZURE_TENANT_ID` | Azure Tenant ID |

### QuickHaul Environment (`terraform/environments/prod`)

| Terraform Output | GitHub Variable | Description |
|---|---|---|
| `quickhaul_aks_name` | `QUICKHAUL_AKS_CLUSTER_NAME` | QuickHaul AKS cluster name |
| `acr_name` | `ACR_NAME` | Shared ACR name |
| `acr_login_server` | `ACR_LOGIN_SERVER` | Shared ACR login server URL |
| `resource_group_name` | `QUICKHAUL_RESOURCE_GROUP` | QuickHaul resource group |
| `quickhaul_dev_namespace` | `QUICKHAUL_DEV_NAMESPACE` | QuickHaul dev namespace |
| `quickhaul_prod_namespace` | `QUICKHAUL_PROD_NAMESPACE` | QuickHaul prod namespace |
| `argocd_namespace` | `ARGOCD_NAMESPACE` | Argo CD namespace |
| `tenant_id` | `AZURE_TENANT_ID` | Azure Tenant ID |

---

## Security Controls

- **Checkov**: Static analysis enforced on all PRs to `terraform/**`. Hard fail on violations.
- **Key Vault**: RBAC authorization. No access policy mode.
- **AKS**: Managed Identities (OIDC + Workload Identity). No local admin accounts, no service principal secrets.
- **ACR**: AcrPull is granted to both AKS kubelet identities — no admin credentials needed.
- **Secrets**: No secrets are hardcoded. All credentials flow through Workload Identity federation.
