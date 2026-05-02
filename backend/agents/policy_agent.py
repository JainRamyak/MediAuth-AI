# backend/agents/policy_agent.py
# STUB: Returns mock policy data. Real implementation would use ChromaDB RAG.
# Build the real version after the hackathon if time permits.

def run_policy_agent(patient_profile: dict, insurer_name: str) -> dict:
    """
    STUB: Returns mock policy check data.
    Real version would query ChromaDB for insurer-specific policy rules.
    """
    return {
        "agent": "policy",
        "status": "success",
        "pre_auth_required": True,
        "qualifies_for_auto_approval": False,
        "required_documentation": [
            "Physician letter of medical necessity",
            "Recent lab results (within 6 months)",
            "Prior treatment history documentation"
        ],
        "available_documentation": [
            "Physician letter of medical necessity",
            "Recent lab results (within 6 months)"
        ],
        "missing_documentation": [
            "Prior treatment history documentation"
        ],
        "coverage_notes": f"Prior authorization required for this treatment under {insurer_name} policy."
    }