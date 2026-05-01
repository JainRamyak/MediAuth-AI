# backend/agents/justification_agent.py
import json
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude


def run_justification_agent(
    patient_profile: dict,
    medical_analysis: dict,
    policy_check: dict
) -> str:
    """
    Generates the prior authorization justification letter.
    Returns the complete letter as a string (plain text).
    
    Args:
        patient_profile: Output from Agent 1 (intake)
        medical_analysis: Output from Agent 2 (medical analysis)  
        policy_check: Output from Agent 3 (policy) — can be stub/mock
    
    Returns:
        str: Complete formal prior authorization letter
    """
    insurer = patient_profile.get("insurer_name", "Unknown Insurer")

    # Build documentation status summary
    missing_docs = policy_check.get("missing_documentation", [])
    available_docs = policy_check.get("available_documentation", [])
    doc_status = f"Available: {available_docs}. Missing: {missing_docs}."

    system = get_system_prompt("justification")
    user = get_user_prompt(
        "justification",
        patient_profile=json.dumps(patient_profile, indent=2),
        icd10_codes=json.dumps(medical_analysis.get("icd10_codes", []), indent=2),
        cpt_codes=json.dumps(medical_analysis.get("cpt_codes", []), indent=2),
        clinical_summary=medical_analysis.get("clinical_necessity_summary", ""),
        insurer_name=insurer,
        documentation_status=doc_status
    )

    # Uses call_claude (not call_claude_for_json) because output is a letter, not JSON
    letter = call_claude(system, user, max_tokens=3000)
    return {
    "status": "success",
    "letter": letter
    }