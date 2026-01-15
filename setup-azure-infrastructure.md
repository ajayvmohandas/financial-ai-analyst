# Azure Infrastructure Setup Guide

## 🏗️ Step 1: Create Azure Resources via Portal

### 1.1 Create Resource Group
1. Go to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" > "Resource Group"
3. **Name**: `financial-ai-rg`
4. **Region**: `East US 2`
5. Click "Review + create" > "Create"

### 1.2 Create Azure Container Registry (ACR)
1. In the resource group, click "Create a resource"
2. Search for "Container Registry"
3. Click "Create"
4. **Registry name**: `financialaiacr` (must be unique)
5. **Subscription**: Your subscription
6. **Resource group**: `financial-ai-rg`
7. **Location**: `East US 2`
8. **SKU**: `Basic`
9. Click "Review + create" > "Create"

### 1.3 Create App Service Plan
1. Click "Create a resource"
2. Search for "App Service Plan"
3. Click "Create"
4. **Name**: `financial-ai-plan`
5. **Subscription**: Your subscription
6. **Resource group**: `financial-ai-rg`
7. **OS**: `Linux`
8. **Region**: `East US 2`
9. **SKU and size**: `B1 (Basic)`
10. Click "Review + create" > "Create"

### 1.4 Create Web Apps (Staging & Production)
#### Staging App:
1. Click "Create a resource"
2. Search for "Web App"
3. Click "Create"
4. **Name**: `financial-ai-staging` (must be unique)
5. **Publish**: `Docker Container`
6. **Subscription**: Your subscription
7. **Resource group**: `financial-ai-rg`
8. **OS**: `Linux`
9. **Region**: `East US 2`
10. **App Service Plan**: `financial-ai-plan`
11. Click "Next: Docker >"
12. **Options**: `Single Container`
13. **Image Source**: `Docker Hub`
14. **Image and tag**: `nginx:latest` (temporary)
15. Click "Review + create" > "Create"

#### Production App:
1. Repeat the above steps with:
   - **Name**: `financial-ai-prod`
   - All other settings the same

## 🔧 Step 2: Configure GitHub Secrets

### 2.1 Get Azure Credentials
1. In Azure Portal, go to **Subscriptions**
2. Select your subscription
3. Click **Access control (IAM)** > **Add** > **Add role assignment**
4. **Role**: `Contributor`
5. **Assign access to**: `Managed identity`
6. **Members**: Select your account
7. Click **Review + assign**

### 2.2 Create Service Principal
```bash
# In Azure Cloud Shell (portal.azure.com > Cloud Shell)
az ad sp create-for-rbac --name "financial-ai-github" --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID --json-auth
```

This will output JSON like:
```json
{
  "clientId": "xxxxx",
  "clientSecret": "xxxxx",
  "subscriptionId": "xxxxx",
  "tenantId": "xxxxx"
}
```

### 2.3 Add Secrets to GitHub
1. Go to your GitHub repository
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Add these secrets:

#### Azure Credentials:
- **Name**: `AZURE_CREDENTIALS`
- **Value**: The JSON output from above

#### Azure OpenAI Settings:
- **Name**: `AZURE_OPENAI_ENDPOINT`
- **Value**: Your Azure OpenAI endpoint URL

- **Name**: `AZURE_OPENAI_API_KEY`
- **Value**: Your Azure OpenAI API key

- **Name**: `AZURE_OPENAI_CHAT_DEPLOYMENT`
- **Value**: `gpt-4-chat`

#### LangSmith Settings:
- **Name**: `LANGSMITH_API_KEY`
- **Value**: Your LangSmith API key

## 🚀 Step 3: Push to GitHub and Deploy

### 3.1 Create GitHub Repository
1. Go to [GitHub](https://github.com)
2. Click "New repository"
3. **Repository name**: `financial-ai-analyst`
4. **Description**: `Intelligent document processing and Q&A system for financial documents`
5. **Visibility**: Private or Public
6. Click "Create repository"

### 3.2 Push Your Code
```bash
# Add GitHub remote
git remote add origin https://github.com/yourusername/financial-ai-analyst.git
git branch -M main
git push -u origin main
```

### 3.3 Monitor Deployment
1. Go to your GitHub repository
2. Click **Actions** tab
3. Watch the workflow run
4. The pipeline will:
   - Build and test your code
   - Build Docker image
   - Deploy to staging (develop branch)
   - Deploy to production (main branch)

## 🌐 Step 4: Access Your Application

### Staging Environment:
- URL: `https://financial-ai-staging.azurewebsites.net`
- Deployed from `develop` branch

### Production Environment:
- URL: `https://financial-ai-prod.azurewebsites.net`
- Deployed from `main` branch

## 📊 Step 5: Monitor and Troubleshoot

### GitHub Actions:
- Go to **Actions** tab in your repository
- Click on workflow runs to see logs
- Check for any deployment errors

### Azure Portal:
- Go to **App Services**
- Select your app (staging or production)
- Check **Log stream** for real-time logs
- Review **Deployment Center** for deployment history

### LangSmith Monitoring:
- Go to [https://smith.langchain.com](https://smith.langchain.com)
- Monitor your AI operations and performance

## ✅ Success Checklist

- [ ] Resource group created
- [ ] Container Registry created
- [ ] App Service Plan created
- [ ] Web Apps created (staging & production)
- [ ] GitHub secrets configured
- [ ] Code pushed to GitHub
- [ ] GitHub Actions workflow running
- [ ] Application deployed and accessible
- [ ] LangSmith monitoring working

## 🎯 Next Steps

1. **Set up custom domains** for your apps
2. **Configure SSL certificates**
3. **Set up monitoring alerts**
4. **Configure backup and recovery**
5. **Add integration tests**
