"""FastAPI Web Application for Financial AI Document Processing System."""

import asyncio
import os
import uuid
from pathlib import Path
import tempfile
from typing import Optional, Dict, Any, List
import time
import json

from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from services.enhanced_qa_chatbot import EnhancedQAChatbot
from services.document_processor import DocumentProcessor
from utils.logger import logger
from config.azure_config import azure_config
from config.langsmith_config import langsmith_config

# Initialize FastAPI app
app = FastAPI(
    title="IDP Financial Analyst - Azure Edition",
    description="Intelligent document processing and Q&A system for financial documents",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Setup templates and static files
templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

# Global variables for services
chatbot = None
document_processor = None
langsmith_enabled = langsmith_config.is_enabled()

# Pydantic models
class ChatRequest(BaseModel):
    question: str
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    answer: str
    sources: List[str]
    company_identified: Optional[str] = None
    session_id: str

class DocumentResponse(BaseModel):
    message: str
    document_id: str
    filename: str
    processing_status: str

# Initialize services
async def initialize_services():
    """Initialize chatbot and document processor services."""
    global chatbot, document_processor
    
    try:
        if chatbot is None:
            chatbot = EnhancedQAChatbot(
                enable_tracing=langsmith_enabled
            )
            logger.info("Enhanced QA Chatbot initialized", 
                       tracing_enabled=langsmith_enabled)
        
        if document_processor is None:
            document_processor = DocumentProcessor()
            logger.info("Document processor initialized")
            
        return True
    except Exception as e:
        logger.error("Service initialization failed", error=str(e))
        return False

@app.on_event("startup")
async def startup_event():
    """Initialize services on startup."""
    await initialize_services()

# Routes
@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    """Home page with document upload and chat interface."""
    return templates.TemplateResponse("index.html", {
        "request": request,
        "title": "IDP Financial Analyst",
        "langsmith_enabled": langsmith_enabled
    })

@app.post("/upload", response_model=DocumentResponse)
async def upload_document(file: UploadFile = File(...)):
    """Upload and process a financial document."""
    try:
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file selected")
        
        # Validate file type
        allowed_extensions = ['.pdf', '.docx', '.xlsx', '.txt']
        file_extension = Path(file.filename).suffix.lower()
        
        if file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=400, 
                detail=f"File type {file_extension} not supported. Allowed: {allowed_extensions}"
            )
        
        # Generate unique document ID
        document_id = str(uuid.uuid4())
        
        # Save file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_extension) as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file_path = temp_file.name
        
        try:
            # Process document
            if document_processor:
                result = await document_processor.process_document(
                    file_path=temp_file_path,
                    filename=file.filename,
                    document_id=document_id
                )
                
                return DocumentResponse(
                    message=f"Document '{file.filename}' processed successfully",
                    document_id=document_id,
                    filename=file.filename,
                    processing_status="completed"
                )
            else:
                raise HTTPException(status_code=500, detail="Document processor not initialized")
                
        finally:
            # Clean up temporary file
            try:
                os.unlink(temp_file_path)
            except:
                pass
                
    except Exception as e:
        logger.error("Document upload failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Document processing failed: {str(e)}")

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Process a chat question and return response."""
    try:
        if not chatbot:
            raise HTTPException(status_code=500, detail="Chatbot service not initialized")
        
        # Start session if not provided
        session_id = request.session_id
        if not session_id:
            session_id = await chatbot.start_conversation_session()
        
        # Process question
        response = await chatbot.ask_question(
            question=request.question,
            session_id=session_id
        )
        
        return ChatResponse(
            answer=response.get("answer", "I'm sorry, I couldn't process your question."),
            sources=response.get("sources", []),
            company_identified=response.get("company_identified"),
            session_id=session_id
        )
        
    except Exception as e:
        logger.error("Chat processing failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Chat processing failed: {str(e)}")

@app.post("/end-session")
async def end_session(session_id: str = Form(...)):
    """End a conversation session."""
    try:
        if chatbot and session_id:
            summary = f"Session ended for user"
            await chatbot.end_conversation_session(session_id, summary)
            return {"message": "Session ended successfully", "session_id": session_id}
        else:
            raise HTTPException(status_code=400, detail="Invalid session or chatbot not initialized")
            
    except Exception as e:
        logger.error("Session end failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Session end failed: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "chatbot_initialized": chatbot is not None,
        "document_processor_initialized": document_processor is not None,
        "langsmith_enabled": langsmith_enabled,
        "azure_configured": azure_config.is_configured()
    }

@app.get("/documents")
async def list_documents():
    """List processed documents."""
    try:
        if document_processor:
            documents = await document_processor.list_processed_documents()
            return {"documents": documents}
        else:
            return {"documents": []}
            
    except Exception as e:
        logger.error("Failed to list documents", error=str(e))
        return {"documents": []}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
