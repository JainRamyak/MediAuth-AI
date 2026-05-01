import pytest
from unittest.mock import Mock, patch, MagicMock
from utils.claude_client import call_claude, call_claude_for_json


class TestCallClaude:
    """Tests for the call_claude function."""

    @patch("utils.claude_client.client")
    def test_call_claude_returns_string(self, mock_client):
        """Test that call_claude returns a string response."""
        mock_response = Mock()
        mock_response.content = [Mock(text="This is a test response")]
        mock_client.messages.create.return_value = mock_response

        result = call_claude("system prompt", "user message")

        assert isinstance(result, str)
        assert result == "This is a test response"

    @patch("utils.claude_client.client")
    def test_call_claude_uses_correct_model(self, mock_client):
        """Test that call_claude uses the correct model."""
        mock_response = Mock()
        mock_response.content = [Mock(text="Response")]
        mock_client.messages.create.return_value = mock_response

        call_claude("system", "user")

        mock_client.messages.create.assert_called_once()
        call_kwargs = mock_client.messages.create.call_args[1]
        assert call_kwargs["model"] == "claude-sonnet-4-20250514"

    @patch("utils.claude_client.client")
    def test_call_claude_passes_system_prompt(self, mock_client):
        """Test that system prompt is passed correctly."""
        mock_response = Mock()
        mock_response.content = [Mock(text="Response")]
        mock_client.messages.create.return_value = mock_response

        call_claude("Test system prompt", "user message")

        call_kwargs = mock_client.messages.create.call_args[1]
        assert call_kwargs["system"] == "Test system prompt"

    @patch("utils.claude_client.client")
    def test_call_claude_passes_user_message(self, mock_client):
        """Test that user message is passed correctly."""
        mock_response = Mock()
        mock_response.content = [Mock(text="Response")]
        mock_client.messages.create.return_value = mock_response

        call_claude("system", "Test user message")

        call_kwargs = mock_client.messages.create.call_args[1]
        assert call_kwargs["messages"] == [
            {"role": "user", "content": "Test user message"}
        ]

    @patch("utils.claude_client.client")
    def test_call_claude_default_max_tokens(self, mock_client):
        """Test that default max_tokens is 2000."""
        mock_response = Mock()
        mock_response.content = [Mock(text="Response")]
        mock_client.messages.create.return_value = mock_response

        call_claude("system", "user")

        call_kwargs = mock_client.messages.create.call_args[1]
        assert call_kwargs["max_tokens"] == 2000

    @patch("utils.claude_client.client")
    def test_call_claude_custom_max_tokens(self, mock_client):
        """Test that custom max_tokens is used."""
        mock_response = Mock()
        mock_response.content = [Mock(text="Response")]
        mock_client.messages.create.return_value = mock_response

        call_claude("system", "user", max_tokens=5000)

        call_kwargs = mock_client.messages.create.call_args[1]
        assert call_kwargs["max_tokens"] == 5000

    @patch("utils.claude_client.client")
    def test_call_claude_api_error(self, mock_client):
        """Test that API errors are propagated."""
        mock_client.messages.create.side_effect = Exception("API Error")

        with pytest.raises(Exception) as exc_info:
            call_claude("system", "user")

        assert "API Error" in str(exc_info.value)


class TestCallClaudeForJson:
    """Tests for the call_claude_for_json function."""

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_returns_dict(self, mock_call_claude):
        """Test that call_claude_for_json returns a dictionary."""
        mock_call_claude.return_value = '{"key": "value"}'

        result = call_claude_for_json("system", "user")

        assert isinstance(result, dict)
        assert result["key"] == "value"

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_valid_json(self, mock_call_claude):
        """Test parsing valid JSON response."""
        mock_call_claude.return_value = '{"name": "John", "age": 30}'

        result = call_claude_for_json("system", "user")

        assert result["name"] == "John"
        assert result["age"] == 30

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_strips_markdown(self, mock_call_claude):
        """Test that markdown code blocks are stripped."""
        mock_call_claude.return_value = '```json\n{"key": "value"}\n```'

        result = call_claude_for_json("system", "user")

        assert result["key"] == "value"

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_strips_whitespace(self, mock_call_claude):
        """Test that leading/trailing whitespace is stripped."""
        mock_call_claude.return_value = '  {"key": "value"}  '

        result = call_claude_for_json("system", "user")

        assert result["key"] == "value"

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_nested_structure(self, mock_call_claude):
        """Test parsing nested JSON structure."""
        mock_call_claude.return_value = (
            '{"patient": {"name": "John", "diagnoses": ["Diabetes"]}}'
        )

        result = call_claude_for_json("system", "user")

        assert result["patient"]["name"] == "John"
        assert result["patient"]["diagnoses"] == ["Diabetes"]

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_invalid_json(self, mock_call_claude):
        """Test that invalid JSON raises an error."""
        mock_call_claude.return_value = "This is not JSON"

        with pytest.raises(Exception):
            call_claude_for_json("system", "user")

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_passes_system_prompt(self, mock_call_claude):
        """Test that system prompt is passed to call_claude."""
        mock_call_claude.return_value = '{"result": "ok"}'

        call_claude_for_json("Test system", "user")

        mock_call_claude.assert_called_once()
        assert mock_call_claude.call_args[0][0] == "Test system"

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_passes_user_message(self, mock_call_claude):
        """Test that user message is passed to call_claude."""
        mock_call_claude.return_value = '{"result": "ok"}'

        call_claude_for_json("system", "Test user message")

        mock_call_claude.assert_called_once()
        assert mock_call_claude.call_args[0][1] == "Test user message"

    @patch("utils.claude_client.call_claude")
    def test_call_claude_for_json_uses_default_max_tokens(self, mock_call_claude):
        """Test that default max_tokens of 2000 is used."""
        mock_call_claude.return_value = '{"result": "ok"}'

        call_claude_for_json("system", "user")

        mock_call_claude.assert_called_once()
        assert mock_call_claude.call_args[1]["max_tokens"] == 2000
