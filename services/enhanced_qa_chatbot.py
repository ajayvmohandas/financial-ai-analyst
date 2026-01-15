"""Enhanced QA Chatbot with LangSmith integration."""

import asyncio
from typing import Dict, Any, List, Optional
from langsmith import traceable
import uuid

from services.qa_chatbot import QAChatbot
from utils.logger import logger
from config.langsmith_config import langsmith_config


class EnhancedQAChatbot(QAChatbot):
    """Enhanced QA Chatbot with comprehensive LangSmith tracing."""
    
    def __init__(self, enable_tracing: bool = True):
        """Initialize enhanced QA chatbot.
        
        Args:
            enable_tracing: Whether to enable LangSmith tracing
        """
        super().__init__()
        self.enable_tracing = enable_tracing and langsmith_config.is_enabled()
        self.chatbot_name = "EnhancedQAChatbot"
    
    @traceable(name="chatbot_query")
    async def ask_question(self, question: str, conversation_history: List[Dict] = None) -> Dict[str, Any]:
        """Ask a question with comprehensive LangSmith tracing.
        
        Args:
            question: User's question
            conversation_history: Previous conversation history
            
        Returns:
            Dictionary containing answer and metadata
        """
        run_id = None
        try:
            if self.enable_tracing:
                run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name=f"{self.chatbot_name}_query",
                    inputs={
                        "question": question,
                        "conversation_history": conversation_history or []
                    },
                    run_id=run_id,
                    tags=["chatbot", "qa", "query"]
                )
            
            self.logger.info("Processing question", 
                           question=question[:100] + "..." if len(question) > 100 else question,
                           tracing_enabled=self.enable_tracing)
            
            # Extract company information
            company_extraction_run_id = None
            if self.enable_tracing:
                company_extraction_run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name="company_extraction",
                    inputs={"question": question},
                    run_id=company_extraction_run_id,
                    tags=["chatbot", "company-extraction"],
                    parent_run_id=run_id
                )
            
            try:
                company_info = await self._extract_company_info(question)
                
                if self.enable_tracing and company_extraction_run_id:
                    langsmith_config.end_run(
                        company_extraction_run_id, 
                        outputs={"company_info": company_info}
                    )
            except Exception as e:
                if self.enable_tracing and company_extraction_run_id:
                    langsmith_config.end_run(company_extraction_run_id, error=e)
                raise
            
            # Search documents
            document_search_run_id = None
            if self.enable_tracing:
                document_search_run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name="document_search",
                    inputs={"company_info": company_info, "question": question},
                    run_id=document_search_run_id,
                    tags=["chatbot", "document-search"],
                    parent_run_id=run_id
                )
            
            try:
                relevant_docs = await self._search_documents(company_info, question)
                
                if self.enable_tracing and document_search_run_id:
                    langsmith_config.end_run(
                        document_search_run_id, 
                        outputs={"document_count": len(relevant_docs)}
                    )
            except Exception as e:
                if self.enable_tracing and document_search_run_id:
                    langsmith_config.end_run(document_search_run_id, error=e)
                raise
            
            # Generate answer
            answer_generation_run_id = None
            if self.enable_tracing:
                answer_generation_run_id = str(uuid.uuid4())
                langsmith_config.create_run(
                    name="answer_generation",
                    inputs={
                        "question": question,
                        "document_count": len(relevant_docs),
                        "company_info": company_info
                    },
                    run_id=answer_generation_run_id,
                    tags=["chatbot", "answer-generation"],
                    parent_run_id=run_id
                )
            
            try:
                answer = await self._generate_answer(question, relevant_docs, company_info)
                
                if self.enable_tracing and answer_generation_run_id:
                    langsmith_config.end_run(
                        answer_generation_run_id, 
                        outputs={"answer": answer}
                    )
            except Exception as e:
                if self.enable_tracing and answer_generation_run_id:
                    langsmith_config.end_run(answer_generation_run_id, error=e)
                raise
            
            result = {
                "question": question,
                "answer": answer,
                "company_info": company_info,
                "sources": relevant_docs,
                "document_count": len(relevant_docs)
            }
            
            self.logger.info("Question processed successfully", 
                           document_count=len(relevant_docs),
                           has_company=bool(company_info))
            
            # End main run
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, outputs=result)
            
            return result
            
        except Exception as e:
            self.logger.error("Failed to process question", error=str(e))
            
            if self.enable_tracing and run_id:
                langsmith_config.end_run(run_id=run_id, error=e)
            
            raise
    
    @traceable(name="conversation_session")
    async def start_conversation_session(self, session_id: str = None) -> str:
        """Start a conversation session with tracing.
        
        Args:
            session_id: Optional session ID
            
        Returns:
            Session ID
        """
        if not session_id:
            session_id = str(uuid.uuid4())
        
        if self.enable_tracing:
            langsmith_config.create_run(
                name=f"{self.chatbot_name}_session",
                inputs={"session_id": session_id},
                run_id=session_id,
                tags=["chatbot", "session"]
            )
        
        self.logger.info("Conversation session started", session_id=session_id)
        return session_id
    
    async def end_conversation_session(self, session_id: str, summary: str = None):
        """End a conversation session with tracing.
        
        Args:
            session_id: Session ID
            summary: Optional session summary
        """
        if self.enable_tracing:
            outputs = {"session_ended": True}
            if summary:
                outputs["summary"] = summary
            
            langsmith_config.end_run(session_id, outputs=outputs)
        
        self.logger.info("Conversation session ended", session_id=session_id)
    
    def trace_custom_event(self, event_name: str, data: Dict[str, Any], session_id: str = None):
        """Trace custom events in LangSmith.
        
        Args:
            event_name: Name of the event
            data: Event data
            session_id: Optional session ID for parent run
        """
        if not self.enable_tracing:
            return
        
        try:
            run_id = str(uuid.uuid4())
            langsmith_config.create_run(
                name=event_name,
                inputs=data,
                run_id=run_id,
                tags=["custom-event"],
                parent_run_id=session_id
            )
            
            # End the run immediately for events
            langsmith_config.end_run(run_id, outputs={"event_processed": True})
            
        except Exception as e:
            self.logger.error("Failed to trace custom event", 
                            event_name=event_name, 
                            error=str(e))
