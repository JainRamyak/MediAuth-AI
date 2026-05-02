# backend/tests/test_appeal_agent.py
import pytest
from unittest.mock import patch

SAMPLE_PATIENT = {
    "name": "Jane Doe",
    "diagnoses": ["Chronic Back Pain"],
    "medications": ["Ibuprofen 800mg"],
    "insurer_name": "BlueCross"
}

SAMPLE_MEDICAL = {
    "icd10_codes": [{"code": "M54.5", "description": "Low back pain"}],
    "clinical_necessity_summary": "Patient requires MRI for diagnostic clarity.",
    "treatment_follows_guidelines": True,
    "step_therapy_required": False
}

def test_appeal_agent_returns_non_empty_letter():
    """Agent 6 must return a non-empty appeal letter string."""
    from agents.appeal_agent import run_appeal_agent
    with patch("agents.appeal_agent.call_claude") as mock_llm:
        mock_llm.return_value = "Dear BlueCross Prior Authorization Department, We formally appeal your denial of the requested MRI..."
        result = run_appeal_agent(
            denial_reason="Step therapy not completed",
            patient_profile=SAMPLE_PATIENT,
            medical_analysis=SAMPLE_MEDICAL,
            appeal_level=1
        )
        assert isinstance(result, str)
        assert len(result) > 50

def test_appeal_agent_called_with_correct_level():
    """Level 3 appeal must pass level=3 to the LLM prompt."""
    from agents.appeal_agent import run_appeal_agent
    with patch("agents.appeal_agent.call_claude") as mock_llm:
        mock_llm.return_value = "URGENT EXTERNAL REVIEW REQUEST..."
        run_appeal_agent(
            denial_reason="Not medically necessary",
            patient_profile=SAMPLE_PATIENT,
            medical_analysis=SAMPLE_MEDICAL,
            appeal_level=3
        )
        # Verify that call_claude was called (appeal ran without crashing)
        assert mock_llm.called
        # The user message passed to LLM should contain "3"
        call_args = mock_llm.call_args[0]  # positional args: (system, user, max_tokens)
        assert "3" in call_args[1]  # "3" appears in user message