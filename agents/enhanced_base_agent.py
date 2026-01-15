"""Enhanced base agent class with LangSmith integration."""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from langchain_core.messages import BaseMessage, HumanMessage
from langchain_openai import AzureChatOpenAI
from langsmith import traceable
import uuid

from utils.logger import logger
from config.azure_config import azure_config
from config.langsmith_config import langsmith_config


class EnhancedBaseAgent(ABC):
    """Enhanced base class for all agents with LangSmith integration."""
    
    def __init__(self, 
                 temperature: float = 0.0,
                 max_tokens: int = 2000,
                 n_ctx: int = 4096,
                 enable_tracing: bool = True):
        """Initialize enhanced base agent.
        
        Args:
            temperature: Temperature for LLM generation
            max_tokens: Maximum tokens for LLM response
            n_ctx: Context window size
            enable_tracing: Whether to enable LangSmith tracing
        """
        self.logger = logger.bind(agent=self.__class__.__name__)
        self.enable_tracing = enable_tracing and langsmith_config.is_enabled()
        self.agent_name = self.__class__.__name__

        # Use centralized Azure configuration
        chat_config = azure_config.get_chat_config()
        
        self.llm = AzureChatOpenAI(
            **chat_config,
            temperature=temperature if temperature != 0.0 else None,
            max_tokens=max_tokens,
        )
        self.model_name = azure_config.chat_deployment
        self.model_path = "azure_openai"
    
    @traceable(name="agent_execute")
    async def execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the agent's main task with LangSmith tracing.
        
        Args:
            input_data: Input data dictionary
            
        Returns:
            Result dictionary
        """
        run_id = None
        try:
            # Create LangSmith run if tracing is enabled
            if self.enable_tracing:
                run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name=f"{self.agent_name}_execute",
                    inputs=input_data,
                    run_id=run_id,
                    tags=["agent", self.agent_name.lower()]
                )
            
            self.logger.info("Agent execution started", 
                           input_keys=list(input_data.keys()),
                           tracing_enabled=self.enable_tracing)
            
            result = await self._execute(input_data)
            
            self.logger.info("Agent execution completed", 
                           result_keys=list(result.keys()))
            
            # End LangSmith run
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, outputs=result)
            
            return result
            
        except Exception as e:
            self.logger.error("Agent execution failed", 
                            error=str(e), 
                            error_type=type(e).__name__)
            
            # End LangSmith run with error
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, error=e)
            
            raise
    
    @abstractmethod
    async def _execute(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Internal execution method to be implemented by subclasses.
        
        Args:
            input_data: Input data dictionary
            
        Returns:
            Result dictionary
        """
        pass
    
    @traceable(name="llm_call")
    async def _call_llm(self, messages: list[BaseMessage], **kwargs) -> str:
        """Call the LLM with messages and LangSmith tracing.
        
        Args:
            messages: List of message objects
            **kwargs: Additional arguments for LLM
            
        Returns:
            LLM response text
        """
        run_id = None
        try:
            if self.enable_tracing:
                run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name=f"{self.agent_name}_llm_call",
                    inputs={"messages": [msg.content for msg in messages], **kwargs},
                    run_id=run_id,
                    tags=["llm", self.agent_name.lower()]
                )
            
            response = await self.llm.ainvoke(messages, **kwargs)
            result = getattr(response, "content", str(response))
            
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, outputs={"response": result})
            
            return result
            
        except Exception as e:
            self.logger.error("LLM call failed", error=str(e))
            
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, error=e)
            
            raise
    
    def _create_system_message(self, system_prompt: str) -> BaseMessage:
        """Create a system message.
        
        Args:
            system_prompt: System prompt text
            
        Returns:
            System message object
        """
        from langchain_core.messages import SystemMessage
        return SystemMessage(content=system_prompt)
    
    def _create_human_message(self, content: str) -> HumanMessage:
        """Create a human message.
        
        Args:
            content: Message content
            
        Returns:
            Human message object
        """
        return HumanMessage(content=content)
    
    def trace_method(self, method_name: str):
        """Decorator for tracing specific methods.
        
        Args:
            method_name: Name of the method for tracing
            
        Returns:
            Decorator function
        """
        def decorator(func):
            if not self.enable_tracing:
                return func
                
            return traceable(name=f"{self.agent_name}_{method_name}")(func)
        
        return decorator
