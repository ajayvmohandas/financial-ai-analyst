#!/bin/bash

# Azure Infrastructure Deployment Script
# This script deploys all necessary Azure resources for the Financial AI application

set -e

# Configuration
RESOURCE_GROUP_NAME="financial-ai-rg"
LOCATION="East US 2"
ACR_NAME="financialaiacr"
OPENAI_CHAT_NAME="financial-ai-openai-chat"
OPENAI_EMBEDDINGS_NAME="financial-ai-openai-embeddings"
STORAGE_ACCOUNT_NAME="financialaistorage"
APP_INSIGHTS_NAME="financial-ai-insights"
LOG_ANALYTICS_WORKSPACE_NAME="financial-ai-logs"
APP_SERVICE_PLAN_NAME="financial-ai-plan"
STAGING_APP_NAME="financial-ai-staging"
PRODUCTION_APP_NAME="financial-ai-prod"

echo "🚀 Starting Azure Infrastructure Deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Login to Azure (if not already logged in)
echo "🔐 Checking Azure authentication..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure:"
    az login
fi

# Set subscription (if multiple subscriptions available)
echo "📋 Setting subscription..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION_ID"

# Create Resource Group
echo "📦 Creating resource group..."
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --tags Environment=production Project=Financial-AI ManagedBy=Script

# Create Azure Container Registry
echo "🐳 Creating Azure Container Registry..."
az acr create \
    --name $ACR_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --sku Standard \
    --admin-enabled true \
    --tags Environment=production Project=Financial-AI Component=ACR

# Get ACR credentials
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

echo "🔑 ACR Credentials:"
echo "  Login Server: $ACR_LOGIN_SERVER"
echo "  Username: $ACR_USERNAME"
echo "  Password: [REDACTED]"

# Create Azure OpenAI for Chat
echo "🤖 Creating Azure OpenAI Chat resource..."
az cognitiveservices account create \
    --name $OPENAI_CHAT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --kind OpenAI \
    --sku S0 \
    --location $LOCATION \
    --tags Environment=production Project=Financial-AI Component=OpenAI-Chat

# Deploy GPT-4 model for chat
echo "🧠 Deploying GPT-4 model..."
az cognitiveservices account deployment create \
    --name $OPENAI_CHAT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --deployment-name gpt-4-chat \
    --model-name gpt-4 \
    --model-version "0613" \
    --model-format OpenAI \
    --sku-name Standard \
    --capacity 1

# Get OpenAI Chat details
OPENAI_CHAT_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_CHAT_NAME --resource-group $RESOURCE_GROUP_NAME --query endpoint -o tsv)
OPENAI_CHAT_KEY=$(az cognitiveservices account keys list --name $OPENAI_CHAT_NAME --resource-group $RESOURCE_GROUP_NAME --query key1 -o tsv)

# Create Azure OpenAI for Embeddings
echo "🔍 Creating Azure OpenAI Embeddings resource..."
az cognitiveservices account create \
    --name $OPENAI_EMBEDDINGS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --kind OpenAI \
    --sku S0 \
    --location $LOCATION \
    --tags Environment=production Project=Financial-AI Component=OpenAI-Embeddings

# Deploy text-embedding-ada-002 model
echo "📊 Deploying embeddings model..."
az cognitiveservices account deployment create \
    --name $OPENAI_EMBEDDINGS_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --deployment-name text-embedding-ada-002 \
    --model-name text-embedding-ada-002 \
    --model-version "2" \
    --model-format OpenAI \
    --sku-name Standard \
    --capacity 1

# Get OpenAI Embeddings details
OPENAI_EMBEDDINGS_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_EMBEDDINGS_NAME --resource-group $RESOURCE_GROUP_NAME --query endpoint -o tsv)
OPENAI_EMBEDDINGS_KEY=$(az cognitiveservices account keys list --name $OPENAI_EMBEDDINGS_NAME --resource-group $RESOURCE_GROUP_NAME --query key1 -o tsv)

# Create Storage Account
echo "💾 Creating Storage Account..."
az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2 \
    --tags Environment=production Project=Financial-AI Component=Storage

# Create file shares
echo "📁 Creating file shares..."
az storage share create \
    --account-name $STORAGE_ACCOUNT_NAME \
    --name vector-db \
    --quota 10

az storage share create \
    --account-name $STORAGE_ACCOUNT_NAME \
    --name documents \
    --quota 100

# Create Log Analytics Workspace
echo "📊 Creating Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --name $LOG_ANALYTICS_WORKSPACE_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --sku PerGB2018 \
    --retention-time 30 \
    --tags Environment=production Project=Financial-AI Component=Monitoring

# Get Log Analytics Workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show --name $LOG_ANALYTICS_WORKSPACE_NAME --resource-group $RESOURCE_GROUP_NAME --query customerId -o tsv)

# Create Application Insights
echo "🔍 Creating Application Insights..."
az monitor app-insights component create \
    --app $APP_INSIGHTS_NAME \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP_NAME \
    --application-type web \
    --workspace $WORKSPACE_ID \
    --tags Environment=production Project=Financial-AI Component=Monitoring

# Get Application Insights Key
APP_INSIGHTS_KEY=$(az monitor app-insights component show --app $APP_INSIGHTS_NAME --resource-group $RESOURCE_GROUP_NAME --query instrumentationKey -o tsv)

# Create App Service Plan
echo "🌐 Creating App Service Plan..."
az appservice plan create \
    --name $APP_SERVICE_PLAN_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --sku B3 \
    --is-linux \
    --tags Environment=production Project=Financial-AI Component=AppService

# Create Staging App Service
echo "🚀 Creating Staging App Service..."
az webapp create \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APP_SERVICE_PLAN_NAME \
    --name $STAGING_APP_NAME \
    --deployment-container-image-name nginx:latest \
    --tags Environment=staging Project=Financial-AI Component=AppService

# Configure Staging App Settings
echo "⚙️ Configuring Staging App Settings..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $STAGING_APP_NAME \
    --settings \
        WEBSITES_PORT=8501 \
        DOCKER_REGISTRY_SERVER_URL=$ACR_LOGIN_SERVER \
        DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
        DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD \
        AZURE_OPENAI_ENDPOINT=$OPENAI_CHAT_ENDPOINT \
        AZURE_OPENAI_API_KEY=$OPENAI_CHAT_KEY \
        AZURE_OPENAI_API_VERSION=2024-02-15-preview \
        AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat \
        AZURE_OPENAI_EMBEDDINGS_ENDPOINT=$OPENAI_EMBEDDINGS_ENDPOINT \
        AZURE_OPENAI_EMBEDDINGS_API_KEY=$OPENAI_EMBEDDINGS_KEY \
        AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002 \
        LANGSMITH_PROJECT=financial-ai-staging \
        LANGSMITH_TRACING=true \
        APPINSIGHTS_INSTRUMENTATIONKEY=$APP_INSIGHTS_KEY

# Create Production App Service
echo "🚀 Creating Production App Service..."
az webapp create \
    --resource-group $RESOURCE_GROUP_NAME \
    --plan $APP_SERVICE_PLAN_NAME \
    --name $PRODUCTION_APP_NAME \
    --deployment-container-image-name nginx:latest \
    --tags Environment=production Project=Financial-AI Component=AppService

# Configure Production App Settings
echo "⚙️ Configuring Production App Settings..."
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $PRODUCTION_APP_NAME \
    --settings \
        WEBSITES_PORT=8501 \
        DOCKER_REGISTRY_SERVER_URL=$ACR_LOGIN_SERVER \
        DOCKER_REGISTRY_SERVER_USERNAME=$ACR_USERNAME \
        DOCKER_REGISTRY_SERVER_PASSWORD=$ACR_PASSWORD \
        AZURE_OPENAI_ENDPOINT=$OPENAI_CHAT_ENDPOINT \
        AZURE_OPENAI_API_KEY=$OPENAI_CHAT_KEY \
        AZURE_OPENAI_API_VERSION=2024-02-15-preview \
        AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat \
        AZURE_OPENAI_EMBEDDINGS_ENDPOINT=$OPENAI_EMBEDDINGS_ENDPOINT \
        AZURE_OPENAI_EMBEDDINGS_API_KEY=$OPENAI_EMBEDDINGS_KEY \
        AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002 \
        LANGSMITH_PROJECT=financial-ai-production \
        LANGSMITH_TRACING=true \
        APPINSIGHTS_INSTRUMENTATIONKEY=$APP_INSIGHTS_KEY

# Get App URLs
STAGING_URL=$(az webapp show --name $STAGING_APP_NAME --resource-group $RESOURCE_GROUP_NAME --query defaultHostName -o tsv)
PRODUCTION_URL=$(az webapp show --name $PRODUCTION_APP_NAME --resource-group $RESOURCE_GROUP_NAME --query defaultHostName -o tsv)

echo ""
echo "✅ Infrastructure deployment completed successfully!"
echo ""
echo "📋 Resource Summary:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Location: $LOCATION"
echo ""
echo "🐳 Container Registry:"
echo "  Login Server: $ACR_LOGIN_SERVER"
echo "  Username: $ACR_USERNAME"
echo ""
echo "🤖 OpenAI Chat:"
echo "  Endpoint: $OPENAI_CHAT_ENDPOINT"
echo "  Deployment: gpt-4-chat"
echo ""
echo "🔍 OpenAI Embeddings:"
echo "  Endpoint: $OPENAI_EMBEDDINGS_ENDPOINT"
echo "  Deployment: text-embedding-ada-002"
echo ""
echo "💾 Storage:"
echo "  Account: $STORAGE_ACCOUNT_NAME"
echo "  File Shares: vector-db, documents"
echo ""
echo "🌐 Applications:"
echo "  Staging: https://$STAGING_URL"
echo "  Production: https://$PRODUCTION_URL"
echo ""
echo "📊 Monitoring:"
echo "  Application Insights: $APP_INSIGHTS_NAME"
echo "  Log Analytics: $LOG_ANALYTICS_WORKSPACE_NAME"
echo ""
echo "🔑 Important: Save these credentials securely!"
echo "  - ACR Password: [Check Azure Portal]"
echo "  - OpenAI Keys: [Check Azure Portal]"
echo "  - Storage Connection String: [Check Azure Portal]"
echo ""
echo "🚀 Next Steps:"
echo "  1. Build and push your Docker image to ACR"
echo "  2. Update the App Services to use your image"
echo "  3. Configure your domain and SSL certificates"
echo "  4. Set up monitoring and alerts"
