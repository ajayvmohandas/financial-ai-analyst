"""LangSmith configuration for tracing and monitoring."""

import os
from typing import Optional
from langsmith import Client
from utils.logger import logger


class LangSmithConfig:
    """LangSmith configuration and utilities."""
    
    def __init__(self):
        """Initialize LangSmith configuration."""
        self.enabled = os.getenv("LANGSMITH_TRACING", "false").lower() == "true"
        self.api_key = os.getenv("LANGSMITH_API_KEY")
        self.project_name = os.getenv("LANGSMITH_PROJECT", "financial-ai")
        self.endpoint = os.getenv("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")
        
        if self.enabled and not self.api_key:
            logger.warning("LangSmith tracing is enabled but LANGSMITH_API_KEY is not set")
            self.enabled = False
        
        self.client: Optional[Client] = None
        if self.enabled:
            self._initialize_client()
    
    def _initialize_client(self):
        """Initialize LangSmith client."""
        try:
            self.client = Client(
                api_key=self.api_key,
                api_url=self.endpoint
            )
            logger.info("LangSmith client initialized", project=self.project_name)
        except Exception as e:
            logger.error("Failed to initialize LangSmith client", error=str(e))
            self.enabled = False
    
    def is_enabled(self) -> bool:
        """Check if LangSmith tracing is enabled."""
        return self.enabled
    
    def get_project_name(self) -> str:
        """Get the current project name."""
        return self.project_name
    
    def create_run(self, name: str, inputs: dict, **kwargs):
        """Create a new LangSmith run."""
        if not self.enabled or not self.client:
            return None
        
        try:
            return self.client.create_run(
                name=name,
                inputs=inputs,
                project_name=self.project_name,
                **kwargs
            )
        except Exception as e:
            logger.error("Failed to create LangSmith run", error=str(e))
            return None
    
    def end_run(self, run_id: str, outputs: dict = None, error: Exception = None):
        """End a LangSmith run."""
        if not self.enabled or not self.client:
            return
        
        try:
            self.client.end_run(
                run_id=run_id,
                outputs=outputs,
                error=error
            )
        except Exception as e:
            logger.error("Failed to end LangSmith run", error=str(e))
    
    def get_client(self) -> Optional[Client]:
        """Get the LangSmith client instance."""
        return self.client


# Global instance
langsmith_config = LangSmithConfig()
