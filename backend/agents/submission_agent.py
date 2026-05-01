# backend/agents/submission_agent.py
# MOCK: Simulates insurer decision. For demo, defaults to "approved".
# Change mock_responses[0] to random.choice(mock_responses) to demo the appeal loop.

import time
import random


def submit_authorization(justification_letter: str, patient_profile: dict) -> dict:
    """
    MOCK: Simulates submitting to an insurer portal and getting a decision.
    
    For demo purposes:
    - mock_responses[0] → always approved (good for clean demo)
    - random.choice(mock_responses) → sometimes denied (good for showing appeal loop)
    
    Change which line is active based on what you want to show in the demo.
    """
    print("[Submission Agent] Submitting authorization to insurer...")
    time.sleep(1)  # Simulate network latency

    mock_responses = [
        {
            "decision": "approved",
            "denial_reason": None,
            "reference_number": "AUTH-2027-7834"
        },
        {
            "decision": "denied",
            "denial_reason": "Step therapy requirements not met. Patient must try and fail at least two generic alternatives before this treatment is covered.",
            "reference_number": "DEN-2027-1122"
        },
    ]

    # ↓ Change to random.choice(mock_responses) to demo the appeal loop
    response = mock_responses[0]
    #response = random.choice(mock_responses)

    return {
        "agent": "submission",
        "status": "success",
        "decision": response["decision"],
        "denial_reason": response.get("denial_reason"),
        "reference_number": response.get("reference_number"),
        "submitted_at": time.strftime("%Y-%m-%dT%H:%M:%SZ")
    }