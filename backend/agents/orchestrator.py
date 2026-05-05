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
    if state.get("patient_profile"):
        result = state.get("patient_profile").copy()
        result["agent"] = "intake"
        result["status"] = "success"
    else:
        result = run_intake_agent(state["raw_patient_input"])
    state["patient_profile"] = result
    state["current_agent"] = "intake"
    name = result.get("name", "Patient")
    insurer = result.get("insurer_name", "insurer")
    diag_count = len(result.get("diagnoses") or [])
    log_agent(state, "intake", result.get("status", "unknown"),
              {"detail": f"Profiled {name} · {insurer} · {diag_count} diagnoses extracted"})
    return state


def medical_analysis_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 2: Medical Analysis")
    result = run_medical_analysis_agent(
        state["patient_profile"],
        state["requested_treatment"]
    )
    state["medical_analysis"] = result
    state["current_agent"] = "medical_analysis"
    icd = result.get("icd10_codes") or []
    cpt = result.get("cpt_codes") or []
    icd_codes = ", ".join([c.get("code", str(c)) if isinstance(c, dict) else str(c) for c in icd[:3]])
    cpt_codes = ", ".join([c.get("code", str(c)) if isinstance(c, dict) else str(c) for c in cpt[:2]])
    log_agent(state, "medical_analysis", result.get("status", "unknown"),
              {"detail": f"ICD-10: {icd_codes or 'none'} · CPT: {cpt_codes or 'none'}"})
    return state


def policy_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 3: Policy Intelligence")
    insurer = state["patient_profile"].get("insurer_name", "Unknown")
    result = run_policy_agent(state["patient_profile"], insurer)
    state["policy_check"] = result
    state["current_agent"] = "policy"
    req = "Required" if result.get("pre_auth_required") else "Not required"
    missing = len(result.get("missing_documentation") or [])
    log_agent(state, "policy", result.get("status", "unknown"),
              {"detail": f"Pre-auth {req} · {missing} missing doc(s) identified"})
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
    risk = result.get("risk_score", "UNKNOWN")
    issues = len(result.get("issues_found") or [])
    log_agent(state, "claims", result.get("status", "unknown"),
              {"detail": f"Denial risk: {risk} · {issues} issue(s) found",
               "risk_score": risk})
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
    letter_str = letter.get("letter", "") if isinstance(letter, dict) else str(letter or "")
    word_count = len(letter_str.split())
    log_agent(state, "justification", "success",
              {"detail": f"Prior-auth letter drafted · {word_count} words"})
    return state


def submission_node(state: AuthState) -> AuthState:
    print("[Orchestrator] ▶ Agent 5: Submission & Monitor")
    
    # Submits the initial Justification Letter if it's the first run, 
    # OR dynamically submits the Appeal Letter if entering an appeal loop.
    document_to_submit = state.get("justification_letter")
    if state.get("appeal_level", 0) > 0 and state.get("appeal_result"):
        document_to_submit = state["appeal_result"].get("letter", document_to_submit)

    result = submit_authorization(
        document_to_submit,
        state["patient_profile"]
    )
    state["submission_result"] = result
    state["workflow_status"] = result["decision"]
    state["current_agent"] = "submission"
    ref = result.get("reference_number", "N/A")
    decision = result["decision"].upper()
    log_agent(state, "submission", result["decision"],
              {"detail": f"Decision: {decision} · Ref: {ref}",
               "reference": ref})
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
    word_count = len(str(letter or "").split())
    log_agent(state, "appeal", "submitted",
              {"detail": f"Level {new_level} appeal letter filed · {word_count} words"})
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
    decision = str(state.get("submission_result", {}).get("decision", "pending")).strip().lower()
    if "approved" in decision:
        return "approved"
    elif "denied" in decision and state.get("appeal_level", 0) < 3:
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

    # Linear flow: intake → medical → policy & claims (parallel track) → justification → submission
    graph.set_entry_point("intake")
    graph.add_edge("intake", "medical_analysis")
    
    # Fan-out to calculate policy & claims in parallel
    graph.add_edge("medical_analysis", "policy")
    graph.add_edge("medical_analysis", "claims_validation")
    
    # Fan-in to justification
    graph.add_edge("policy", "justification")
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


def build_appeal_graph():
    """Builds a customized LangGraph starting from the Appeal Node instead of Intake."""
    graph = StateGraph(AuthState)

    graph.add_node("appeal", appeal_node)
    graph.add_node("submission", submission_node)
    graph.add_node("human_escalation", human_escalation_node)

    graph.set_entry_point("appeal")

    graph.add_conditional_edges(
        "appeal",
        route_after_appeal,
        {
            "resubmit": "submission",
            "escalate": "human_escalation"
        }
    )

    graph.add_conditional_edges(
        "submission",
        route_after_submission,
        {
            "approved": END,
            "appeal": "appeal",
            "escalate": "human_escalation"
        }
    )

    graph.add_edge("human_escalation", END)

    return graph.compile()

# ─────────────────────────────────────────────────────────────
# Main entry point
# ─────────────────────────────────────────────────────────────

def run_authorization_workflow(patient_input: str, treatment: str, structured_profile: dict = None) -> AuthState:
    """
    Main entry point. Call this from FastAPI routes.
    
    Args:
        patient_input: Free-text patient description
        treatment: Requested treatment or procedure
        structured_profile: Pre-extracted patient structured dictionary
    
    Returns:
        Final AuthState dict with all agent outputs and audit trail
    """
    initial_state = AuthState(
        raw_patient_input=patient_input,
        requested_treatment=treatment,
        patient_profile=structured_profile,
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

def run_appeal_workflow(state: AuthState) -> AuthState:
    """
    Runs a dedicated appeal subgraph without running prior extraction agents.
    Accepts an assembled past AuthState and injects it dynamically into the appeal flow.
    """
    app = build_appeal_graph()
    return app.invoke(state)