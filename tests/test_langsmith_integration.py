"""Tests for LangSmith integration."""

import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from config.langsmith_config import LangSmithConfig
from agents.enhanced_base_agent import EnhancedBaseAgent
from services.enhanced_qa_chatbot import EnhancedQAChatbot


class TestLangSmithConfig:
    """Test LangSmith configuration."""
    
    def test_langsmith_disabled_by_default(self):
        """Test that LangSmith is disabled when API key is not set."""
        with patch.dict('os.environ', {}, clear=True):
            config = LangSmithConfig()
            assert not config.is_enabled()
    
    def test_langsmith_enabled_with_api_key(self):
        """Test that LangSmith is enabled when API key is set."""
        with patch.dict('os.environ', {
            'LANGSMITH_TRACING': 'true',
            'LANGSMITH_API_KEY': 'test-key',
            'LANGSMITH_PROJECT': 'test-project'
        }):
            config = LangSmithConfig()
            assert config.is_enabled()
            assert config.get_project_name() == 'test-project'
    
    def test_create_run_when_disabled(self):
        """Test that create_run returns None when disabled."""
        config = LangSmithConfig()
        run = config.create_run("test", {"test": "data"})
        assert run is None
    
    def test_end_run_when_disabled(self):
        """Test that end_run does nothing when disabled."""
        config = LangSmithConfig()
        # Should not raise any exception
        config.end_run("test-run-id")


class MockEnhancedAgent(EnhancedBaseAgent):
    """Mock agent for testing."""
    
    async def _execute(self, input_data):
        return {"result": "test", "input": input_data}


class TestEnhancedBaseAgent:
    """Test enhanced base agent with LangSmith integration."""
    
    @pytest.fixture
    def mock_agent(self):
        """Create mock agent for testing."""
        with patch.dict('os.environ', {
            'LANGSMITH_TRACING': 'true',
            'LANGSMITH_API_KEY': 'test-key',
            'LANGSMITH_PROJECT': 'test-project'
        }):
            return MockEnhancedAgent(enable_tracing=True)
    
    @pytest.mark.asyncio
    async def test_execute_with_tracing(self, mock_agent):
        """Test agent execution with tracing enabled."""
        input_data = {"test": "data"}
        
        result = await mock_agent.execute(input_data)
        
        assert result["result"] == "test"
        assert result["input"] == input_data
    
    @pytest.mark.asyncio
    async def test_execute_without_tracing(self):
        """Test agent execution with tracing disabled."""
        with patch.dict('os.environ', {}, clear=True):
            agent = MockEnhancedAgent(enable_tracing=False)
            input_data = {"test": "data"}
            
            result = await agent.execute(input_data)
            
            assert result["result"] == "test"
            assert result["input"] == input_data
    
    @pytest.mark.asyncio
    async def test_llm_call_with_tracing(self, mock_agent):
        """Test LLM call with tracing."""
        messages = [{"role": "user", "content": "test"}]
        
        with patch.object(mock_agent.llm, 'ainvoke', new_callable=AsyncMock) as mock_invoke:
            mock_response = Mock()
            mock_response.content = "test response"
            mock_invoke.return_value = mock_response
            
            result = await mock_agent._call_llm(messages)
            
            assert result == "test response"
            mock_invoke.assert_called_once()


class TestEnhancedQAChatbot:
    """Test enhanced QA chatbot with LangSmith integration."""
    
    @pytest.fixture
    def mock_chatbot(self):
        """Create mock chatbot for testing."""
        with patch.dict('os.environ', {
            'LANGSMITH_TRACING': 'true',
            'LANGSMITH_API_KEY': 'test-key',
            'LANGSMITH_PROJECT': 'test-project'
        }):
            return EnhancedQAChatbot(enable_tracing=True)
    
    @pytest.mark.asyncio
    async def test_ask_question_with_tracing(self, mock_chatbot):
        """Test asking question with tracing."""
        question = "What is the revenue?"
        
        # Mock the parent methods
        mock_chatbot._extract_company_info = AsyncMock(return_value={"name": "Test Corp"})
        mock_chatbot._search_documents = AsyncMock(return_value=["doc1", "doc2"])
        mock_chatbot._generate_answer = AsyncMock(return_value="Test answer")
        
        result = await mock_chatbot.ask_question(question)
        
        assert result["question"] == question
        assert result["answer"] == "Test answer"
        assert result["company_info"]["name"] == "Test Corp"
        assert len(result["sources"]) == 2
    
    @pytest.mark.asyncio
    async def test_conversation_session_management(self, mock_chatbot):
        """Test conversation session management."""
        session_id = await mock_chatbot.start_conversation_session()
        assert session_id is not None
        
        await mock_chatbot.end_conversation_session(session_id, "Test summary")
    
    def test_trace_custom_event(self, mock_chatbot):
        """Test custom event tracing."""
        event_name = "test_event"
        data = {"test": "data"}
        
        # Should not raise any exception
        mock_chatbot.trace_custom_event(event_name, data)


if __name__ == "__main__":
    pytest.main([__file__])
