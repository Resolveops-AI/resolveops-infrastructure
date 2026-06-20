# Infrastructure as Code (IaC) Implementation Report

This document outlines the Terraform setup for the ResolveOps AI Azure AKS capstone environment and explains how the Terraform outputs map to the required GitHub Actions variables in the `resolveops-application` repository.

## Overview

The infrastructure for the `dev` environment has been implemented using Terraform modules for standardization. The state is managed remotely using Azure Blob Storage.

Key components deployed:
- Resource Group
- Virtual Network & Subnets
- Azure Container Registry (ACR) - Basic SKU for dev
- Azure Kubernetes Service (AKS) - Includes Workload Identity and OIDC enabled
- Log Analytics Workspace (LAW)
- Key Vault - RBAC enabled
- Storage Account
- Azure Service Bus (Optional)

## GitHub Variables Mapping

Once Terraform has been successfully applied, several outputs are generated. These outputs must be copied to the `resolveops-application` repository's GitHub Variables and Secrets to enable the CI/CD pipelines to build, push, and deploy the application.

### Variables

| Terraform Output Name | Application GitHub Variable Name | Description |
|-----------------------|----------------------------------|-------------|
| `acr_login_server` | `ACR_LOGIN_SERVER` | The URL of the Azure Container Registry (e.g., `acrresolveopsdev123.azurecr.io`). |
| `acr_name` | `ACR_NAME` | The name of the Azure Container Registry (e.g., `acrresolveopsdev123`). |
| `resource_group_name` | `AZURE_RESOURCE_GROUP` | The name of the Azure Resource Group where the AKS cluster and ACR reside. |
| `aks_cluster_name` | `AKS_CLUSTER_NAME` | The name of the AKS cluster. |
| *(From tfvars)* | `AKS_NAMESPACE` | The target namespace for deployment in AKS (e.g., `resolveops-dev`). |
| `workload_identity_client_id` | `WORKLOAD_IDENTITY_CLIENT_ID` | The Client ID of the User Assigned Managed Identity used for Workload Identity. |
| `key_vault_name` | `KEY_VAULT_NAME` | The name of the Azure Key Vault used by the application. |
| `tenant_id` | `AZURE_TENANT_ID` | The Azure Active Directory Tenant ID. |

### Configuration Steps

1. Run the Terraform workflow for the `dev` environment or run it locally.
2. Observe the Terraform outputs at the end of the `terraform apply` stage.
3. In the `resolveops-application` GitHub repository, navigate to **Settings > Secrets and variables > Actions**.
4. Click on the **Variables** tab.
5. For each variable listed in the table above, click **New repository variable**, enter the corresponding GitHub Variable Name and the value from the Terraform output, and save.

## Security Controls

- **Checkov**: Static analysis is enforced on all PRs modifying `terraform/**`. It is configured for a hard fail on any policy violation.
- **Key Vault**: Uses RBAC authorization.
- **AKS**: Managed Identities are used for authentication (OIDC and Workload Identity), removing the need to manage Service Principal secrets. No local admin accounts are used.
