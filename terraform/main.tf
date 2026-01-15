# Terraform configuration for Financial AI Azure Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
    ManagedBy   = "Terraform"
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = true
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
  }
}

# Azure OpenAI for Chat
resource "azurerm_cognitive_account" "openai_chat" {
  name                = var.openai_chat_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "OpenAI"
  sku_name            = "S0"
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
    Component   = "OpenAI-Chat"
  }
}

resource "azurerm_cognitive_deployment" "chat_deployment" {
  name                = var.chat_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai_chat.id
  
  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "0613"
  }
  
  scale {
    type = "Standard"
    capacity = 1
  }
}

# Azure OpenAI for Embeddings
resource "azurerm_cognitive_account" "openai_embeddings" {
  name                = var.openai_embeddings_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "OpenAI"
  sku_name            = "S0"
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
    Component   = "OpenAI-Embeddings"
  }
}

resource "azurerm_cognitive_deployment" "embeddings_deployment" {
  name                = var.embeddings_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai_embeddings.id
  
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }
  
  scale {
    type = "Standard"
    capacity = 1
  }
}

# Azure Storage Account
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
  }
}

# File Shares for persistent storage
resource "azurerm_storage_share" "vector_db" {
  name                 = "vector-db"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 10
}

resource "azurerm_storage_share" "documents" {
  name                 = "documents"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days    = 30
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B3"
  
  tags = {
    Environment = var.environment
    Project     = "Financial-AI"
  }
}

# App Service for Staging
resource "azurerm_linux_web_app" "staging" {
  name                = var.staging_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  
  site_config {
    always_on        = true
    app_command_line = ""
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/financial-ai-app:latest"
  }
  
  app_settings = {
    "WEBSITES_PORT"                          = "8501"
    "DOCKER_REGISTRY_SERVER_URL"             = azurerm_container_registry.acr.login_server
    "DOCKER_REGISTRY_SERVER_USERNAME"         = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"         = azurerm_container_registry.acr.admin_password
    "AZURE_OPENAI_ENDPOINT"                  = azurerm_cognitive_account.openai_chat.endpoint
    "AZURE_OPENAI_API_KEY"                   = azurerm_cognitive_account.openai_chat.primary_access_key
    "AZURE_OPENAI_API_VERSION"               = "2024-02-15-preview"
    "AZURE_OPENAI_CHAT_DEPLOYMENT"           = azurerm_cognitive_deployment.chat_deployment.name
    "AZURE_OPENAI_EMBEDDINGS_ENDPOINT"       = azurerm_cognitive_account.openai_embeddings.endpoint
    "AZURE_OPENAI_EMBEDDINGS_API_KEY"        = azurerm_cognitive_account.openai_embeddings.primary_access_key
    "AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT"     = azurerm_cognitive_deployment.embeddings_deployment.name
    "LANGSMITH_PROJECT"                      = "financial-ai-staging"
    "LANGSMITH_TRACING"                      = "true"
    "APPINSIGHTS_INSTRUMENTATIONKEY"         = azurerm_application_insights.main.instrumentation_key
  }
  
  tags = {
    Environment = "staging"
    Project     = "Financial-AI"
  }
}

# App Service for Production
resource "azurerm_linux_web_app" "production" {
  name                = var.production_app_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  
  site_config {
    always_on        = true
    app_command_line = ""
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/financial-ai-app:latest"
  }
  
  app_settings = {
    "WEBSITES_PORT"                          = "8501"
    "DOCKER_REGISTRY_SERVER_URL"             = azurerm_container_registry.acr.login_server
    "DOCKER_REGISTRY_SERVER_USERNAME"         = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"         = azurerm_container_registry.acr.admin_password
    "AZURE_OPENAI_ENDPOINT"                  = azurerm_cognitive_account.openai_chat.endpoint
    "AZURE_OPENAI_API_KEY"                   = azurerm_cognitive_account.openai_chat.primary_access_key
    "AZURE_OPENAI_API_VERSION"               = "2024-02-15-preview"
    "AZURE_OPENAI_CHAT_DEPLOYMENT"           = azurerm_cognitive_deployment.chat_deployment.name
    "AZURE_OPENAI_EMBEDDINGS_ENDPOINT"       = azurerm_cognitive_account.openai_embeddings.endpoint
    "AZURE_OPENAI_EMBEDDINGS_API_KEY"        = azurerm_cognitive_account.openai_embeddings.primary_access_key
    "AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT"     = azurerm_cognitive_deployment.embeddings_deployment.name
    "LANGSMITH_PROJECT"                      = "financial-ai-production"
    "LANGSMITH_TRACING"                      = "true"
    "APPINSIGHTS_INSTRUMENTATIONKEY"         = azurerm_application_insights.main.instrumentation_key
  }
  
  tags = {
    Environment = "production"
    Project     = "Financial-AI"
  }
}
