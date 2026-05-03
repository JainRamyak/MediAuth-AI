# backend/agents/policy_agent.py
import json
from knowledge_base.loader import query_policies
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json

def run_policy_agent(patient_profile: dict, insurer_name: str) -> dict:
    """
    Queries ChromaDB for insurer-specific policy rules based on the patient's
    diagnoses, and uses Claude to analyze coverage requirements and gaps.
    """
    try:
        # 1. Build a query string from patient profile
        diagnoses = patient_profile.get("diagnoses", [])
        admission_type = patient_profile.get("admission_type", "Planned")
        
        query = f"Prior authorization requirements for {', '.join(diagnoses)} admission type {admission_type}"
        
        # 2. Query ChromaDB for policy context
        chunks = query_policies(query=query, insurer=insurer_name, n_results=3)
        policy_context = "\n---\n".join(chunks) if chunks else "No specific policy documents found for this insurer."
        
        # 3. Create a patient summary string
        patient_summary = json.dumps(patient_profile, indent=2)
        
        # 4. Generate Prompts
        system = get_system_prompt("policy")
        user = get_user_prompt("policy", 
                               insurer_name=insurer_name or "Unknown",
                               policy_context=policy_context,
                               patient_summary=patient_summary)
                               
        # 5. Call Claude
        result = call_claude_for_json(system, user)
        result["agent"] = "policy"
        result["status"] = "success"
        
        return result
        
    except Exception as e:
        return {
            "agent": "policy",
            "status": "error",
            "error": str(e)
        }