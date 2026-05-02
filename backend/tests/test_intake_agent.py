# backend/tests/test_intake_agent.py
import pytest
from unittest.mock import patch

SAMPLE_INPUT = """
Patient: John Doe, DOB 1975-03-15
Insurance: BlueCross, Policy BCX-12345
Diagnoses: Type 2 Diabetes, Hypertension
Medications: Metformin 1000mg, Lisinopril 10mg
Allergies: Penicillin
"""

def test_intake_agent_returns_success_dict():
    """Agent 1 must return a dict with status=success and structured fields."""
    from agents.intake_agent import run_intake_agent
    with patch("agents.intake_agent.call_claude_for_json") as mock_llm:
        mock_llm.return_value = {
            "name": "John Doe",
            "diagnoses": ["Type 2 Diabetes", "Hypertension"],
            "medications": ["Metformin 1000mg"],
            "insurer_name": "BlueCross",
            "missing_fields": []
        }
        result = run_intake_agent(SAMPLE_INPUT)
        assert result["status"] == "success"
        assert "name" in result
        assert "diagnoses" in result
        assert isinstance(result["diagnoses"], list)

def test_intake_agent_handles_api_error_gracefully():
    """Agent 1 must not crash if LLM API fails — it returns status=error."""
    from agents.intake_agent import run_intake_agent
    with patch("agents.intake_agent.call_claude_for_json") as mock_llm:
        mock_llm.side_effect = Exception("Groq API connection error")
        result = run_intake_agent(SAMPLE_INPUT)
        assert result["status"] == "error"
        assert "error" in result
        # Should not raise — graceful degradation