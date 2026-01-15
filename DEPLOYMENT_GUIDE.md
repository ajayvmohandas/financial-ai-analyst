# 🚀 Complete Azure DevOps Deployment Guide

This guide will walk you through setting up Azure DevOps, pushing code, configuring, deploying, and visualizing the Financial AI application.

## 📋 Prerequisites

- Azure Subscription with Owner permissions
- Azure DevOps organization
- Docker installed locally
- Git installed locally

---

## 🏗️ Step 1: Azure Infrastructure Setup

### 1.1 Deploy Azure Resources

```bash
# Navigate to project folder
cd IDP-FINANCIAL-ANALYST

# Make deployment script executable (Linux/Mac)
chmod +x scripts/deploy-infrastructure.sh

# Run infrastructure deployment
./scripts/deploy-infrastructure.sh
```

**Or use Terraform:**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 1.2 Save Generated Credentials

After deployment, save these values securely:
- ACR Login Server, Username, Password
- OpenAI Endpoints and API Keys
- Storage Connection String
- Application Insights Key

---

## 🔧 Step 2: Azure DevOps Project Setup

### 2.1 Create Azure DevOps Project

1. Go to [https://dev.azure.com](https://dev.azure.com)
2. Sign in with your Azure account
3. Click **"New Project"**
4. **Project name**: `financial-ai-devops`
5. **Visibility**: Private
6. Click **"Create"**

### 2.2 Initialize Git Repository

```bash
# Navigate to project folder
cd IDP-FINANCIAL-ANALYST

# Initialize git
git init
git add .
git commit -m "Initial commit - Financial AI with LangSmith integration"

# Add Azure DevOps remote
git remote add origin https://dev.azure.com/your-organization/financial-ai-devops/_git/financial-ai-devops

# Push to Azure DevOps
git push -u origin main
```

### 2.3 Configure Service Connections

#### A. Container Registry Service Connection

1. In Azure DevOps, go to **Project Settings** > **Service connections**
2. Click **"New service connection"**
3. Select **"Docker Registry"**
4. Choose **"Azure Container Registry"**
5. Select your Azure subscription
6. Choose the ACR created in Step 1
7. **Service connection name**: `financial-ai-acr`
8. Click **"Save"**

#### B. Azure Resource Manager Service Connection

1. Click **"New service connection"**
2. Select **"Azure Resource Manager"**
3. Choose **"Service principal (automatic)"**
4. Select your Azure subscription
5. **Resource group**: `financial-ai-rg`
6. **Service connection name**: `financial-ai-subscription`
7. Click **"Save"**

### 2.4 Create Variable Groups

#### A. Secrets Variable Group

1. Go to **Pipelines** > **Library**
2. Click **"+ Variable group"**
3. **Name**: `financial-ai-secrets`
4. **Keep values secret**: ✅ Checked
5. Add these variables:

| Variable Name | Value |
|---------------|-------|
| `AZURE_OPENAI_ENDPOINT` | Your OpenAI endpoint |
| `AZURE_OPENAI_API_KEY` | Your OpenAI API key |
| `AZURE_OPENAI_CHAT_DEPLOYMENT` | `gpt-4-chat` |
| `AZURE_OPENAI_EMBEDDINGS_ENDPOINT` | Your embeddings endpoint |
| `AZURE_OPENAI_EMBEDDINGS_API_KEY` | Your embeddings API key |
| `AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT` | `text-embedding-ada-002` |
| `LANGSMITH_API_KEY` | Your LangSmith API key |
| `LANGSMITH_PROJECT` | `financial-ai-production` |

6. Click **"Save"**

#### B. Configuration Variable Group

1. Create another variable group
2. **Name**: `financial-ai-config`
3. **Keep values secret**: ❌ Unchecked
4. Add these variables:

| Variable Name | Value |
|---------------|-------|
| `dockerRegistryServiceConnection` | `financial-ai-acr` |
| `imageRepository` | `financial-ai-app` |
| `containerRegistry` | `your-acr-name.azurecr.io` |
| `tag` | `$(Build.BuildId)` |

---

## 🚀 Step 3: Configure Azure DevOps Pipeline

### 3.1 Create Pipeline

1. In Azure DevOps, go to **Pipelines**
2. Click **"New pipeline"**
3. Select **"Azure Repos Git"**
4. Choose your repository
5. Select **"Existing Azure Pipelines YAML file"**
6. Choose **`azure-pipelines.yml`**
7. Click **"Continue"** then **"Save and run"**

### 3.2 Update Pipeline Configuration

Edit the `azure-pipelines.yml` to match your service connection names:

```yaml
variables:
  - group: financial-ai-secrets
  - group: financial-ai-config
  - name: dockerRegistryServiceConnection
    value: 'financial-ai-acr'  # Update if different
  - name: azureSubscription
    value: 'financial-ai-subscription'  # Update if different
```

---

## 🎯 Step 4: Run Deployment Pipeline

### 4.1 Trigger Pipeline

1. Go to **Pipelines** > **Builds**
2. Select your pipeline
3. Click **"Run pipeline"**
4. Choose branch: `main`
5. Click **"Run"**

### 4.2 Monitor Pipeline Stages

The pipeline will execute these stages:

1. **Validate** ✅
   - Code linting and formatting
   - Type checking

2. **Test** ✅
   - Unit tests execution
   - Coverage reporting

3. **Security** ✅
   - Vulnerability scanning
   - Security analysis

4. **BuildImage** ✅
   - Docker image creation
   - Push to Azure Container Registry

5. **DeployStaging** ✅
   - Deploy to staging environment
   - Health checks

6. **DeployProduction** ✅
   - Deploy to production (main branch only)

---

## 🌐 Step 5: Configure Application Settings

### 5.1 Staging Environment

1. Go to **Azure Portal** > **App Services**
2. Select `financial-ai-staging`
3. Go to **Configuration** > **Application settings**
4. Add/verify these settings:

```bash
WEBSITES_PORT=8501
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=financial-ai-staging
```

### 5.2 Production Environment

1. Select `financial-ai-prod`
2. Go to **Configuration** > **Application settings**
3. Add/verify these settings:

```bash
WEBSITES_PORT=8501
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=financial-ai-production
```

---

## 📊 Step 6: Visualization and Monitoring

### 6.1 Access Your Application

**Staging Environment:**
- URL: `https://financial-ai-staging.azurewebsites.net`
- Test with sample documents and questions

**Production Environment:**
- URL: `https://financial-ai-prod.azurewebsites.net`
- Production-ready application

### 6.2 LangSmith Monitoring

1. Go to [https://smith.langchain.com](https://smith.langchain.com)
2. Sign in with your LangSmith account
3. Select your project: `financial-ai-production`
4. Monitor:
   - **Traces**: All AI operations and executions
   - **Performance**: Response times and token usage
   - **Errors**: Failed operations and exceptions
   - **Costs**: API usage and costs

### 6.3 Azure Monitoring

#### Application Insights

1. Go to **Azure Portal** > **Application Insights**
2. Select `financial-ai-insights`
3. Monitor:
   - **Application Map**: Service dependencies
   - **Performance**: Response times and throughput
   - **Failures**: Errors and exceptions
   - **Metrics**: CPU, memory, request rates

#### Log Analytics

1. Go to **Azure Portal** > **Log Analytics workspace**
2. Select `financial-ai-logs`
3. Run queries:

```kql
// Application logs
AppExceptions
| where TimeGenerated > ago(1h)
| summarize count() by type, outerMessage

// Performance metrics
AppRequests
| where TimeGenerated > ago(1h)
| summarize avg(DurationMs) by name
```

---

## 🔍 Step 7: Testing and Validation

### 7.1 Test Document Upload

1. Navigate to your application URL
2. Go to **"📄 Document Upload"** tab
3. Upload a financial document (PDF, DOCX, XLSX)
4. Verify processing completes successfully
5. Check LangSmith for trace events

### 7.2 Test Q&A Chatbot

1. Go to **"💬 Q&A Chatbot"** tab
2. Ask questions like:
   - "What was Apple's revenue in 2023?"
   - "Show me Microsoft's financial metrics"
   - "What are the risks mentioned in Amazon's 10-K?"
3. Verify answers are generated
4. Check sources and company identification

### 7.3 Monitor Performance

1. **LangSmith Dashboard**:
   - Check trace latency
   - Monitor token usage
   - Review error rates

2. **Azure Monitor**:
   - Check application response times
   - Monitor resource utilization
   - Review error logs

---

## 🛠️ Step 8: Troubleshooting Common Issues

### 8.1 Pipeline Failures

**Build Failures:**
```bash
# Check logs in Azure DevOps
# Verify requirements.txt is complete
# Check Dockerfile syntax
```

**Test Failures:**
```bash
# Run tests locally
cd IDP-FINANCIAL-ANALYST
pip install -r requirements.txt
pytest tests/ -v
```

**Deployment Failures:**
```bash
# Check Azure App Service logs
# Verify environment variables
# Check container health
```

### 8.2 Application Issues

**LangSmith Not Working:**
```bash
# Verify LANGSMITH_API_KEY is correct
# Check LANGSMITH_TRACING=true
# Verify network connectivity
```

**Azure OpenAI Issues:**
```bash
# Verify API keys and endpoints
# Check deployment names
# Verify API version compatibility
```

---

## 📈 Step 9: Scaling and Optimization

### 9.1 Horizontal Scaling

```bash
# Scale out App Service
az webapp scale rule create \
  --resource-group financial-ai-rg \
  --name financial-ai-prod \
  --custom-rule "cpu" \
  --metric-name "CpuPercentage" \
  --operator "GreaterThan" \
  --threshold "70" \
  --action "ScaleOut" \
  --count "1" \
  --cooldown "5"
```

### 9.2 Performance Optimization

1. **Enable Application Insights Profiler**
2. **Configure Redis caching**
3. **Enable CDN for static assets**
4. **Optimize database queries**

---

## 🎉 Step 10: Success Verification

### ✅ Checklist

- [ ] Infrastructure deployed successfully
- [ ] Code pushed to Azure DevOps
- [ ] Pipeline runs without errors
- [ ] Application accessible in staging
- [ ] Application accessible in production
- [ ] LangSmith tracing working
- [ ] Azure monitoring configured
- [ ] Document upload functional
- [ ] Q&A chatbot working
- [ ] Performance metrics visible

### 🎯 Next Steps

1. **Set up alerts** in Azure Monitor
2. **Configure backup** for storage accounts
3. **Set up custom domains** and SSL certificates
4. **Implement CI/CD for feature branches**
5. **Add integration tests** for end-to-end validation

---

## 📞 Support and Resources

- **Azure DevOps Documentation**: https://docs.microsoft.com/azure/devops/
- **LangSmith Documentation**: https://docs.smith.langchain.com/
- **Azure App Service**: https://docs.microsoft.com/azure/app-service/
- **Application Insights**: https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview

**Congratulations! 🎉 Your Financial AI application is now running on Azure with comprehensive monitoring and CI/CD automation!**
