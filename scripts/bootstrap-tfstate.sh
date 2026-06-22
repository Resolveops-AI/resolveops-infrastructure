#!/bin/bash
set -e

# Load or set variables
RESOURCE_GROUP_NAME=${1:-"rg-resolveops-tfstate"}
STORAGE_ACCOUNT_NAME=${2:-"stresolveopstfstate01"}
CONTAINER_NAME=${3:-"tfstate"}
LOCATION=${4:-"centralindia"}

echo "Bootstrapping Terraform backend..."

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Assign Storage Blob Data Contributor role to the logged-in identity
echo "Assigning Storage Blob Data Contributor role to the active identity..."
STORAGE_ID=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --query id -o tsv)
ASSIGNEE=$(az account show --query user.name -o tsv)

# Retry loop since role assignment propagation might take a few seconds
for i in {1..3}; do
  az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$ASSIGNEE" \
    --scope "$STORAGE_ID" && break || sleep 5
done

# Enable blob versioning
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --enable-versioning true

echo "Terraform backend setup completed successfully."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"

echo ""
echo "Run the following command to initialize your Terraform backend locally:"
echo ""
echo "export ARM_USE_AZUREAD=true"
echo "export ARM_USE_CLI=true"
echo "terraform init \\"
echo "  -backend-config=\"resource_group_name=$RESOURCE_GROUP_NAME\" \\"
echo "  -backend-config=\"storage_account_name=$STORAGE_ACCOUNT_NAME\" \\"
echo "  -backend-config=\"container_name=$CONTAINER_NAME\" \\"
echo "  -backend-config=\"key=resolveops-platform-dev.tfstate\""
echo ""
