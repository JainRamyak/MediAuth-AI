# backend/api/routes/prompts.py
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from utils.prompt_loader import load_prompt, update_prompt

router = APIRouter(prefix="/api/v1/prompts", tags=["prompts"])

AGENT_NAMES = [
    "intake", "medical_analysis", "policy",
    "justification", "appeal", "submission", "claims"
]


@router.get("/")
def list_prompts():
    """List all available agent prompt names."""
    return {"agents": AGENT_NAMES}


@router.get("/{agent_name}")
def get_prompt(agent_name: str):
    """Get the current system prompt and user template for an agent."""
    if agent_name not in AGENT_NAMES:
        raise HTTPException(status_code=404, detail=f"Agent '{agent_name}' not found")
    try:
        return load_prompt(agent_name)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Prompt file not found on disk")


class PromptUpdateRequest(BaseModel):
    system: str
    user_template: str


@router.put("/{agent_name}")
def update_agent_prompt(agent_name: str, request: PromptUpdateRequest):
    """Update an agent's prompt from the Flutter UI editor."""
    if agent_name not in AGENT_NAMES:
        raise HTTPException(status_code=404, detail=f"Agent '{agent_name}' not found")
    success = update_prompt(agent_name, request.system, request.user_template)
    return {"success": success, "agent": agent_name, "message": "Prompt updated successfully"}