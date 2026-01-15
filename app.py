"""Enhanced Streamlit UI for Financial Agentic AI System with LangSmith integration."""

import streamlit as st
import asyncio
import os
import uuid
from pathlib import Path
import tempfile
from typing import Optional, Dict, Any, List
import time

from services.enhanced_qa_chatbot import EnhancedQAChatbot
from services.document_processor import DocumentProcessor
from utils.logger import logger
from config.azure_config import azure_config
from config.langsmith_config import langsmith_config

# Page configuration
st.set_page_config(
    page_title="IDP Financial Analyst - Azure DevOps Edition",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state
def init_session_state():
    """Initialize session state variables."""
    if 'chatbot' not in st.session_state:
        st.session_state.chatbot = None
    if 'document_processor' not in st.session_state:
        st.session_state.document_processor = None
    if 'conversation_history' not in st.session_state:
        st.session_state.conversation_history = []
    if 'processed_documents' not in st.session_state:
        st.session_state.processed_documents = []
    if 'session_id' not in st.session_state:
        st.session_state.session_id = None
    if 'langsmith_enabled' not in st.session_state:
        st.session_state.langsmith_enabled = langsmith_config.is_enabled()

def run_async(coro):
    """Run async function in Streamlit."""
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
    return loop.run_until_complete(coro)

def initialize_services():
    """Initialize chatbot and document processor services."""
    try:
        if st.session_state.chatbot is None:
            st.session_state.chatbot = EnhancedQAChatbot(
                enable_tracing=st.session_state.langsmith_enabled
            )
            logger.info("Enhanced QA Chatbot initialized", 
                       tracing_enabled=st.session_state.langsmith_enabled)
        
        if st.session_state.document_processor is None:
            st.session_state.document_processor = DocumentProcessor()
            logger.info("Document processor initialized")
            
        return True
    except Exception as e:
        st.error(f"Failed to initialize services: {str(e)}")
        logger.error("Service initialization failed", error=str(e))
        return False

def start_conversation_session():
    """Start a new conversation session."""
    try:
        if st.session_state.chatbot and st.session_state.langsmith_enabled:
            session_id = run_async(st.session_state.chatbot.start_conversation_session())
            st.session_state.session_id = session_id
            logger.info("Conversation session started", session_id=session_id)
            return session_id
        return None
    except Exception as e:
        st.error(f"Failed to start conversation session: {str(e)}")
        logger.error("Failed to start conversation session", error=str(e))
        return None

def end_conversation_session():
    """End the current conversation session."""
    try:
        if st.session_state.session_id and st.session_state.chatbot:
            # Create session summary
            summary = f"Session with {len(st.session_state.conversation_history)} interactions"
            run_async(st.session_state.chatbot.end_conversation_session(
                st.session_state.session_id, 
                summary
            ))
            logger.info("Conversation session ended", 
                       session_id=st.session_state.session_id)
            st.session_state.session_id = None
    except Exception as e:
        logger.error("Failed to end conversation session", error=str(e))

def display_langsmith_status():
    """Display LangSmith integration status."""
    col1, col2 = st.columns([3, 1])
    
    with col1:
        st.info("🔍 **LangSmith Integration**")
        st.write(f"Status: {'✅ Enabled' if st.session_state.langsmith_enabled else '❌ Disabled'}")
        
        if st.session_state.langsmith_enabled:
            st.write(f"Project: `{langsmith_config.get_project_name()}`")
            if st.session_state.session_id:
                st.write(f"Session ID: `{st.session_state.session_id[:8]}...`")
    
    with col2:
        if st.button("🔄 Reset Session", key="reset_session"):
            end_conversation_session()
            st.session_state.conversation_history = []
            start_conversation_session()
            st.rerun()

def display_system_info():
    """Display system information and configuration."""
    with st.expander("🔧 System Information", expanded=False):
        col1, col2 = st.columns(2)
        
        with col1:
            st.write("**Azure Configuration:**")
            st.write(f"- Chat Deployment: `{azure_config.chat_deployment}`")
            st.write(f"- Embeddings: `{azure_config.embeddings_deployment or 'Local'}`")
        
        with col2:
            st.write("**Application Status:**")
            st.write(f"- Services: {'✅ Ready' if st.session_state.chatbot else '❌ Initializing'}")
            st.write(f"- Documents: {len(st.session_state.processed_documents)} processed")

def handle_document_upload():
    """Handle document upload and processing."""
    st.subheader("📄 Document Upload & Processing")
    
    uploaded_file = st.file_uploader(
        "Upload financial document (PDF, DOCX, XLSX, or image)",
        type=['pdf', 'docx', 'xlsx', 'jpg', 'jpeg', 'png', 'tiff'],
        help="Upload financial documents for AI-powered analysis"
    )
    
    if uploaded_file is not None:
        with st.spinner("Processing document..."):
            try:
                # Save uploaded file temporarily
                with tempfile.NamedTemporaryFile(delete=False, suffix=Path(uploaded_file.name).suffix) as tmp_file:
                    tmp_file.write(uploaded_file.getvalue())
                    tmp_file_path = tmp_file.name
                
                # Process document
                if st.session_state.document_processor:
                    result = run_async(st.session_state.document_processor.process_document(
                        tmp_file_path, 
                        uploaded_file.name
                    ))
                    
                    if result.get('success'):
                        st.session_state.processed_documents.append({
                            'filename': uploaded_file.name,
                            'processed_at': time.time(),
                            'company': result.get('company_info', {}).get('name', 'Unknown'),
                            'document_type': result.get('document_type', 'Unknown'),
                            'file_size': len(uploaded_file.getvalue())
                        })
                        
                        st.success(f"✅ Document processed successfully!")
                        st.json(result)
                        
                        # Track custom event in LangSmith
                        if st.session_state.langsmith_enabled and st.session_state.chatbot:
                            st.session_state.chatbot.trace_custom_event(
                                "document_processed",
                                {
                                    "filename": uploaded_file.name,
                                    "company": result.get('company_info', {}).get('name'),
                                    "document_type": result.get('document_type'),
                                    "file_size": len(uploaded_file.getvalue())
                                },
                                st.session_state.session_id
                            )
                    else:
                        st.error(f"❌ Document processing failed: {result.get('error', 'Unknown error')}")
                
                # Clean up temporary file
                os.unlink(tmp_file_path)
                
            except Exception as e:
                st.error(f"❌ Error processing document: {str(e)}")
                logger.error("Document processing error", error=str(e))

def handle_qa_chatbot():
    """Handle Q&A chatbot interface."""
    st.subheader("💬 Financial Q&A Chatbot")
    
    # Display conversation history
    if st.session_state.conversation_history:
        st.write("**Conversation History:**")
        for i, interaction in enumerate(st.session_state.conversation_history):
            with st.chat_message("user"):
                st.write(interaction['question'])
            with st.chat_message("assistant"):
                st.write(interaction['answer'])
                if interaction.get('sources'):
                    with st.expander("📚 Sources"):
                        for source in interaction['sources']:
                            st.write(f"- {source}")
    
    # Chat input
    user_question = st.chat_input("Ask about financial documents, companies, or reports...")
    
    if user_question and st.session_state.chatbot:
        with st.spinner("Analyzing your question..."):
            try:
                # Get answer from chatbot
                result = run_async(st.session_state.chatbot.ask_question(
                    user_question, 
                    st.session_state.conversation_history
                ))
                
                # Add to conversation history
                st.session_state.conversation_history.append({
                    'question': user_question,
                    'answer': result['answer'],
                    'company_info': result.get('company_info'),
                    'sources': result.get('sources', []),
                    'timestamp': time.time()
                })
                
                # Display answer
                with st.chat_message("assistant"):
                    st.write(result['answer'])
                    
                    if result.get('company_info'):
                        st.info(f"🏢 Company Identified: {result['company_info']}")
                    
                    if result.get('sources'):
                        with st.expander("📚 Source Documents"):
                            for source in result['sources']:
                                st.write(f"- {source}")
                
                st.rerun()
                
            except Exception as e:
                st.error(f"❌ Error processing question: {str(e)}")
                logger.error("Chatbot error", error=str(e))

def display_document_library():
    """Display processed document library."""
    st.subheader("📚 Document Library")
    
    if not st.session_state.processed_documents:
        st.info("No documents processed yet. Upload a document to get started.")
        return
    
    # Document statistics
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.metric("Total Documents", len(st.session_state.processed_documents))
    
    with col2:
        companies = set(doc['company'] for doc in st.session_state.processed_documents)
        st.metric("Unique Companies", len(companies))
    
    with col3:
        total_size = sum(doc['file_size'] for doc in st.session_state.processed_documents)
        st.metric("Total Size", f"{total_size / 1024 / 1024:.1f} MB")
    
    # Document list
    st.write("**Processed Documents:**")
    for i, doc in enumerate(st.session_state.processed_documents):
        with st.expander(f"📄 {doc['filename']}"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**Company:** {doc['company']}")
                st.write(f"**Type:** {doc['document_type']}")
            
            with col2:
                st.write(f"**Size:** {doc['file_size'] / 1024:.1f} KB")
                st.write(f"**Processed:** {time.ctime(doc['processed_at'])}")
            
            with col3:
                if st.button(f"🗑️ Remove", key=f"remove_doc_{i}"):
                    st.session_state.processed_documents.pop(i)
                    st.rerun()

def main():
    """Main Streamlit application."""
    # Initialize session state
    init_session_state()
    
    # Initialize services
    if not initialize_services():
        st.error("❌ Failed to initialize application services. Please check your configuration.")
        return
    
    # Start conversation session if LangSmith is enabled
    if st.session_state.langsmith_enabled and not st.session_state.session_id:
        start_conversation_session()
    
    # Header
    st.title("📊 IDP Financial Analyst")
    st.markdown("*Intelligent Document Processing & Financial Analysis with LangSmith Monitoring*")
    
    # Sidebar
    with st.sidebar:
        st.header("🔧 Configuration")
        
        # LangSmith status
        display_langsmith_status()
        
        # System info
        st.divider()
        display_system_info()
        
        # Clear data button
        st.divider()
        if st.button("🗑️ Clear All Data", type="secondary"):
            st.session_state.conversation_history = []
            st.session_state.processed_documents = []
            end_conversation_session()
            start_conversation_session()
            st.rerun()
    
    # Main content tabs
    tab1, tab2, tab3 = st.tabs(["📄 Document Upload", "💬 Q&A Chatbot", "📚 Document Library"])
    
    with tab1:
        handle_document_upload()
    
    with tab2:
        handle_qa_chatbot()
    
    with tab3:
        display_document_library()
    
    # Footer
    st.divider()
    col1, col2, col3 = st.columns([1, 2, 1])
    
    with col2:
        st.markdown(
            "<div style='text-align: center; color: gray;'>"
            "IDP Financial Analyst - Azure DevOps Edition | "
            f"LangSmith {'✅' if st.session_state.langsmith_enabled else '❌'}"
            "</div>",
            unsafe_allow_html=True
        )

if __name__ == "__main__":
    main()
