# backend/tests/test_claude_client.py
import pytest
from unittest.mock import patch, MagicMock


class TestCallClaude:
    """Tests for call_claude() — mocked for Groq API structure."""

    def _make_mock_groq_response(self, text="Test response"):
        """Helper: build a mock that matches Groq's response structure."""
        mock_response = MagicMock()
        mock_response.choices[0].message.content = text
        return mock_response

    def test_call_claude_returns_string(self):
        """call_claude must return a string."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response("Hello world")
            result = call_claude("system prompt", "user message")
            assert isinstance(result, str)
            assert result == "Hello world"

    def test_call_claude_uses_correct_model(self):
        """call_claude must call Groq with the correct model."""
        from utils.claude_client import call_claude, MODEL
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response()
            call_claude("system", "user")
            mock_client.chat.completions.create.assert_called_once()
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            assert call_kwargs["model"] == MODEL

    def test_call_claude_passes_system_prompt(self):
        """call_claude must pass system prompt as first message."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response()
            call_claude("my system prompt", "user msg")
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            messages = call_kwargs["messages"]
            system_msg = next(m for m in messages if m["role"] == "system")
            assert system_msg["content"] == "my system prompt"

    def test_call_claude_passes_user_message(self):
        """call_claude must pass user message as second message."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response()
            call_claude("system", "my user message")
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            messages = call_kwargs["messages"]
            user_msg = next(m for m in messages if m["role"] == "user")
            assert user_msg["content"] == "my user message"

    def test_call_claude_default_max_tokens(self):
        """call_claude must use 2000 as default max_tokens."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response()
            call_claude("system", "user")
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            assert call_kwargs["max_tokens"] == 2000

    def test_call_claude_custom_max_tokens(self):
        """call_claude must pass custom max_tokens when provided."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.return_value = \
                self._make_mock_groq_response()
            call_claude("system", "user", max_tokens=3000)
            call_kwargs = mock_client.chat.completions.create.call_args[1]
            assert call_kwargs["max_tokens"] == 3000

    def test_call_claude_api_error(self):
        """call_claude must propagate exceptions from Groq API."""
        from utils.claude_client import call_claude
        with patch("utils.claude_client.client") as mock_client:
            mock_client.chat.completions.create.side_effect = \
                Exception("Groq API connection error")
            with pytest.raises(Exception, match="Groq API connection error"):
                call_claude("system", "user")


class TestCallClaudeForJson:
    """Tests for call_claude_for_json() — these were already passing, keep as-is."""

    def test_call_claude_for_json_returns_dict(self):
        from utils.claude_client import call_claude_for_json
        with patch("utils.claude_client.call_claude") as mock:
            mock.return_value = '{"key": "value"}'
            result = call_claude_for_json("system", "user")
            assert isinstance(result, dict)

    def test_call_claude_for_json_valid_json(self):
        from utils.claude_client import call_claude_for_json
        with patch("utils.claude_client.call_claude") as mock:
            mock.return_value = '{"name": "John", "age": 30}'
            result = call_claude_for_json("system", "user")
            assert result["name"] == "John"
            assert result["age"] == 30

    def test_call_claude_for_json_strips_markdown(self):
        from utils.claude_client import call_claude_for_json
        with patch("utils.claude_client.call_claude") as mock:
            mock.return_value = '```json\n{"key": "value"}\n```'
            result = call_claude_for_json("system", "user")
            assert result == {"key": "value"}

    def test_call_claude_for_json_invalid_json(self):
        from utils.claude_client import call_claude_for_json
        with patch("utils.claude_client.call_claude") as mock:
            mock.return_value = "this is not json"
            with pytest.raises(Exception):
                call_claude_for_json("system", "user")