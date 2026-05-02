# backend/agents/orchestrator.py
from langgraph.graph import StateGraph, END
from typing import TypedDict, Optional
from datetime import datetime

from agents.intake_agent import run_intake_agent
from agents.medical_analysis_agent import run_medical_analysis_agent
from agents.policy_agent import run_policy_agent
from agents.justification_agent import run_justification_agent
from agents.submission_agent import submit_authorization
from agents.appeal_agent import run_appeal_agent
from agents.claims_agent import run_claims_validation_agent


# ─────────────────────────────────────────────────────────────
# State — shared data bag passed between all agents
# ─────────────────────────────────────────────────────────────
class AuthState(TypedDict):
    # Input fields (set at workflow start)
    raw_patient_input: str
    requested_treatment: str

    # Agent outputs (filled in as workflow progresses)
    patient_profile: Optional[dict]
    medical_analysis: Optional[dict]
    policy_check: Optional[dict]
    justification_letter: Optional[str]
    submission_result: Optional[dict]
    appeal_result: Optional[dict]
    claims_validation: Optional[dict]

    # Control flow fields
    current_agent: str
    workflow_status: str   # running | approved | denied | appealing | escalated | error
    appeal_level: int      # 0 = no appeal yet, 1/2/3 = appeal levels tried
    error_message: Optional[str]
    audit_trail: list      # list of dicts: {agent, status, timestamp}


# ─────────────────────────────────────────────────────────────
# Helper: add to audit trail
# ─────────────────────────────────────────────────────────────
def log_agent(state: AuthState, agent_name: str, status: str, extra: dict = None) -> None:
    entry = {
        "agent": agent_name,
        "status": status,
        "timestamp": datetime.utcnow().isoformat()
    }
    if extra:
        entry.update(extra)
    state["audit_trail"].append(entry)


# ─────────────────────────────────────────────────────────────
# Node functions — one per agent
# ─────────────────────────────────────────────────────────────

def intake_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 1: Intake & History")
    result = run_intake_agent(state["raw_patient_input"])
    state["patient_profile"] = result
    state["current_agent"] = "intake"
    log_agent(state, "intake", result.get("status", "unknown"))
    return state


def medical_analysis_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 2: Medical Analysis")
    result = run_medical_analysis_agent(
        state["patient_profile"],
        state["requested_treatment"]
    )
    state["medical_analysis"] = result
    state["current_agent"] = "medical_analysis"
    log_agent(state, "medical_analysis", result.get("status", "unknown"))
    return state


def policy_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 3: Policy Intelligence")
    insurer = state["patient_profile"].get("insurer_name", "Unknown")
    result = run_policy_agent(state["patient_profile"], insurer)
    state["policy_check"] = result
    state["current_agent"] = "policy"
    log_agent(state, "policy", result.get("status", "unknown"))
    return state


def claims_validation_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 7: Claims Validation (parallel track)")
    profile = state["patient_profile"]
    medical = state["medical_analysis"]
    result = run_claims_validation_agent(
        patient_id=profile.get("name", "unknown"),
        icd10_codes=medical.get("icd10_codes", []),
        cpt_codes=medical.get("cpt_codes", []),
        documentation_list=state["policy_check"].get("available_documentation", [])
    )
    state["claims_validation"] = result
    state["current_agent"] = "claims_validation"
    log_agent(state, "claims_validation", result.get("status", "unknown"),
              {"risk_score": result.get("risk_score")})
    return state


def justification_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 4: Justification Writer")
    letter = run_justification_agent(
        state["patient_profile"],
        state["medical_analysis"],
        state["policy_check"]
    )
    state["justification_letter"] = letter
    state["current_agent"] = "justification"
    log_agent(state, "justification", "success")
    return state


def submission_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 5: Submission & Monitor")
    result = submit_authorization(
        state["justification_letter"],
        state["patient_profile"]
    )
    state["submission_result"] = result
    state["workflow_status"] = result["decision"]
    state["current_agent"] = "submission"
    log_agent(state, "submission", result["decision"],
              {"reference": result.get("reference_number")})
    return state


def appeal_node(state: AuthState) -> AuthState:
    new_level = state["appeal_level"] + 1
    print(f"[Orchestrator] ▶ Agent 6: Appeal (Level {new_level})")
    denial_reason = state["submission_result"].get(
        "denial_reason", "Reason not specified"
    )
    letter = run_appeal_agent(
        denial_reason=denial_reason,
        patient_profile=state["patient_profile"],
        medical_analysis=state["medical_analysis"],
        appeal_level=new_level
    )
    state["appeal_result"] = {"letter": letter, "level": new_level}
    state["appeal_level"] = new_level
    state["workflow_status"] = "appealing"
    state["current_agent"] = "appeal"
    log_agent(state, f"appeal_level_{new_level}", "submitted")
    return state


def human_escalation_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ⚠️  Escalating to human clinician review")
    state["workflow_status"] = "escalated"
    log_agent(state, "human_escalation", "escalated",
              {"reason": "Maximum appeal levels reached or insufficient evidence"})
    return state


# ─────────────────────────────────────────────────────────────
# Routing logic
# ─────────────────────────────────────────────────────────────

def route_after_submission(state: AuthState) -> str:
    """Decide what to do after getting insurer decision."""
    decision = state.get("submission_result", {}).get("decision", "pending")
    if decision == "approved":
        return "approved"
    elif decision == "denied" and state.get("appeal_level", 0) < 3:
        return "appeal"
    else:
        return "escalate"


def route_after_appeal(state: AuthState) -> str:
    """After writing appeal letter, loop back to resubmit or escalate."""
    if state.get("appeal_level", 0) >= 3:
        return "escalate"
    return "resubmit"


# ─────────────────────────────────────────────────────────────
# Graph assembly
# ─────────────────────────────────────────────────────────────

def build_graph():
    graph = StateGraph(AuthState)

    # Register all nodes
    graph.add_node("intake", intake_node)
    graph.add_node("medical_analysis", medical_analysis_node)
    graph.add_node("policy", policy_node)
    graph.add_node("claims_validation", claims_validation_node)
    graph.add_node("justification", justification_node)
    graph.add_node("submission", submission_node)
    graph.add_node("appeal", appeal_node)
    graph.add_node("human_escalation", human_escalation_node)

    # Linear flow: intake → medical → policy → claims (parallel track) → justification → submission
    graph.set_entry_point("intake")
    graph.add_edge("intake", "medical_analysis")
    graph.add_edge("medical_analysis", "policy")
    graph.add_edge("policy", "claims_validation")   # claims runs right after policy
    graph.add_edge("claims_validation", "justification")
    graph.add_edge("justification", "submission")

    # Conditional routing after submission decision
    graph.add_conditional_edges(
        "submission",
        route_after_submission,
        {
            "approved": END,
            "appeal": "appeal",
            "escalate": "human_escalation"
        }
    )

    # Conditional routing after appeal letter written — loop back to submission
    graph.add_conditional_edges(
        "appeal",
        route_after_appeal,
        {
            "resubmit": "submission",   # ← This creates the loop!
            "escalate": "human_escalation"
        }
    )

    # Escalation and final approval both end the workflow
    graph.add_edge("human_escalation", END)

    return graph.compile()


# ─────────────────────────────────────────────────────────────
# Main entry point
# ─────────────────────────────────────────────────────────────

def run_authorization_workflow(patient_input: str, treatment: str) -> AuthState:
    """
    Main entry point. Call this from FastAPI routes.
    
    Args:
        patient_input: Free-text patient description
        treatment: Requested treatment or procedure
    
    Returns:
        Final AuthState dict with all agent outputs and audit trail
    """
    initial_state = AuthState(
        raw_patient_input=patient_input,
        requested_treatment=treatment,
        patient_profile=None,
        medical_analysis=None,
        policy_check=None,
        justification_letter=None,
        submission_result=None,
        appeal_result=None,
        claims_validation=None,
        current_agent="",
        workflow_status="running",
        appeal_level=0,
        error_message=None,
        audit_trail=[]
    )

    app = build_graph()
    final_state = app.invoke(initial_state)
    return final_state