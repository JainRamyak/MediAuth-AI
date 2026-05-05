# backend/agents/appeal_agent.py
import json
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude


def run_appeal_agent(
    denial_reason: str,
    patient_profile: dict,
    medical_analysis: dict,
    appeal_level: int
) -> str:
    """
    Writes an appeal letter based on the denial reason and patient evidence.
    
    Args:
        denial_reason: The specific reason the insurer gave for denial
        patient_profile: Output from Agent 1 (intake)
        medical_analysis: Output from Agent 2 (medical analysis)
        appeal_level: 1 = initial polite appeal, 2 = peer-to-peer firm, 3 = external review urgent
    
    Returns:
        str: Complete formal appeal letter
    """
    # Build counter-evidence from patient record
    counter_evidence = f"""
    Clinical evidence supporting medical necessity:
    - Patient diagnoses: {patient_profile.get('diagnoses', [])}
    - Medications already tried: {patient_profile.get('medications', [])}
    - Clinical necessity summary: {medical_analysis.get('clinical_necessity_summary', '')}
    - Relevant ICD-10 codes: {[c['code'] if isinstance(c, dict) else str(c) for c in medical_analysis.get('icd10_codes', [])]}
    - Treatment follows clinical guidelines: {medical_analysis.get('treatment_follows_guidelines', True)}
    - Step therapy already attempted: {medical_analysis.get('step_therapy_required', False)}
    """

    system = get_system_prompt("appeal")
    user = get_user_prompt(
        "appeal",
        denial_reason=denial_reason,
        appeal_level=appeal_level,
        patient_profile=json.dumps(patient_profile, indent=2),
        counter_evidence=counter_evidence,
        insurer_name=patient_profile.get("insurer_name", "Insurance Provider")
    )

    # Uses call_claude (not JSON) — output is a letter
    appeal_letter = call_claude(system, user, max_tokens=3000)
    return appeal_letter