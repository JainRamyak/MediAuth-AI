# backend/agents/medical_analysis_agent.py
import json
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json


def run_medical_analysis_agent(patient_profile: dict, requested_treatment: str) -> dict:
    """
    Takes patient profile dict and treatment description.
    Returns ICD-10/CPT codes and clinical necessity summary.
    
    Args:
        patient_profile: Structured dict from Agent 1 (intake agent output)
        requested_treatment: Free-text description of what treatment/procedure is being requested
    
    Returns:
        dict with keys: icd10_codes, cpt_codes, clinical_necessity_summary,
                        treatment_follows_guidelines, step_therapy_required,
                        step_therapy_notes, agent, status
    """
    system = get_system_prompt("medical_analysis")
    user = get_user_prompt(
        "medical_analysis",
        patient_profile=json.dumps(patient_profile, indent=2),
        requested_treatment=requested_treatment
    )

    try:
        result = call_claude_for_json(system, user)
        result["agent"] = "medical_analysis"
        result["status"] = "success"
        return result
    except Exception as e:
        return {
            "agent": "medical_analysis",
            "status": "error",
            "error": str(e),
            "icd10_codes": [],
            "cpt_codes": [],
            "clinical_necessity_summary": ""
        }