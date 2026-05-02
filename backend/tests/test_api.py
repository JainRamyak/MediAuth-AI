# backend/tests/test_api.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from api.main import app

client = TestClient(app)

def test_health_endpoint_returns_ok():
    """Health endpoint must return status=ok."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "MediAuth AI"

def test_prompts_list_returns_all_agents():
    """Prompts list must include all 7 agent names."""
    response = client.get("/api/v1/prompts/")
    assert response.status_code == 200
    data = response.json()
    assert "agents" in data
    assert "intake" in data["agents"]
    assert "appeal" in data["agents"]
    assert len(data["agents"]) == 7

def test_get_intake_prompt_returns_yaml_content():
    """Getting intake prompt must return system and user_template fields."""
    response = client.get("/api/v1/prompts/intake")
    assert response.status_code == 200
    data = response.json()
    assert "system" in data
    assert "user_template" in data
    assert len(data["system"]) > 10

def test_get_invalid_agent_returns_404():
    """Requesting a non-existent agent must return 404."""
    response = client.get("/api/v1/prompts/nonexistent_agent")
    assert response.status_code == 404
