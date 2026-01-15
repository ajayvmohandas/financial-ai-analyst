# Variables for Financial AI Infrastructure

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "financial-ai-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "financialaiacr"
}

variable "openai_chat_name" {
  description = "Azure OpenAI Chat account name"
  type        = string
  default     = "financial-ai-openai-chat"
}

variable "openai_embeddings_name" {
  description = "Azure OpenAI Embeddings account name"
  type        = string
  default     = "financial-ai-openai-embeddings"
}

variable "chat_deployment_name" {
  description = "Chat model deployment name"
  type        = string
  default     = "gpt-4-chat"
}

variable "embeddings_deployment_name" {
  description = "Embeddings model deployment name"
  type        = string
  default     = "text-embedding-ada-002"
}

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
  default     = "financialaistorage"
}

variable "app_insights_name" {
  description = "Application Insights name"
  type        = string
  default     = "financial-ai-insights"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace name"
  type        = string
  default     = "financial-ai-logs"
}

variable "app_service_plan_name" {
  description = "App Service Plan name"
  type        = string
  default     = "financial-ai-plan"
}

variable "staging_app_name" {
  description = "Staging App Service name"
  type        = string
  default     = "financial-ai-staging"
}

variable "production_app_name" {
  description = "Production App Service name"
  type        = string
  default     = "financial-ai-prod"
}
