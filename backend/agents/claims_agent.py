# backend/agents/claims_agent.py
import json
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json

def run_claims_validation_agent(
    patient_id: str,
    icd10_codes: list,
    cpt_codes: list,
    documentation_list: list
) -> dict:
    """
    Calls the LLM using the claims prompt to determine risk.
    """
    try:
        system = get_system_prompt("claims")
        user = get_user_prompt("claims",
            patient_id=patient_id,
            icd10_codes=json.dumps(icd10_codes),
            cpt_codes=json.dumps(cpt_codes),
            documentation_list=json.dumps(documentation_list)
        )
        result = call_claude_for_json(system, user)
        result["agent"] = "claims_validation"
        result["status"] = "success"
        return result
    except Exception as e:
        return {
            "agent": "claims_validation",
            "status": "error",
            "error": str(e)
        }