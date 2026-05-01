# backend/agents/intake_agent.py
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json


def run_intake_agent(patient_input: str) -> dict:
    """
    Takes raw patient text input.
    Returns structured patient profile as dict with status field.
    
    Args:
        patient_input: Free-text patient description (demographics, insurance, diagnoses, etc.)
    
    Returns:
        dict with keys: name, date_of_birth, insurance_policy_number, insurer_name,
                        diagnoses, medications, allergies, past_procedures,
                        medical_history, missing_fields, agent, status
    """
    system = get_system_prompt("intake")
    user = get_user_prompt("intake", patient_input=patient_input)

    try:
        profile = call_claude_for_json(system, user)
        profile["agent"] = "intake"
        profile["status"] = "success"
        return profile
    except Exception as e:
        return {
            "agent": "intake",
            "status": "error",
            "error": str(e),
            "raw_input": patient_input
        }