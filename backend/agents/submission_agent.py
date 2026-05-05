# backend/agents/submission_agent.py
import time
import random
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json

def submit_authorization(document_to_submit: str, patient_profile: dict) -> dict:
    """
    MOCK: Simulates submitting to an insurer portal and getting a decision.
    Then hands the simulated response to the LLM to parse cleanly into the JSON structure.
    """
    print("[Submission Agent] Submitting authorization to insurer...")
    time.sleep(1)  # Simulate network latency

    simulated_responses = [
        "Status: APPROVED. Reference: AUTH-2027-7834. Note: No further info required.",
        "Status: DENIED. Reference: DEN-2027-1122. Reason: Step therapy requirements not met. Patient must try and fail at least two generic alternatives before this treatment is covered."
    ]

    # Randomly select a response text to simulate occasional denials natively
    raw_response = random.choice(simulated_responses)

    try:
        system = get_system_prompt("submission")
        user = get_user_prompt("submission", insurer_response=raw_response)
        
        result = call_claude_for_json(system, user)
        result["agent"] = "submission"
        result["status"] = "success"
        result["submitted_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ")
        return result
    except Exception as e:
        return {
            "agent": "submission",
            "status": "error",
            "error": str(e)
        }