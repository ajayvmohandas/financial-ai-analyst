#!/bin/bash

# Azure DevOps Setup Script for Financial AI
# This script automates the complete setup process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="financial-ai-devops"
RESOURCE_GROUP="financial-ai-rg"
LOCATION="East US 2"
ACR_NAME="financialaiacr"

echo -e "${BLUE}🚀 Starting Azure DevOps Setup for Financial AI${NC}"
echo "=================================================="

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install it first.${NC}"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Step 1: Login to Azure
echo -e "${YELLOW}🔐 Azure Authentication${NC}"
echo "Please login to Azure:"
az login

# Set subscription
echo -e "${YELLOW}📋 Setting subscription...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Using subscription: $SUBSCRIPTION_ID"

# Step 2: Deploy Infrastructure
echo -e "${YELLOW}🏗️ Deploying Azure Infrastructure...${NC}"
echo "This will create: ACR, OpenAI resources, Storage, App Services, Monitoring"

# Run the infrastructure deployment script
if [ -f "scripts/deploy-infrastructure.sh" ]; then
    chmod +x scripts/deploy-infrastructure.sh
    ./scripts/deploy-infrastructure.sh
else
    echo -e "${RED}❌ Infrastructure deployment script not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"

# Step 3: Get Infrastructure Details
echo -e "${YELLOW}📊 Retrieving Infrastructure Details...${NC}"

ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

OPENAI_ENDPOINT=$(az cognitiveservices account show --name financial-ai-openai-chat --resource-group $RESOURCE_GROUP --query endpoint -o tsv)
OPENAI_KEY=$(az cognitiveservices account keys list --name financial-ai-openai-chat --resource-group $RESOURCE_GROUP --query key1 -o tsv)

OPENAI_EMBEDDINGS_ENDPOINT=$(az cognitiveservices account show --name financial-ai-openai-embeddings --resource-group $RESOURCE_GROUP --query endpoint -o tsv)
OPENAI_EMBEDDINGS_KEY=$(az cognitiveservices account keys list --name financial-ai-openai-embeddings --resource-group $RESOURCE_GROUP --query key1 -o tsv)

STAGING_URL=$(az webapp show --name financial-ai-staging --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)
PRODUCTION_URL=$(az webapp show --name financial-ai-prod --resource-group $RESOURCE_GROUP --query defaultHostName -o tsv)

# Step 4: Create .env file
echo -e "${YELLOW}⚙️ Creating environment configuration...${NC}"
cat > .env << EOF
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$OPENAI_KEY
AZURE_OPENAI_API_VERSION=2024-02-15-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat

# Azure OpenAI Embeddings
AZURE_OPENAI_EMBEDDINGS_ENDPOINT=$OPENAI_EMBEDDINGS_ENDPOINT
AZURE_OPENAI_EMBEDDINGS_API_KEY=$OPENAI_EMBEDDINGS_KEY
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002

# Storage Configuration
CHROMA_DB_PATH=./data/vector_db
DOCUMENT_STORAGE_PATH=./data/processed
RAW_DOCUMENT_PATH=./data/raw_documents

# Model Configuration
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2

# Logging Configuration
LOG_LEVEL=INFO

# LangSmith Configuration (optional - add your key)
# LANGSMITH_API_KEY=your-langsmith-key
# LANGSMITH_PROJECT=financial-ai-production
# LANGSMITH_TRACING=true
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

# Step 5: Initialize Git Repository
echo -e "${YELLOW}📦 Setting up Git repository...${NC}"

if [ ! -d ".git" ]; then
    git init
    git add .
    git commit -m "Initial commit - Financial AI with LangSmith integration"
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${YELLOW}⚠️ Git repository already exists${NC}"
fi

# Step 6: Azure DevOps Instructions
echo -e "${BLUE}🔧 Azure DevOps Setup Instructions${NC}"
echo "=================================================="
echo ""
echo "1. Create Azure DevOps Project:"
echo "   - Go to https://dev.azure.com"
echo "   - Create new project: '$PROJECT_NAME'"
echo "   - Visibility: Private"
echo ""
echo "2. Push Code to Azure DevOps:"
echo "   git remote add origin https://dev.azure.com/your-organization/$PROJECT_NAME/_git/$PROJECT_NAME"
echo "   git push -u origin main"
echo ""
echo "3. Configure Service Connections in Azure DevOps:"
echo "   - Docker Registry: '$ACR_LOGIN_SERVER'"
echo "   - Username: '$ACR_USERNAME'"
echo "   - Password: '$ACR_PASSWORD'"
echo ""
echo "4. Create Variable Groups:"
echo "   - Group: 'financial-ai-secrets'"
echo "   - Variables: AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, etc."
echo ""
echo "5. Run Pipeline:"
echo "   - Create pipeline from azure-pipelines.yml"
echo "   - Run pipeline to deploy application"
echo ""

# Step 7: Display Results
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}📊 Infrastructure Details:${NC}"
echo "  ACR Login Server: $ACR_LOGIN_SERVER"
echo "  ACR Username: $ACR_USERNAME"
echo "  ACR Password: [Check Azure Portal]"
echo "  OpenAI Endpoint: $OPENAI_ENDPOINT"
echo "  OpenAI Key: [Check Azure Portal]"
echo ""
echo -e "${BLUE}🌐 Application URLs:${NC}"
echo "  Staging: https://$STAGING_URL"
echo "  Production: https://$PRODUCTION_URL"
echo ""
echo -e "${BLUE}📁 Important Files Created:${NC}"
echo "  .env - Environment configuration"
echo "  DEPLOYMENT_GUIDE.md - Complete deployment guide"
echo ""
echo -e "${YELLOW}⚠️ Important Notes:${NC}"
echo "  1. Save your API keys securely"
echo "  2. Update azure-pipelines.yml with your service connection names"
echo "  3. Add LANGSMITH_API_KEY to .env for AI monitoring"
echo "  4. Configure Azure DevOps variable groups with secrets"
echo ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo "  1. Complete Azure DevOps project setup"
echo "  2. Push code to Azure DevOps"
echo "  3. Configure service connections and variable groups"
echo "  4. Run the deployment pipeline"
echo "  5. Monitor deployment in Azure DevOps and Azure Portal"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "  - Full Guide: DEPLOYMENT_GUIDE.md"
echo "  - Azure DevOps: https://docs.microsoft.com/azure/devops/"
echo "  - LangSmith: https://docs.smith.langchain.com/"
echo ""
echo -e "${GREEN}✨ Your Financial AI application is ready for deployment!${NC}"
