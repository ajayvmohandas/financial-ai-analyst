"""Azure configuration management for Financial AI System."""

import os
from typing import Dict, Any, Optional
from pydantic import BaseSettings, Field


class AzureConfig(BaseSettings):
    """Azure configuration settings."""
    
    # OpenAI Configuration
    azure_openai_endpoint: str = Field(..., env="AZURE_OPENAI_ENDPOINT")
    azure_openai_api_key: str = Field(..., env="AZURE_OPENAI_API_KEY")
    azure_openai_api_version: str = Field(default="2024-02-15-preview", env="AZURE_OPENAI_API_VERSION")
    azure_openai_chat_deployment: str = Field(..., env="AZURE_OPENAI_CHAT_DEPLOYMENT")
    
    # Embeddings Configuration (Optional)
    azure_openai_embeddings_endpoint: Optional[str] = Field(None, env="AZURE_OPENAI_EMBEDDINGS_ENDPOINT")
    azure_openai_embeddings_api_key: Optional[str] = Field(None, env="AZURE_OPENAI_EMBEDDINGS_API_KEY")
    azure_openai_embeddings_deployment: Optional[str] = Field(None, env="AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT")
    
    # Storage Configuration
    azure_storage_connection_string: Optional[str] = Field(None, env="AZURE_STORAGE_CONNECTION_STRING")
    azure_storage_container_name: str = Field(default="documents", env="AZURE_STORAGE_CONTAINER_NAME")
    
    # Model Configuration
    embedding_model: str = Field(default="sentence-transformers/all-MiniLM-L6-v2", env="EMBEDDING_MODEL")
    
    # Application Configuration
    chroma_db_path: str = Field(default="./data/vector_db", env="CHROMA_DB_PATH")
    document_storage_path: str = Field(default="./data/processed", env="DOCUMENT_STORAGE_PATH")
    raw_document_path: str = Field(default="./data/raw_documents", env="RAW_DOCUMENT_PATH")
    
    class Config:
        env_file = ".env"
        case_sensitive = False
    
    def get_chat_config(self) -> Dict[str, Any]:
        """Get chat model configuration.
        
        Returns:
            Dictionary with chat model configuration
        """
        return {
            "azure_endpoint": self.azure_openai_endpoint,
            "api_key": self.azure_openai_api_key,
            "api_version": self.azure_openai_api_version,
            "deployment_name": self.azure_openai_chat_deployment,
        }
    
    def get_embeddings_config(self) -> Optional[Dict[str, Any]]:
        """Get embeddings model configuration.
        
        Returns:
            Dictionary with embeddings configuration or None if not configured
        """
        if not all([
            self.azure_openai_embeddings_endpoint,
            self.azure_openai_embeddings_api_key,
            self.azure_openai_embeddings_deployment
        ]):
            return None
        
        return {
            "azure_endpoint": self.azure_openai_embeddings_endpoint,
            "api_key": self.azure_openai_embeddings_api_key,
            "api_version": self.azure_openai_api_version,
            "deployment_name": self.azure_openai_embeddings_deployment,
        }
    
    def has_azure_embeddings(self) -> bool:
        """Check if Azure embeddings are configured.
        
        Returns:
            True if Azure embeddings are configured
        """
        return self.get_embeddings_config() is not None
    
    @property
    def chat_deployment(self) -> str:
        """Get chat deployment name."""
        return self.azure_openai_chat_deployment
    
    @property
    def embeddings_deployment(self) -> Optional[str]:
        """Get embeddings deployment name."""
        return self.azure_openai_embeddings_deployment


# Global instance
azure_config = AzureConfig()
