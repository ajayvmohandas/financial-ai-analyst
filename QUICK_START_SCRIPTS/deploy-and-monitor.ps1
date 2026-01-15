# PowerShell Script for Azure DevOps Deployment and Monitoring
# This script automates deployment and sets up monitoring

param(
    [string]$ResourceGroup = "financial-ai-rg",
    [string]$ProjectName = "financial-ai-devops",
    [string]$Location = "East US 2"
)

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Test-Prerequisites {
    Write-ColorOutput "📋 Checking prerequisites..." "Yellow"
    
    # Check Azure CLI
    try {
        $azVersion = az --version 2>$null
        Write-ColorOutput "✅ Azure CLI found" "Green"
    } catch {
        Write-ColorOutput "❌ Azure CLI is not installed. Please install it first." "Red"
        Write-ColorOutput "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" "Yellow"
        exit 1
    }
    
    # Check Git
    try {
        $gitVersion = git --version 2>$null
        Write-ColorOutput "✅ Git found" "Green"
    } catch {
        Write-ColorOutput "❌ Git is not installed. Please install it first." "Red"
        exit 1
    }
    
    # Check Docker
    try {
        $dockerVersion = docker --version 2>$null
        Write-ColorOutput "✅ Docker found" "Green"
    } catch {
        Write-ColorOutput "❌ Docker is not installed. Please install it first." "Red"
        exit 1
    }
    
    Write-ColorOutput "✅ All prerequisites check passed" "Green"
}

function Connect-AzureAccount {
    Write-ColorOutput "🔐 Azure Authentication" "Yellow"
    Write-ColorOutput "Please login to Azure:" "Cyan"
    az login
    
    # Set subscription
    Write-ColorOutput "📋 Setting subscription..." "Yellow"
    $subscriptionId = az account show --query id -o tsv
    Write-ColorOutput "Using subscription: $subscriptionId" "Cyan"
}

function Deploy-Infrastructure {
    Write-ColorOutput "🏗️ Deploying Azure Infrastructure..." "Yellow"
    Write-ColorOutput "This will create: ACR, OpenAI resources, Storage, App Services, Monitoring" "Cyan"
    
    # Run the infrastructure deployment script
    if (Test-Path "scripts/deploy-infrastructure.sh") {
        # For Windows, we'll run the equivalent commands
        Write-ColorOutput "Running infrastructure deployment..." "Cyan"
        
        # Create Resource Group
        az group create --name $ResourceGroup --location $Location --tags Environment=production Project=Financial-AI ManagedBy=Script
        
        # Create ACR
        az acr create --name financialaiacr --resource-group $ResourceGroup --sku Standard --admin-enabled true --tags Environment=production Project=Financial-AI Component=ACR
        
        # Create OpenAI resources
        az cognitiveservices account create --name financial-ai-openai-chat --resource-group $ResourceGroup --kind OpenAI --sku S0 --location $Location --tags Environment=production Project=Financial-AI Component=OpenAI-Chat
        
        az cognitiveservices account deployment create --name financial-ai-openai-chat --resource-group $ResourceGroup --deployment-name gpt-4-chat --model-name gpt-4 --model-version "0613" --model-format OpenAI --sku-name Standard --capacity 1
        
        az cognitiveservices account create --name financial-ai-openai-embeddings --resource-group $ResourceGroup --kind OpenAI --sku S0 --location $Location --tags Environment=production Project=Financial-AI Component=OpenAI-Embeddings
        
        az cognitiveservices account deployment create --name financial-ai-openai-embeddings --resource-group $ResourceGroup --deployment-name text-embedding-ada-002 --model-name text-embedding-ada-002 --model-version "2" --model-format OpenAI --sku-name Standard --capacity 1
        
        # Create Storage
        az storage account create --name financialaistorage --resource-group $ResourceGroup --location $Location --sku Standard_LRS --kind StorageV2 --tags Environment=production Project=Financial-AI Component=Storage
        
        # Create App Service Plan
        az appservice plan create --name financial-ai-plan --resource-group $ResourceGroup --location $Location --sku B3 --is-linux --tags Environment=production Project=Financial-AI Component=AppService
        
        # Create App Services
        az webapp create --resource-group $ResourceGroup --plan financial-ai-plan --name financial-ai-staging --deployment-container-image-name nginx:latest --tags Environment=staging Project=Financial-AI Component=AppService
        
        az webapp create --resource-group $ResourceGroup --plan financial-ai-plan --name financial-ai-prod --deployment-container-image-name nginx:latest --tags Environment=production Project=Financial-AI Component=AppService
        
        Write-ColorOutput "✅ Infrastructure deployed successfully" "Green"
    } else {
        Write-ColorOutput "❌ Infrastructure deployment script not found" "Red"
        exit 1
    }
}

function Get-InfrastructureDetails {
    Write-ColorOutput "📊 Retrieving Infrastructure Details..." "Yellow"
    
    $script:ACR_LOGIN_SERVER = az acr show --name financialaiacr --query loginServer -o tsv
    $script:ACR_USERNAME = az acr credential show --name financialaiacr --query username -o tsv
    $script:ACR_PASSWORD = az acr credential show --name financialaiacr --query passwords[0].value -o tsv
    
    $script:OPENAI_ENDPOINT = az cognitiveservices account show --name financial-ai-openai-chat --resource-group $ResourceGroup --query endpoint -o tsv
    $script:OPENAI_KEY = az cognitiveservices account keys list --name financial-ai-openai-chat --resource-group $ResourceGroup --query key1 -o tsv
    
    $script:OPENAI_EMBEDDINGS_ENDPOINT = az cognitiveservices account show --name financial-ai-openai-embeddings --resource-group $ResourceGroup --query endpoint -o tsv
    $script:OPENAI_EMBEDDINGS_KEY = az cognitiveservices account keys list --name financial-ai-openai-embeddings --resource-group $ResourceGroup --query key1 -o tsv
    
    $script:STAGING_URL = az webapp show --name financial-ai-staging --resource-group $ResourceGroup --query defaultHostName -o tsv
    $script:PRODUCTION_URL = az webapp show --name financial-ai-prod --resource-group $ResourceGroup --query defaultHostName -o tsv
}

function Create-EnvironmentConfig {
    Write-ColorOutput "⚙️ Creating environment configuration..." "Yellow"
    
    $envContent = @"
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=$script:OPENAI_ENDPOINT
AZURE_OPENAI_API_KEY=$script:OPENAI_KEY
AZURE_OPENAI_API_VERSION=2024-02-15-preview
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-4-chat

# Azure OpenAI Embeddings
AZURE_OPENAI_EMBEDDINGS_ENDPOINT=$script:OPENAI_EMBEDDINGS_ENDPOINT
AZURE_OPENAI_EMBEDDINGS_API_KEY=$script:OPENAI_EMBEDDINGS_KEY
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
"@
    
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-ColorOutput "✅ Environment configuration created" "Green"
}

function Setup-GitRepository {
    Write-ColorOutput "📦 Setting up Git repository..." "Yellow"
    
    if (-not (Test-Path ".git")) {
        git init
        git add .
        git commit -m "Initial commit - Financial AI with LangSmith integration"
        Write-ColorOutput "✅ Git repository initialized" "Green"
    } else {
        Write-ColorOutput "⚠️ Git repository already exists" "Yellow"
    }
}

function Show-DevOpsInstructions {
    Write-ColorOutput "🔧 Azure DevOps Setup Instructions" "Blue"
    Write-ColorOutput "==================================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "1. Create Azure DevOps Project:" "Cyan"
    Write-Host "   - Go to https://dev.azure.com"
    Write-Host "   - Create new project: '$ProjectName'"
    Write-Host "   - Visibility: Private"
    Write-Host ""
    Write-ColorOutput "2. Push Code to Azure DevOps:" "Cyan"
    Write-Host "   git remote add origin https://dev.azure.com/your-organization/$ProjectName/_git/$ProjectName"
    Write-Host "   git push -u origin main"
    Write-Host ""
    Write-ColorOutput "3. Configure Service Connections in Azure DevOps:" "Cyan"
    Write-Host "   - Docker Registry: '$script:ACR_LOGIN_SERVER'"
    Write-Host "   - Username: '$script:ACR_USERNAME'"
    Write-Host "   - Password: [Check Azure Portal]"
    Write-Host ""
    Write-ColorOutput "4. Create Variable Groups:" "Cyan"
    Write-Host "   - Group: 'financial-ai-secrets'"
    Write-Host "   - Variables: AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_API_KEY, etc."
    Write-Host ""
    Write-ColorOutput "5. Run Pipeline:" "Cyan"
    Write-Host "   - Create pipeline from azure-pipelines.yml"
    Write-Host "   - Run pipeline to deploy application"
    Write-Host ""
}

function Show-Results {
    Write-ColorOutput "🎉 Setup Complete!" "Green"
    Write-ColorOutput "==================================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "📊 Infrastructure Details:" "Blue"
    Write-Host "  ACR Login Server: $script:ACR_LOGIN_SERVER"
    Write-Host "  ACR Username: $script:ACR_USERNAME"
    Write-Host "  ACR Password: [Check Azure Portal]"
    Write-Host "  OpenAI Endpoint: $script:OPENAI_ENDPOINT"
    Write-Host "  OpenAI Key: [Check Azure Portal]"
    Write-Host ""
    Write-ColorOutput "🌐 Application URLs:" "Blue"
    Write-Host "  Staging: https://$script:STAGING_URL"
    Write-Host "  Production: https://$script:PRODUCTION_URL"
    Write-Host ""
    Write-ColorOutput "📁 Important Files Created:" "Blue"
    Write-Host "  .env - Environment configuration"
    Write-Host "  DEPLOYMENT_GUIDE.md - Complete deployment guide"
    Write-Host ""
    Write-ColorOutput "⚠️ Important Notes:" "Yellow"
    Write-Host "  1. Save your API keys securely"
    Write-Host "  2. Update azure-pipelines.yml with your service connection names"
    Write-Host "  3. Add LANGSMITH_API_KEY to .env for AI monitoring"
    Write-Host "  4. Configure Azure DevOps variable groups with secrets"
    Write-Host ""
    Write-ColorOutput "🚀 Next Steps:" "Green"
    Write-Host "  1. Complete Azure DevOps project setup"
    Write-Host "  2. Push code to Azure DevOps"
    Write-Host "  3. Configure service connections and variable groups"
    Write-Host "  4. Run the deployment pipeline"
    Write-Host "  5. Monitor deployment in Azure DevOps and Azure Portal"
    Write-Host ""
    Write-ColorOutput "📚 Documentation:" "Blue"
    Write-Host "  - Full Guide: DEPLOYMENT_GUIDE.md"
    Write-Host "  - Azure DevOps: https://docs.microsoft.com/azure/devops/"
    Write-Host "  - LangSmith: https://docs.smith.langchain.com/"
    Write-Host ""
    Write-ColorOutput "✨ Your Financial AI application is ready for deployment!" "Green"
}

function Set-Monitoring {
    Write-ColorOutput "📊 Setting up Monitoring..." "Yellow"
    
    # Create Log Analytics Workspace
    az monitor log-analytics workspace create --name financial-ai-logs --resource-group $ResourceGroup --location $Location --sku PerGB2018 --retention-time 30 --tags Environment=production Project=Financial-AI Component=Monitoring
    
    # Get workspace ID
    $workspaceId = az monitor log-analytics workspace show --name financial-ai-logs --resource-group $ResourceGroup --query customerId -o tsv
    
    # Create Application Insights
    az monitor app-insights component create --app financial-ai-insights --location $Location --resource-group $ResourceGroup --application-type web --workspace $workspaceId --tags Environment=production Project=Financial-AI Component=Monitoring
    
    # Configure App Settings for monitoring
    $appInsightsKey = az monitor app-insights component show --app financial-ai-insights --resource-group $ResourceGroup --query instrumentationKey -o tsv
    
    az webapp config appsettings set --resource-group $ResourceGroup --name financial-ai-staging --settings APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey
    az webapp config appsettings set --resource-group $ResourceGroup --name financial-ai-prod --settings APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey
    
    Write-ColorOutput "✅ Monitoring configured successfully" "Green"
}

function Open-MonitoringDashboards {
    Write-ColorOutput "📈 Opening Monitoring Dashboards..." "Yellow"
    
    # Open Azure Portal
    Start-Process "https://portal.azure.com"
    
    # Open Application Insights
    Start-Process "https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/microsoft.insights%2Fcomponents"
    
    Write-ColorOutput "📊 Monitoring dashboards opened in browser" "Green"
    Write-ColorOutput "You can now monitor your application performance and logs" "Cyan"
}

# Main execution
try {
    Write-ColorOutput "🚀 Starting Azure DevOps Setup for Financial AI" "Blue"
    Write-ColorOutput "==================================================" "Cyan"
    
    Test-Prerequisites
    Connect-AzureAccount
    Deploy-Infrastructure
    Get-InfrastructureDetails
    Create-EnvironmentConfig
    Setup-GitRepository
    Set-Monitoring
    Show-DevOpsInstructions
    Show-Results
    Open-MonitoringDashboards
    
} catch {
    Write-ColorOutput "❌ Error occurred during setup: $_" "Red"
    exit 1
}

Write-ColorOutput "🎉 All done! Your Financial AI application is ready for deployment!" "Green"
