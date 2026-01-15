#!/bin/bash

# Setup GitHub Secrets for Azure Deployment
# This script helps configure all necessary secrets in GitHub

set -e

# Configuration
GITHUB_REPO=""  # Set your GitHub repository (format: username/repo)
GITHUB_TOKEN="" # Set your GitHub personal access token

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 Setting up GitHub Secrets for Azure Deployment..."

# Check if required parameters are set
if [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ Please set GITHUB_REPO and GITHUB_TOKEN variables${NC}"
    echo "Example: GITHUB_REPO='username/financial-ai' GITHUB_TOKEN='your-token' ./setup-github-secrets.sh"
    exit 1
fi

# Function to set GitHub secret
set_github_secret() {
    local secret_name=$1
    local secret_value=$2
    
    echo -e "${YELLOW}🔑 Setting secret: $secret_name${NC}"
    
    curl -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/$GITHUB_REPO/actions/secrets/$secret_name \
        -d "{\"encrypted_value\":\"$(echo -n "$secret_value" | base64)\",\"key_id\":\"latest\"}" \
        -s > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Secret '$secret_name' set successfully${NC}"
    else
        echo -e "${RED}❌ Failed to set secret '$secret_name'${NC}"
    fi
}

# Get Azure credentials
echo "🔐 Getting Azure credentials..."

# Create service principal and get credentials
AZURE_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
AZURE_TENANT_ID=$(az account show --query tenantId --output tsv)

# Create service principal
echo "👤 Creating Azure Service Principal..."
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name "financial-ai-github-actions" \
    --role contributor \
    --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID \
    --json-output)

SP_APP_ID=$(echo $SP_OUTPUT | jq -r .appId)
SP_PASSWORD=$(echo $SP_OUTPUT | jq -r .password)

# Create Azure credentials JSON
AZURE_CREDENTIALS=$(cat << EOF
{
  "clientId": "$SP_APP_ID",
  "clientSecret": "$SP_PASSWORD",
  "subscriptionId": "$AZURE_SUBSCRIPTION_ID",
  "tenantId": "$AZURE_TENANT_ID"
}
EOF
)

# Get ACR information
ACR_NAME="financialaiacr"
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv 2>/dev/null || echo "")
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv 2>/dev/null || echo "")
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value --output tsv 2>/dev/null || echo "")

# Set GitHub secrets
echo "🚀 Setting GitHub secrets..."

set_github_secret "AZURE_CREDENTIALS" "$AZURE_CREDENTIALS"
set_github_secret "AZURE_SUBSCRIPTION_ID" "$AZURE_SUBSCRIPTION_ID"
set_github_secret "AZURE_TENANT_ID" "$AZURE_TENANT_ID"

if [ ! -z "$ACR_LOGIN_SERVER" ]; then
    set_github_secret "AZURE_CONTAINER_REGISTRY" "$ACR_LOGIN_SERVER"
    set_github_secret "AZURE_CONTAINER_REGISTRY_USERNAME" "$ACR_USERNAME"
    set_github_secret "AZURE_CONTAINER_REGISTRY_PASSWORD" "$ACR_PASSWORD"
fi

# Additional secrets (set these manually or provide as environment variables)
if [ ! -z "$AZURE_OPENAI_ENDPOINT" ]; then
    set_github_secret "AZURE_OPENAI_ENDPOINT" "$AZURE_OPENAI_ENDPOINT"
fi

if [ ! -z "$AZURE_OPENAI_API_KEY" ]; then
    set_github_secret "AZURE_OPENAI_API_KEY" "$AZURE_OPENAI_API_KEY"
fi

if [ ! -z "$LANGSMITH_API_KEY" ]; then
    set_github_secret "LANGSMITH_API_KEY" "$LANGSMITH_API_KEY"
fi

# Create setup information file
cat > github-secrets-info.txt << EOF
🎉 GitHub Secrets Setup Complete!

📊 Repository: $GITHUB_REPO

🔑 Secrets Set:
   - AZURE_CREDENTIALS
   - AZURE_SUBSCRIPTION_ID
   - AZURE_TENANT_ID
   - AZURE_CONTAINER_REGISTRY
   - AZURE_CONTAINER_REGISTRY_USERNAME
   - AZURE_CONTAINER_REGISTRY_PASSWORD

🔧 Additional Secrets to Add Manually:
   - AZURE_OPENAI_ENDPOINT
   - AZURE_OPENAI_API_KEY
   - LANGSMITH_API_KEY

📝 Next Steps:
   1. Verify secrets in GitHub repository settings
   2. Add any missing secrets manually
   3. Push code to trigger GitHub Actions workflow
   4. Monitor deployment in GitHub Actions tab

🌐 GitHub Repository: https://github.com/$GITHUB_REPO
⚡ GitHub Actions: https://github.com/$GITHUB_REPO/actions

EOF

echo -e "${GREEN}✅ GitHub secrets setup completed!${NC}"
echo "📄 Check github-secrets-info.txt for all details"
echo -e "${YELLOW}⚠️  Remember to add your Azure OpenAI and LangSmith API keys manually${NC}"
