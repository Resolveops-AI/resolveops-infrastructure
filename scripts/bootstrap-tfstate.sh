#!/bin/bash
set -e

# Load or set variables
RESOURCE_GROUP_NAME=${1:-"rg-resolveops-tfstate"}
STORAGE_ACCOUNT_NAME=${2:-"stresolveopstfstate"}
CONTAINER_NAME=${3:-"tfstate"}
LOCATION=${4:-"eastus"}

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

# Get storage account key
echo "Retrieving storage account key..."
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' \
  -o tsv)

# Create blob container
echo "Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

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
