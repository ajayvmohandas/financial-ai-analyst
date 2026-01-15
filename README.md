# IDP Financial Analyst - Azure DevOps Edition

An intelligent document processing and question-answering system for financial documents with comprehensive Azure DevOps integration and LangSmith monitoring.

## 🚀 Features

- **Document Upload UI**: Streamlit-based web interface for easy document processing
- **LangSmith Integration**: Comprehensive tracing and monitoring of all AI operations
- **Azure DevOps CI/CD**: Complete pipeline with testing, security scanning, and deployment
- **Multi-Environment Support**: Staging and production environments with automated deployments
- **Container Orchestration**: Kubernetes and Azure Container Apps support
- **Infrastructure as Code**: Terraform templates for reproducible deployments
- **Security Scanning**: Automated vulnerability scanning and code quality checks
- **Monitoring**: Azure Application Insights and LangSmith integration

## 📋 Prerequisites

- Azure Subscription with appropriate permissions
- Azure DevOps organization and project
- Docker installed locally
- Terraform installed (for infrastructure deployment)
- kubectl installed (for Kubernetes deployment)

## 🛠️ Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd IDP-FINANCIAL-ANALYST
```

### 2. Azure DevOps Setup

1. **Create Azure DevOps Project**:
   - Navigate to [Azure DevOps](https://dev.azure.com)
   - Create new project: `financial-ai-devops`

2. **Configure Service Connections**:
   ```bash
   # In Azure DevOps Project Settings > Service connections
   # Create Docker Registry Service Connection
   # Create Azure Resource Manager Service Connection
   ```

3. **Set up Variable Groups**:
   ```bash
   # Create Variable Group: financial-ai-secrets
   AZURE_OPENAI_ENDPOINT=your_endpoint
   AZURE_OPENAI_API_KEY=your_api_key
   AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat
   AZURE_OPENAI_EMBEDDINGS_ENDPOINT=your_embeddings_endpoint
   AZURE_OPENAI_EMBEDDINGS_API_KEY=your_embeddings_api_key
   AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002
   LANGSMITH_API_KEY=your_langsmith_key
   LANGSMITH_PROJECT=financial-ai-production
   ```

### 3. Infrastructure Deployment

#### Option A: Terraform (Recommended)

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="resource_group_name=financial-ai-rg" -var="location=East US 2"

# Deploy infrastructure
terraform apply -var="resource_group_name=financial-ai-rg" -var="location=East US 2"
```

#### Option B: Azure CLI

```bash
# Use the provided Azure CLI scripts
./scripts/deploy-infrastructure.sh
```

### 4. Application Deployment

#### Azure DevOps Pipeline

1. Push your code to the Azure DevOps repository
2. The pipeline will automatically trigger and deploy through stages:
   - **Validate**: Code linting and formatting checks
   - **Test**: Unit tests with coverage reporting
   - **Security**: Vulnerability scanning
   - **BuildImage**: Docker image creation and push
   - **DeployStaging**: Deploy to staging environment
   - **DeployProduction**: Deploy to production (main branch only)

#### Manual Deployment

```bash
# Build and push Docker image
docker build -t financialaiacr.azurecr.io/financial-ai-app:latest .
docker push financialaiacr.azurecr.io/financial-ai-app:latest

# Deploy to Azure Container Apps
az containerapp create \
  --resource-group financial-ai-rg \
  --name financial-ai-app \
  --image financialaiacr.azurecr.io/financial-ai-app:latest \
  --environment financial-ai-env \
  --ingress external \
  --target-port 8501
```

## 🔧 Configuration

### Environment Variables

```bash
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-key
AZURE_OPENAI_API_VERSION=2024-02-15-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat

# Embeddings Configuration
AZURE_OPENAI_EMBEDDINGS_ENDPOINT=https://your-embeddings-resource.openai.azure.com/
AZURE_OPENAI_EMBEDDINGS_API_KEY=your-embeddings-key
AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT=text-embedding-ada-002

# LangSmith Configuration
LANGSMITH_API_KEY=your_langsmith_key
LANGSMITH_PROJECT=financial-ai-production
LANGSMITH_TRACING=true

# Storage Configuration
CHROMA_DB_PATH=/app/data/vector_db
DOCUMENT_STORAGE_PATH=/app/data/processed
RAW_DOCUMENT_PATH=/app/data/raw_documents
```

### Kubernetes Deployment

```bash
# Create secrets
kubectl apply -f kubernetes/secrets.yaml

# Deploy application
kubectl apply -f kubernetes/deployment.yaml

# Expose service
kubectl apply -f kubernetes/ingress.yaml

# Check deployment
kubectl get pods -l app=financial-ai
```

## 📊 Monitoring and Observability

### LangSmith Integration

The application includes comprehensive LangSmith tracing for:

- **Agent Execution**: Track all agent operations and performance
- **LLM Calls**: Monitor token usage, response times, and costs
- **Document Processing**: Track document parsing and processing steps
- **User Sessions**: Monitor user interactions and conversation flows

### Azure Monitoring

- **Application Insights**: Performance monitoring and error tracking
- **Log Analytics**: Centralized logging and querying
- **Azure Monitor**: Resource utilization and health monitoring

### Viewing Traces

```bash
# LangSmith Dashboard
# Visit: https://smith.langchain.com

# Azure Monitor
# Visit: Azure Portal > Monitor > Application Insights
```

## 🧪 Testing

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run unit tests
pytest tests/ -v --cov=.

# Run integration tests
pytest tests/integration/ -v

# Run security scans
safety check -r requirements.txt
bandit -r . -f json
```

### Azure DevOps Testing

The pipeline automatically runs:
- Unit tests with pytest
- Code coverage reporting
- Security vulnerability scanning
- Code quality checks with flake8 and black

## 🔄 CI/CD Pipeline

### Pipeline Stages

1. **Validate**: Code formatting and linting
2. **Test**: Unit tests and coverage
3. **Security**: Vulnerability scanning
4. **Build**: Docker image creation
5. **Deploy Staging**: Deploy to staging environment
6. **Deploy Production**: Deploy to production (main branch only)

### Branch Strategy

```
main (production)
├── develop (integration)
│   ├── feature/document-upload
│   ├── feature/chatbot-enhancement
│   └── hotfix/critical-bug-fix
└── release/v1.0.0
```

## 🚀 Scaling and Performance

### Horizontal Scaling

```bash
# Scale Kubernetes deployment
kubectl scale deployment financial-ai-app --replicas=5

# Configure autoscaling
kubectl autoscale deployment financial-ai-app --cpu-percent=70 --min=2 --max=10
```

### Performance Optimization

- **Caching**: Redis integration for session management
- **CDN**: Azure CDN for static assets
- **Load Balancing**: Azure Load Balancer for high availability

## 🔒 Security

### Security Features

- **Secret Management**: Azure Key Vault integration
- **Network Security**: VNet integration and firewall rules
- **Container Security**: Image scanning and runtime protection
- **API Security**: Rate limiting and authentication

### Security Best Practices

```bash
# Update dependencies regularly
pip-audit

# Scan container images
trivy image financialaiacr.azurecr.io/financial-ai-app:latest

# Monitor security alerts
az security alert list
```

## 📚 Documentation

- **API Documentation**: Available at `/docs` endpoint
- **Architecture Guide**: See `docs/architecture.md`
- **Troubleshooting**: See `docs/troubleshooting.md`

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Create Pull Request in Azure DevOps

## 📞 Support

- **Issues**: Create work item in Azure DevOps
- **Documentation**: Check project wiki
- **Monitoring**: Check Azure Monitor and LangSmith dashboard

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This is a production-ready deployment configuration with comprehensive monitoring, security, and scalability features. Ensure you review and update all configuration values before deploying to production.
"# Deployment test" 
