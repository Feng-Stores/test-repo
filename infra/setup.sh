#!/bin/bash
# Creates all Azure resources needed for the test app.
# Override any variable by setting it before running:
#   LOCATION=eastus RG=my-rg ./infra/setup.sh
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
RG="${RG:-test-rg}"
LOCATION="${LOCATION:-westeurope}"
CA_ENV="${CA_ENV:-test-env}"
CA_APP="${CA_APP:-test-backend}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-testfrontend001}"  # override if name is taken

# Subscription to deploy into — required
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-6dae2b1a-88d7-4a40-ae2c-1f7ffcd2df7d}"
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "ERROR: set SUBSCRIPTION_ID before running this script"
  exit 1
fi

# Tenant ID — same value as AZURE_TENANT_ID in your GitHub secrets
TENANT_ID="${TENANT_ID:-9192f42a-01ed-4eca-9931-6f5594c7e626}"
if [[ -z "$TENANT_ID" ]]; then
  echo "ERROR: set TENANT_ID before running this script"
  exit 1
fi

# ── Login ─────────────────────────────────────────────────────────────────────
echo "==> Logging in to Azure"
az login --tenant "$TENANT_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# ── Resource providers ────────────────────────────────────────────────────────
echo "==> Registering resource providers (may take a minute)"
az provider register -n Microsoft.App --wait -o none
az provider register -n Microsoft.OperationalInsights --wait -o none
az provider register -n Microsoft.Storage --wait -o none

# ── Resource group ─────────────────────────────────────────────────────────────
echo "==> Creating resource group: $RG"
az group create -n "$RG" -l "$LOCATION" -o none

# ── Container Apps ─────────────────────────────────────────────────────────────
if ! az containerapp env show -g "$RG" -n "$CA_ENV" &>/dev/null; then
  echo "==> Creating Container Apps environment: $CA_ENV"
  az containerapp env create -g "$RG" -n "$CA_ENV" -l "$LOCATION" -o none
else
  echo "==> Container Apps environment already exists: $CA_ENV"
fi

if ! az containerapp show -g "$RG" -n "$CA_APP" &>/dev/null; then
  echo "==> Creating Container App: $CA_APP"
  az containerapp create -g "$RG" -n "$CA_APP" \
    --environment "$CA_ENV" \
    --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
    --target-port 3000 \
    --ingress external \
    -o none
else
  echo "==> Container App already exists: $CA_APP"
fi

# ── Storage account (static website) ──────────────────────────────────────────
if ! az storage account show -g "$RG" -n "$STORAGE_ACCOUNT" --subscription "$SUBSCRIPTION_ID" &>/dev/null; then
  echo "==> Creating storage account: $STORAGE_ACCOUNT"
  az storage account create \
    -g "$RG" -n "$STORAGE_ACCOUNT" -l "$LOCATION" \
    --subscription "$SUBSCRIPTION_ID" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access true \
    -o none

  echo "==> Enabling static website"
  az storage blob service-properties update \
    --account-name "$STORAGE_ACCOUNT" \
    --subscription "$SUBSCRIPTION_ID" \
    --static-website \
    --index-document index.html \
    --404-document index.html \
    -o none
else
  echo "==> Storage account already exists: $STORAGE_ACCOUNT"
fi

# ── Output ─────────────────────────────────────────────────────────────────────
BACKEND_FQDN=$(az containerapp show -g "$RG" -n "$CA_APP" \
  --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_URL=$(az storage account show -g "$RG" -n "$STORAGE_ACCOUNT" \
  --query "primaryEndpoints.web" -o tsv)

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  GitHub Actions — Variables (Settings → Variables → Actions)"
echo "════════════════════════════════════════════════════════════"
echo "  RESOURCE_GROUP       = $RG"
echo "  CONTAINER_APP_NAME   = $CA_APP"
echo "  STORAGE_ACCOUNT_NAME = $STORAGE_ACCOUNT"
echo "  BACKEND_URL          = https://$BACKEND_FQDN"
echo ""
echo "  App URLs"
echo "  Frontend : $FRONTEND_URL"
echo "  Backend  : https://$BACKEND_FQDN"
echo "════════════════════════════════════════════════════════════"
