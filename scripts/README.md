# ResolveOps Infrastructure Scripts

This directory contains utility scripts for managing the infrastructure lifecycle.

## Bootstrap Terraform State

The `bootstrap-tfstate.sh` script is used to set up the Azure resources required for Terraform's remote backend.

### Prerequisites
- Azure CLI installed (`az`)
- Logged into Azure (`az login`)

### Usage

Run the script to create the necessary Resource Group, Storage Account, and Blob Container. It uses default names if no arguments are provided.

```bash
./bootstrap-tfstate.sh [RESOURCE_GROUP_NAME] [STORAGE_ACCOUNT_NAME] [CONTAINER_NAME] [LOCATION]
```

Default values:
- Resource Group: `rg-resolveops-tfstate`
- Storage Account: `stresolveopstfstate`
- Container: `tfstate`
- Location: `eastus`
