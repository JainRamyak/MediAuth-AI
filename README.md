# MediAuth AI

> Autonomous insurance prior authorization — 7 agents, zero manual paperwork.

[![Stack](https://img.shields.io/badge/Stack-Flutter%20%7C%20FastAPI%20%7C%20LangGraph%20%7C%20Claude%20Sonnet%204-green)](/) [![License](https://img.shields.io/badge/License-MIT-yellow)](/)

**Links:** [Pitch Deck](https://canva.link/ruz4die26sp8jo0) · [Figma UI](https://www.figma.com/design/04EV8eKKddOo7zkjCyz0mV/MediAuth_AI--Veersa_hack?node-id=0-1&t=iS5dXxCHj51ICsjU-1) · [Android APK](https://github.com/JainRamyak/MediAuth-AI/releases/download/V1/Test.apk)

---

## Overview

MediAuth AI accepts raw patient data and autonomously navigates the full prior authorization lifecycle — from clinical coding to multi-level appeal — completing initial submission in under 60 seconds. The core innovation is a **closed-loop appeal cycle** (Agent 6) that reads denials, finds counter-evidence, writes escalating appeal letters, and re-submits without human input.

---

## Architecture

```mermaid
graph TD
    A[Patient Input] --> B[Agent 1: Intake & History]
    B --> C[Agent 2: Medical Analysis]
    C --> D[Agent 3: Policy Intelligence]
    D --> E[Agent 4: Justification Writer]
    E --> F[Agent 5: Submission & Monitor]

    F -->|Approved| G[Notify User / End]
    F -->|Denied| H[Agent 6: Denial & Appeal]

    H -->|Level < 3| F
    H -->|Level = 3| I[Human Escalation]

    subgraph "Parallel Track"
        J[Agent 7: Claims Validation]
    end

    C -.-> J
```

**Why LangGraph?** Native support for conditional edges and cycles — the appeal loop (submit → deny → appeal → re-submit) is a graph cycle handled without workarounds.

**Why ChromaDB?** Insurance policies stored as vector embeddings. Adding a new insurer = dropping their PDF and re-running the loader. Zero code changes.

**Why external YAML prompts?** All 7 agent prompts live in `backend/prompts/*.yaml`, surfaced in the Flutter Prompt Editor. Clinicians adjust agent behaviour without touching code.

---

## The 7 Agents

| # | Agent | Input | Output |
|---|---|---|---|
| 1 | **Intake & History** | Raw patient text | Structured JSON: name, DOB, insurer, diagnoses, medications |
| 2 | **Medical Analysis** | Patient profile + treatment | ICD-10 / CPT codes, clinical necessity summary, step therapy flags |
| 3 | **Policy Intelligence** | Patient profile + insurer | ChromaDB RAG → coverage gaps, required docs, pre-auth flag |
| 4 | **Justification Writer** | Agents 1–3 output | 2–3 page prior auth letter via Claude Sonnet 4 |
| 5 | **Submission & Monitor** | Justification letter | Decision (approved/denied), denial reason, reference number |
| 6 | **Denial & Appeal** | Denial reason + appeal level | Escalating appeal letter: professional → assertive → regulatory |
| 7 | **Claims Validation** | Billing codes + doc list | Risk score (LOW/MED/HIGH), issues, recommendation (SUBMIT/HOLD/AUTO_CORRECT) |

All agents are LangGraph nodes. Prompts loaded from `backend/prompts/*.yaml`. Agents never call each other — the orchestrator owns all state transitions.

### Autonomous Appeal Loop

```
Agent 5 submits → Approved → Done
                → Denied  → Agent 6: parse denial, find counter-evidence, write appeal (Level 1)
                          → Agent 5 re-submits
                          → Denied → Level 2 (assertive tone)
                          → Denied → Level 3 (regulatory language + CMS citations)
                          → Denied → Human escalation
```

Routing logic in `orchestrator.py`:

```python
def route_after_submission(state: AuthState) -> str:
    if state["submission_result"]["decision"] == "approved":
        return "approved"
    elif state["appeal_level"] < 3:
        return "appeal"
    return "escalate"
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| LLM | Claude Sonnet 4 (`claude-sonnet-4-20250514`) |
| Agent Framework | LangGraph 0.0.55 |
| Backend | FastAPI 0.111.0 + Python 3.11+ |
| Frontend | Flutter 3.x (Dart) |
| Database | Supabase / PostgreSQL 15 + SQLAlchemy 2.0.30 |
| Vector Store | ChromaDB 0.5.0 |
| Auth | Supabase Auth + JWT (`python-jose`) |
| Containers | Docker + docker-compose |
| Deployment | Render.com |

---

## Project Structure

```
MediAuth-AI/
├── backend/
│   ├── agents/
│   │   ├── orchestrator.py            # LangGraph state machine
│   │   ├── intake_agent.py
│   │   ├── medical_analysis_agent.py
│   │   ├── policy_agent.py
│   │   ├── justification_agent.py
│   │   ├── submission_agent.py
│   │   ├── appeal_agent.py
│   │   └── claims_agent.py
│   ├── api/routes/
│   │   ├── auth.py
│   │   ├── prompts.py
│   │   └── main.py
│   ├── models/
│   ├── prompts/                       # All agent prompts — editable via UI
│   │   ├── intake_prompt.yaml
│   │   ├── medical_analysis_prompt.yaml
│   │   ├── policy_prompt.yaml
│   │   ├── justification_prompt.yaml
│   │   ├── submission_prompt.yaml
│   │   ├── appeal_prompt.yaml
│   │   └── claims_prompt.yaml
│   ├── knowledge_base/
│   │   ├── loader.py
│   │   └── sample_policies/
│   ├── utils/
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
├── mediauth_flutter/lib/
│   ├── screens/
│   │   ├── patient_intake_screen.dart
│   │   ├── authorization_status_screen.dart
│   │   └── prompt_editor_screen.dart
│   └── services/api_service.dart
├── docker-compose.yml
├── render.yaml
└── README.md
```

---

## Setup

### Prerequisites

- Python 3.11+, Flutter 3.x, Docker
- Anthropic API key, PostgreSQL 15+ or Supabase project

### Backend

```bash
git clone https://github.com/JainRamyak/MediAuth-AI.git
cd MediAuth-AI/backend

python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

cp .env.example .env          # set ANTHROPIC_API_KEY and DATABASE_URL

python models/init_db.py
python knowledge_base/loader.py

uvicorn api.main:app --reload
```

Verify: `curl http://localhost:8000/health` → `{"status":"ok"}`

### Flutter

```bash
cd mediauth_flutter && flutter pub get && flutter run -d chrome
```

### Docker (single command)

```bash
docker-compose up --build
```

---

## Environment Variables

```env
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_URL=postgresql://user:pass@localhost:5432/mediauth
JWT_SECRET=<openssl rand -hex 32>
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ENVIRONMENT=development
```

---

## API Reference

Interactive docs: `http://localhost:8000/docs` · Postman: `backend/tests/postman_collection.json`

```
GET    /health
POST   /api/v1/authorize             # Trigger full 7-agent pipeline
GET    /api/v1/authorize/{id}        # Poll status + audit trail
GET    /api/v1/prompts/              # List agents
GET    /api/v1/prompts/{agent}       # Get agent's YAML prompt
PUT    /api/v1/prompts/{agent}       # Update prompt (live, no restart)
```

**Request:**

```bash
curl -X POST http://localhost:8000/api/v1/authorize \
  -H "Content-Type: application/json" \
  -d '{
    "patient_text": "Jane Doe, 54F. Diagnoses: T2 Diabetes, Chronic Back Pain. Insurer: BlueCross.",
    "requested_treatment": "MRI Lumbar Spine without contrast"
  }'
```

**Response:**

```json
{
  "auth_request_id": "uuid-...",
  "workflow_status": "approved",
  "appeal_level": 0,
  "justification_letter": "...",
  "audit_trail": [
    { "agent": "intake_agent", "status": "success", "timestamp": "..." }
  ]
}
```

---

## Database Schema

```
patients        — id, name, dob, insurer, diagnoses[], medications[], structured_profile
auth_requests   — id, patient_id, status, icd10_codes[], cpt_codes[],
                  justification_letter, denial_reason, appeal_level (0–3)
audit_logs      — id, auth_request_id, agent_name, action, input_data, output_data, status
claims          — id, auth_request_id, billing_codes, risk_score, risk_flags[], status
```

---

## Prompt Configuration

All prompts are YAML files in `backend/prompts/`, editable live via the Flutter Prompt Editor (no restart required):

```yaml
# appeal_prompt.yaml (excerpt)
system: |
  You are a medical authorization appeal specialist.
  Level 1 — Professional. Cite clinical evidence.
  Level 2 — Assertive. Reference insurer's own coverage criteria.
  Level 3 — Regulatory. Invoke CMS guidelines and state commissioner pathways.

user_template: |
  Denial Reason: {denial_reason}
  Appeal Level: {appeal_level}
  Patient Profile: {patient_profile}
  Clinical Analysis: {medical_analysis}
  Write the Level {appeal_level} appeal letter.
```

---

## Testing

```bash
cd backend && source venv/bin/activate && pytest tests/ -v
```

Tests mock `call_claude_for_json` / `call_claude` via `unittest.mock.patch` — no API key or network calls required. All test data is fully synthetic.

---

## Deployment

**Render.com**

| Field | Value |
|---|---|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn api.main:app --host 0.0.0.0 --port $PORT` |
| Env Vars | `ANTHROPIC_API_KEY`, `DATABASE_URL`, `JWT_SECRET`, `ENVIRONMENT=production` |

**Flutter Web**

```bash
cd mediauth_flutter
# Update lib/services/api_service.dart → baseUrl
flutter build web
# Deploy build/web/ to Vercel / Netlify / Render static site
```

---

## Contributor Guidelines

```python
# Prompts always loaded from YAML — never hardcoded
self.prompt = load_prompt("intake_agent")          # correct
PROMPT = "You are a patient intake specialist..."  # never do this

# Agents never call each other — orchestrator owns all wiring
def medical_analysis_node(state: AuthState):       # correct
    return {**state, "medical_analysis": run_medical_analysis_agent(...)}

# State is never mutated in place — always return a new dict
return {**state, "new_key": value}   # correct
state["new_key"] = value             # never do this
```

**`AuthState` TypedDict:**

```python
class AuthState(TypedDict):
    patient_input: str
    requested_treatment: str
    patient_profile: dict
    medical_analysis: dict
    policy_check: dict
    justification_letter: str
    submission_result: dict       # must include "decision" key
    appeal_level: int             # 0–3
    appeal_letter: str
    claims_validation: dict
    workflow_status: str
    audit_trail: list[dict]
```

---

## Roadmap

| Feature | Description |
|---|---|
| Real insurer APIs | Live CMS/payer REST + HIPAA-compliant fax PDF + EDI 278 |
| EHR integration | Direct Epic/Cerner read — eliminates manual data entry |
| Longitudinal history | Past auth outcomes inform letter strategy on repeat submissions |
| On-device inference | Ollama fallback for privacy-sensitive PHI |
| WhatsApp notifications | Appeal status via WhatsApp Business API |

---

> **Disclaimer:** MediAuth AI is a hackathon prototype. It does not replace qualified medical advice, authorization decisions, or legal compliance review. All AI-generated letters are labelled as system-generated. All test data is fully synthetic.
