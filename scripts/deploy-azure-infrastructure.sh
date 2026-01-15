#!/bin/bash

# Azure Infrastructure Deployment Script for Financial AI Application
# This script sets up all necessary Azure resources for the FastAPI application

set -e

# Configuration
RESOURCE_GROUP="financial-ai-rg"
LOCATION="eastus"
ACR_NAME="financialaiacr"
APP_SERVICE_PLAN_STAGING="financial-ai-plan-staging"
APP_SERVICE_PLAN_PROD="financial-ai-plan-prod"
APP_SERVICE_STAGING="financial-ai-staging"
APP_SERVICE_PROD="financial-ai-prod"
STORAGE_ACCOUNT="financialaistorage"
KEY_VAULT="financial-ai-kv"
APP_INSIGHTS="financial-ai-insights"
LOG_ANALYTICS="financial-ai-logs"

echo "🚀 Starting Azure Infrastructure Deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Login to Azure (if not already logged in)
echo "🔐 Checking Azure authentication..."
az account show > /dev/null 2>&1 || {
    echo "Please login to Azure:"
    az login
}

# Create Resource Group
echo "📦 Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --tags "project=financial-ai" "environment=production"

# Create Azure Container Registry
echo "🐳 Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

# Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv)

echo "✅ ACR Login Server: $ACR_LOGIN_SERVER"

# Create App Service Plans
echo "🌐 Creating App Service Plans..."
az appservice plan create \
    --name $APP_SERVICE_PLAN_STAGING \
    --resource-group $RESOURCE_GROUP \
    --sku B1 \
    --is-linux \
    --location $LOCATION

az appservice plan create \
    --name $APP_SERVICE_PLAN_PROD \
    --resource-group $RESOURCE_GROUP \
    --sku P1v2 \
    --is-linux \
    --location $LOCATION

# Create Web Apps
echo "🚀 Creating Web Apps..."
az webapp create \
    --name $APP_SERVICE_STAGING \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN_STAGING \
    --deployment-container-image-name nginx:alpine

az webapp create \
    --name $APP_SERVICE_PROD \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN_PROD \
    --deployment-container-image-name nginx:alpine

# Configure Web Apps for containers
echo "⚙️ Configuring Web Apps..."
az webapp config container set \
    --name $APP_SERVICE_STAGING \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name $ACR_LOGIN_SERVER/financial-ai-app:latest \
    --docker-registry-server-url https://$ACR_LOGIN_SERVER \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD

az webapp config container set \
    --name $APP_SERVICE_PROD \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name $ACR_LOGIN_SERVER/financial-ai-app:latest \
    --docker-registry-server-url https://$ACR_LOGIN_SERVER \
    --docker-registry-server-user $ACR_USERNAME \
    --docker-registry-server-password $ACR_PASSWORD

# Set application settings
echo "🔧 Setting Application Configuration..."
az webapp config appsettings set \
    --name $APP_SERVICE_STAGING \
    --resource-group $RESOURCE_GROUP \
    --settings \
    WEBSITES_PORT=8000 \
    LANGSMITH_TRACING=true \
    LANGSMITH_PROJECT=financial-ai-staging

az webapp config appsettings set \
    --name $APP_SERVICE_PROD \
    --resource-group $RESOURCE_GROUP \
    --settings \
    WEBSITES_PORT=8000 \
    LANGSMITH_TRACING=true \
    LANGSMITH_PROJECT=financial-ai-production

# Create Storage Account
echo "💾 Creating Storage Account..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --access-tier Hot

# Get storage connection string
STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --query connectionString \
    --output tsv)

# Create Key Vault
echo "🔐 Creating Key Vault..."
az keyvault create \
    --name $KEY_VAULT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --enable-soft-delete true \
    --enable-purge-protection true

# Store secrets in Key Vault
echo "🔑 Storing Secrets in Key Vault..."
az keyvault secret set \
    --vault-name $KEY_VAULT \
    --name "acr-username" \
    --value $ACR_USERNAME

az keyvault secret set \
    --vault-name $KEY_VAULT \
    --name "acr-password" \
    --value $ACR_PASSWORD

az keyvault secret set \
    --vault-name $KEY_VAULT \
    --name "storage-connection-string" \
    --value $STORAGE_CONNECTION_STRING

# Create Application Insights
echo "📊 Creating Application Insights..."
az monitor app-insights component create \
    --app $APP_INSIGHTS \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --application-type web

# Get Application Insights instrumentation key
APP_INSIGHTS_KEY=$(az monitor app-insights component show \
    --app $APP_INSIGHTS \
    --resource-group $RESOURCE_GROUP \
    --query instrumentationKey \
    --output tsv)

# Store App Insights key in Key Vault
az keyvault secret set \
    --vault-name $KEY_VAULT \
    --name "app-insights-key" \
    --value $APP_INSIGHTS_KEY

# Enable Application Insights for Web Apps
echo "📈 Enabling Application Insights..."
az webapp config appsettings set \
    --name $APP_SERVICE_STAGING \
    --resource-group $RESOURCE_GROUP \
    --settings \
    APPINSIGHTS_INSTRUMENTATIONKEY=$APP_INSIGHTS_KEY \
    APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=$APP_INSIGHTS_KEY

az webapp config appsettings set \
    --name $APP_SERVICE_PROD \
    --resource-group $RESOURCE_GROUP \
    --settings \
    APPINSIGHTS_INSTRUMENTATIONKEY=$APP_INSIGHTS_KEY \
    APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=$APP_INSIGHTS_KEY

# Create Log Analytics Workspace
echo "📋 Creating Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --name $LOG_ANALYTICS \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --name $LOG_ANALYTICS \
    --resource-group $RESOURCE_GROUP \
    --query customerId \
    --output tsv)

# Store workspace ID in Key Vault
az keyvault secret set \
    --vault-name $KEY_VAULT \
    --name "log-analytics-workspace-id" \
    --value $WORKSPACE_ID

# Enable diagnostic settings
echo "🔍 Enabling Diagnostic Settings..."
az monitor diagnostic-settings create \
    --name $APP_SERVICE_STAGING \
    --resource $RESOURCE_GROUP \
    --resource-type Microsoft.Web/sites \
    --resource $APP_SERVICE_STAGING \
    --workspace $LOG_ANALYTICS \
    --metrics '[{"category": "AllMetrics", "enabled": true}]' \
    --logs '[{"category": "AppServiceAppLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}]'

az monitor diagnostic-settings create \
    --name $APP_SERVICE_PROD \
    --resource $RESOURCE_GROUP \
    --resource-type Microsoft.Web/sites \
    --resource $APP_SERVICE_PROD \
    --workspace $LOG_ANALYTICS \
    --metrics '[{"category": "AllMetrics", "enabled": true}]' \
    --logs '[{"category": "AppServiceAppLogs", "enabled": true}, {"category": "AppServiceConsoleLogs", "enabled": true}]'

# Get URLs
STAGING_URL=$(az webapp show \
    --name $APP_SERVICE_STAGING \
    --resource-group $RESOURCE_GROUP \
    --query defaultHostName \
    --output tsv)

PROD_URL=$(az webapp show \
    --name $APP_SERVICE_PROD \
    --resource-group $RESOURCE_GROUP \
    --query defaultHostName \
    --output tsv)

# Create output file with all important information
cat > azure-infrastructure-info.txt << EOF
🎉 Azure Infrastructure Deployment Complete!

📊 Resource Group: $RESOURCE_GROUP
🌐 Location: $LOCATION

🐳 Container Registry:
   - Name: $ACR_NAME
   - Login Server: $ACR_LOGIN_SERVER
   - Username: $ACR_USERNAME
   - Password: $ACR_PASSWORD

🚀 Web Apps:
   - Staging: https://$STAGING_URL
   - Production: https://$PROD_URL

💾 Storage Account: $STORAGE_ACCOUNT
🔐 Key Vault: $KEY_VAULT
📊 App Insights: $APP_INSIGHTS
📋 Log Analytics: $LOG_ANALYTICS

🔑 Important Secrets Stored in Key Vault:
   - acr-username
   - acr-password
   - storage-connection-string
   - app-insights-key
   - log-analytics-workspace-id

📝 Next Steps:
   1. Add your Azure OpenAI credentials to Key Vault
   2. Add your LangSmith API key to Key Vault
   3. Configure GitHub Actions secrets
   4. Push your code to GitHub to trigger deployment

🔧 GitHub Secrets Required:
   - AZURE_CREDENTIALS
   - AZURE_CONTAINER_REGISTRY: $ACR_LOGIN_SERVER
   - AZURE_CONTAINER_REGISTRY_USERNAME: $ACR_USERNAME
   - AZURE_CONTAINER_REGISTRY_PASSWORD: $ACR_PASSWORD

EOF

echo "✅ Infrastructure deployment completed!"
echo "📄 Check azure-infrastructure-info.txt for all details"
echo "🌐 Staging URL: https://$STAGING_URL"
echo "🌐 Production URL: https://$PROD_URL"
