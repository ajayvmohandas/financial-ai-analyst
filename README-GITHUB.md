# 🚀 IDP Financial Analyst - GitHub + Azure Edition

An intelligent document processing and question-answering system for financial documents with **complete GitHub Actions CI/CD** and **Azure App Service** deployment. This version replaces Streamlit with a professional FastAPI web application.

## 🎯 Key Features

- **🌐 FastAPI Web Application** - Professional REST API with modern web interface
- **🚀 GitHub Actions CI/CD** - Complete automated deployment pipeline
- **☁️ Azure App Service** - Scalable cloud hosting with auto-scaling
- **📊 Document Processing** - Upload and analyze financial documents (PDF, DOCX, XLSX)
- **🤖 AI-Powered Q&A** - Ask questions about your uploaded documents
- **📈 LangSmith Integration** - Comprehensive AI operation monitoring
- **🔐 Azure Security** - Key Vault, Application Insights, Log Analytics
- **🐳 Container Ready** - Docker-based deployment with Azure Container Registry

## 📋 Prerequisites

- **Azure Subscription** with appropriate permissions
- **GitHub Account** with repository creation access
- **Azure CLI** installed and configured
- **Docker** installed locally (for testing)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-github-repository-url>
cd IDP-FINANCIAL-ANALYST-GIT
```

### 2. Deploy Azure Infrastructure

```bash
# Make script executable (Linux/Mac)
chmod +x scripts/deploy-azure-infrastructure.sh

# Deploy all Azure resources
./scripts/deploy-azure-infrastructure.sh
```

This creates:
- Azure Container Registry (ACR)
- Azure App Service (Staging & Production)
- Azure Storage Account
- Azure Key Vault
- Application Insights
- Log Analytics Workspace

### 3. Setup GitHub Secrets

```bash
# Set your repository and GitHub token
export GITHUB_REPO="your-username/financial-ai"
export GITHUB_TOKEN="your-github-personal-access-token"

# Run the setup script
./scripts/setup-github-secrets.sh
```

### 4. Configure Additional Secrets

Add these secrets manually in GitHub repository settings:

- `AZURE_OPENAI_ENDPOINT` - Your Azure OpenAI endpoint
- `AZURE_OPENAI_API_KEY` - Your Azure OpenAI API key
- `LANGSMITH_API_KEY` - Your LangSmith API key

### 5. Push to GitHub

```bash
git add .
git commit -m "Initial commit - FastAPI Financial AI application"
git push origin main
```

### 6. Monitor Deployment

The GitHub Actions workflow will automatically:
- Run tests and security scans
- Build Docker image
- Deploy to Azure App Service
- Configure monitoring

## 🏗️ Architecture

```
GitHub Repository
    ↓ (Push)
GitHub Actions CI/CD Pipeline
    ↓ (Build & Test)
Azure Container Registry
    ↓ (Deploy)
Azure App Service (FastAPI)
    ↓ (Serve)
Web Browser (Users)
```

### Azure Services Used

- **Azure App Service** - Web application hosting
- **Azure Container Registry** - Docker image storage
- **Azure Key Vault** - Secret management
- **Azure Storage** - Document storage
- **Application Insights** - Performance monitoring
- **Log Analytics** - Centralized logging

## 🌐 Application Features

### Document Upload
- **Supported Formats**: PDF, DOCX, XLSX, TXT
- **File Size Limit**: 50MB
- **Processing**: Automatic OCR and text extraction
- **Storage**: Azure Blob Storage

### Q&A Chatbot
- **Natural Language**: Ask questions in plain English
- **Context Awareness**: Understands document context
- **Source Attribution**: Shows source documents for answers
- **Company Identification**: Automatically identifies companies

### Monitoring & Analytics
- **LangSmith Tracing**: AI operation monitoring
- **Application Insights**: Performance metrics
- **Log Analytics**: Centralized logging
- **Health Checks**: Automatic health monitoring

## 📁 Project Structure

```
IDP-FINANCIAL-ANALYST-GIT/
├── main.py                 # FastAPI application entry point
├── templates/              # HTML templates
│   └── index.html         # Main web interface
├── static/                 # Static assets
│   ├── css/style.css      # Custom styles
│   └── js/app.js          # Frontend JavaScript
├── services/               # Business logic
│   ├── enhanced_qa_chatbot.py
│   └── document_processor.py
├── config/                 # Configuration
│   ├── azure_config.py
│   └── langsmith_config.py
├── agents/                 # AI agents
├── utils/                  # Utilities
├── tests/                  # Test suite
├── scripts/                # Deployment scripts
│   ├── deploy-azure-infrastructure.sh
│   └── setup-github-secrets.sh
├── .github/workflows/      # GitHub Actions
│   └── deploy-azure.yml
├── Dockerfile              # Container configuration
├── requirements.txt        # Python dependencies
└── README-GITHUB.md        # This file
```

## 🔧 Development Setup

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export AZURE_OPENAI_ENDPOINT="your-endpoint"
export AZURE_OPENAI_API_KEY="your-api-key"
export LANGSMITH_API_KEY="your-langsmith-key"

# Run locally
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Access the application at: `http://localhost:8000`

### Docker Development

```bash
# Build image
docker build -t financial-ai-app .

# Run container
docker run -p 8000:8000 financial-ai-app
```

## 🚀 Deployment Process

### Automated Deployment (Recommended)

1. **Push to GitHub** → Triggers GitHub Actions
2. **Run Tests** → Unit tests, security scans
3. **Build Image** → Docker image creation
4. **Push to ACR** → Azure Container Registry
5. **Deploy to App Service** → Automatic deployment
6. **Health Check** → Verify deployment success

### Manual Deployment

```bash
# Build and push Docker image
az acr build --registry financialaiacr --image financial-ai-app .

# Deploy to App Service
az webapp config container set \
  --name financial-ai-prod \
  --resource-group financial-ai-rg \
  --docker-custom-image-name financialaiacr.azurecr.io/financial-ai-app:latest
```

## 📊 Monitoring

### Application Monitoring
- **URL**: `https://financial-ai-prod.azurewebsites.net/health`
- **Application Insights**: Azure Portal → Application Insights
- **Log Analytics**: Azure Portal → Log Analytics

### AI Operation Monitoring
- **LangSmith**: https://smith.langchain.com
- **Project**: `financial-ai-production`

## 🔒 Security

### Azure Security Features
- **Key Vault**: Secure secret storage
- **Managed Identity**: Azure AD authentication
- **Network Security**: VNet integration available
- **SSL/TLS**: Automatic HTTPS

### Application Security
- **Input Validation**: File type and size validation
- **Error Handling**: Secure error responses
- **Logging**: Security event logging
- **Dependencies**: Regular security scanning

## 🛠️ Troubleshooting

### Common Issues

**Deployment Failures:**
```bash
# Check GitHub Actions logs
# Verify Azure credentials
# Check resource group permissions
```

**Application Errors:**
```bash
# Check Application Insights
# Review Log Analytics
# Verify environment variables
```

**Performance Issues:**
```bash
# Scale up App Service plan
# Check resource utilization
# Review Application Insights metrics
```

## 📈 Scaling

### Horizontal Scaling
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

### Vertical Scaling
```bash
# Scale up App Service plan
az appservice plan update \
  --resource-group financial-ai-rg \
  --name financial-ai-plan-prod \
  --sku P2v2
```

## 🔄 CI/CD Pipeline

### Pipeline Stages

1. **Test** - Unit tests, coverage, security scans
2. **Build** - Docker image creation
3. **Security** - Vulnerability scanning
4. **Deploy Staging** - Deploy to staging environment
5. **Deploy Production** - Deploy to production (main branch only)

### Environment Promotion

- **develop branch** → Staging environment
- **main branch** → Production environment

## 📞 Support

### Azure Support
- **Azure Portal**: https://portal.azure.com
- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Azure Support**: Create support request in Azure Portal

### Application Support
- **GitHub Issues**: Report bugs in repository
- **LangSmith Support**: https://docs.smith.langchain.com/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/

## 🎉 Success!

🎊 **Congratulations!** Your Financial AI application is now running on Azure with:

- ✅ **Professional FastAPI web interface**
- ✅ **Complete GitHub Actions CI/CD**
- ✅ **Azure App Service hosting**
- ✅ **Automated monitoring and logging**
- ✅ **Secure secret management**
- ✅ **Scalable architecture**

**Next Steps:**
1. 📊 **Monitor performance** in Application Insights
2. 🔍 **Review AI traces** in LangSmith
3. 🚀 **Scale as needed** based on usage
4. 🔄 **Set up additional environments** for development/testing

---

**🌟 Enjoy your production-ready Financial AI application on Azure!** 🌟
