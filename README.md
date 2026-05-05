# 🏥 MediAuth AI — Autonomous Insurance Authorization & Appeal Ecosystem

> **A multi-agent AI system that autonomously manages the full insurance prior authorization lifecycle — from patient intake and clinical coding to writing justification letters and filing multi-level appeals — with zero manual paperwork.**

[![Veersa Hackathon 2027](https://img.shields.io/badge/Veersa%20Hackathon-2027-blue)](https://forms.office.com/r/wax7a55k6n)
[![Theme](https://img.shields.io/badge/Theme-Agentic%20AI%20Systems-teal)](/)
[![Stack](https://img.shields.io/badge/Stack-Flutter%20%7C%20FastAPI%20%7C%20LangGraph%20%7C%20Claude%20Sonnet%204-green)](/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](/)

---

## Demo Links

- [![PPT](https://img.shields.io/badge/PPT-Canva-00C4CC?style=for-the-badge&logo=canva&logoColor=white)](https://canva.link/ruz4die26sp8jo0) Pitch deck covering problem, solution, and architecture.
- [![Figma](https://img.shields.io/badge/Figma-Design-1ABCFE?style=for-the-badge&logo=figma&logoColor=white)](https://www.figma.com/design/04EV8eKKddOo7zkjCyz0mV/MediAuth_AI--Veersa_hack?node-id=0-1&t=iS5dXxCHj51ICsjU-1) UI/UX screens and wireframes for the Flutter app.
- [![APK](https://img.shields.io/badge/APK-Download-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/JainRamyak/MediAuth-AI/releases/download/V1/Test.apk) Android demo build.

---

## 🏗️ System Architecture

MediAuth AI follows a modular, agentic architecture where specialized agents handle specific domains. The **LangGraph Orchestrator** manages the state and handles cycles (specifically the appeal loop).

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

---

## 📌 Table of Contents

1. [One-Line Pitch](#one-line-pitch)
2. [Problem Statement](#problem-statement)
3. [Solution Overview](#solution-overview)
4. [Core USP](#core-usp)
5. [Feature Set](#feature-set)
6. [System Architecture](#system-architecture)
7. [The 7 Specialized Agents](#the-7-specialized-agents)
8. [Tech Stack](#tech-stack)
9. [Data Flow](#data-flow)
10. [Project Structure](#project-structure)
11. [Setup & Installation](#setup--installation)
12. [Environment Variables](#environment-variables)
13. [Running the Project](#running-the-project)
14. [Prompt Configuration](#prompt-configuration)
15. [API Documentation](#api-documentation)
16. [Database Schema](#database-schema)
17. [Testing](#testing)
18. [Deployment](#deployment)
19. [Future Additions](#future-additions)
20. [Team](#team)

---

## One-Line Pitch

> Enter patient details → watch 7 AI agents coordinate in real time → get a medically-precise authorization letter → have denials autonomously appealed up to 3 levels — all without a human touching a form.

---

## Problem Statement

US healthcare prior authorization is a broken, manual process that costs clinicians and patients thousands of hours every year.

| Failure | Description |
|---|---|
| **Physician time sink** | Doctors spend 12+ hours per week on prior auth paperwork that requires no clinical judgment |
| **Preventable denials** | Over 70% of initial denials are due to administrative errors, not clinical unsuitability |
| **No appeal follow-through** | Most denied claims go unappealed because the process is too time-consuming — even when reversal is likely |
| **Disconnected systems** | Patient records, clinical codes, insurer policies, and justification letters live in 4–6 separate systems with no integration |

---

## Solution Overview

MediAuth AI is a **7-agent agentic orchestration system** that accepts raw patient data, autonomously navigates the full prior authorization lifecycle, and appeals denials in a closed loop — all under 60 seconds for the initial submission.

The core innovation is **Agent 6 (Denial & Appeal)**, which enters an autonomous cycle: read denial → locate counter-evidence from patient records → write a formal appeal letter with escalating tone → re-submit. It continues for up to 3 levels without any human input.

---

## Core USP

### 🔁 The Autonomous Appeal Loop

MediAuth AI is the **only system** where denied authorizations are re-fought by the AI itself — not flagged for a human to handle later.

```
Agent 5 submits authorization
          │
          ▼
Insurer denies with reason
          │
          ▼
Agent 6 reads denial → finds counter-evidence → writes appeal
          │
          ▼
Agent 5 re-submits (Appeal Level 1)
          │
     ┌────┴────┐
  Approved   Denied
     │          │
   Done    Agent 6 escalates tone → Level 2
                │
           ┌────┴────┐
        Approved   Denied
           │          │
          Done    Agent 6 → Level 3 (regulatory language)
                       │
                  ┌────┴────┐
               Approved   Denied
                  │          │
                Done    Human escalation
```

### Additional Differentiators

- **Policy RAG** — ChromaDB stores insurance policy PDFs as vector embeddings. Adding a new insurer = uploading their PDF. No code changes.
- **Parallel claims validation** — Agent 7 pre-checks billing codes for risk while the main pipeline runs, reducing rejection rate before the first submission.
- **Externally configurable prompts** — all 7 agent system prompts live in YAML files, editable via the Flutter Prompt Editor screen without touching code (satisfies Veersa's explicit requirement).
- **Full audit trail** — every agent invocation is logged with inputs, outputs, and timestamps. Every decision is traceable.
- **Human-in-loop gate** — the appeal loop caps at 3 levels, after which the case is flagged for human review rather than continuing blindly.

---

## Feature Set

### ✅ Core Features (Hackathon Scope)

#### Feature 1 — Patient Intake & Authorization

Hospital staff enter a patient's medical history and requested treatment via the Flutter app. Agent 1 transforms the free-text input into a structured patient profile. The full 7-agent pipeline fires automatically.

#### Feature 2 — Clinical Code Assignment

Agent 2 maps the clinical data to ICD-10 diagnosis codes and CPT procedure codes, producing a clinical necessity summary used by both the justification writer and the claims validator.

#### Feature 3 — Policy Intelligence (RAG)

Agent 3 queries ChromaDB for the patient's insurer's policy documents, identifies coverage requirements, lists missing documentation, and flags whether pre-authorization is required.

#### Feature 4 — Justification Letter Generation

Agent 4 uses outputs from Agents 1, 2, and 3 to generate a full prior authorization letter — 2–3 pages, medically precise, written using real patient data rather than a generic template. Powered by Claude Sonnet 4.

#### Feature 5 — Autonomous Denial & Appeal ⭐ (Core USP)

When a submission is denied, Agent 6 automatically:
- Parses the denial reason
- Identifies counter-evidence from the patient record
- Writes a formal appeal letter (tone escalates with each level: professional → assertive → regulatory)
- Re-submits via Agent 5

Up to 3 levels. No human input needed.

#### Feature 6 — Prompt Configuration Panel

The Flutter Prompt Editor screen exposes all 7 agent system prompts via `GET/PUT /api/v1/prompts/{agent}`. Changes saved from the UI take effect on the next agent run — no server restart required.

---

### 🔮 Future Additions (Post-Hackathon Roadmap)

| Feature | Description |
|---|---|
| **Real Insurer API Integration** | Replace mocked Agent 5 with live connections to CMS portals and payer REST APIs |
| **HIPAA-Compliant PDF Generation** | Generate and transmit authorization letters as HIPAA-formatted fax PDFs |
| **Longitudinal Patient History** | HistoryAgent queries past authorizations and appeal outcomes to inform strategy |
| **WhatsApp Status Notifications** | Real-time appeal status updates to hospital staff via WhatsApp Business API |
| **On-Device Inference Mode** | Ollama-powered fallback for privacy-sensitive PHI processing |
| **EHR Integration** | Direct read from Epic/Cerner patient records to eliminate manual data entry |

---

## System Architecture

### State Machine Flow

```
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

### Key Design Decisions

**Why LangGraph?** It is a state-machine framework that natively handles conditional edges and cycles. The appeal loop (submission → appeal → re-submission) is a graph cycle. CrewAI and AutoGen cannot do this cleanly without workarounds.

**Why external YAML prompts?** Every agent's system prompt is a YAML file in `/prompts/`, surfaced in the Flutter Prompt Editor. Reviewers and clinicians can inspect and adjust agent behaviour without a developer. No prompt is hardcoded in Python.

**Why ChromaDB?** Insurance policies differ by insurer. ChromaDB stores policy PDFs as vector embeddings. Adding a new insurer requires only uploading their PDF and re-running the loader — zero code changes.

---

## The 7 Specialized Agents

> Each agent is a tool-using LLM node in the LangGraph state machine. Prompts are loaded from `backend/prompts/*.yaml`.

### 🧾 Agent 1 — Intake & History

| Property | Detail |
|---|---|
| **File** | `backend/agents/intake_agent.py` |
| **Function** | `run_intake_agent(patient_input: str) -> dict` |
| **Input** | Raw patient text (free-form or structured) |
| **Output** | Structured JSON: name, DOB, insurance, diagnoses, medications, allergies, procedures |
| **Prompt** | `backend/prompts/intake_prompt.yaml` |

### 🔬 Agent 2 — Medical Analysis

| Property | Detail |
|---|---|
| **File** | `backend/agents/medical_analysis_agent.py` |
| **Function** | `run_medical_analysis_agent(patient_profile, requested_treatment) -> dict` |
| **Input** | Patient profile from Agent 1 + treatment description |
| **Output** | ICD-10 codes, CPT codes, clinical necessity summary, step therapy flags |
| **Prompt** | `backend/prompts/medical_analysis_prompt.yaml` |

### 📋 Agent 3 — Policy Intelligence

| Property | Detail |
|---|---|
| **File** | `backend/agents/policy_agent.py` |
| **Function** | `run_policy_agent(patient_profile, insurer_name) -> dict` |
| **Input** | Patient profile + insurer name |
| **How it works** | Queries ChromaDB (RAG) for relevant policy sections, sends context to Claude |
| **Output** | Required docs list, missing documentation gaps, pre-auth required flag |
| **Prompt** | `backend/prompts/policy_prompt.yaml` |

### ✍️ Agent 4 — Justification Writer

| Property | Detail |
|---|---|
| **File** | `backend/agents/justification_agent.py` |
| **Function** | `run_justification_agent(patient_profile, medical_analysis, policy_check) -> str` |
| **Input** | Combined outputs from Agents 1, 2, and 3 |
| **Output** | Full prior auth justification letter as plain text (2–3 pages) |
| **Prompt** | `backend/prompts/justification_prompt.yaml` |

### 📡 Agent 5 — Submission & Monitor

| Property | Detail |
|---|---|
| **File** | `backend/agents/submission_agent.py` |
| **Function** | `submit_authorization(justification_letter, patient_profile) -> dict` |
| **Input** | Justification letter + patient profile |
| **Output** | Decision (approved/denied), denial reason if denied, reference number |
| **Note** | MVP uses mocked insurer response. Production would call payer REST API or generate fax PDF. |

### ⚔️ Agent 6 — Denial & Appeal ⭐

| Property | Detail |
|---|---|
| **File** | `backend/agents/appeal_agent.py` |
| **Function** | `run_appeal_agent(denial_reason, patient_profile, medical_analysis, appeal_level) -> str` |
| **Input** | Denial reason + patient data + appeal level (1, 2, or 3) |
| **Output** | Formal appeal letter — tone escalates with each level |
| **Loop logic** | `route_after_submission` and `route_after_appeal` in `orchestrator.py` |
| **Prompt** | `backend/prompts/appeal_prompt.yaml` |

### 🧮 Agent 7 — Claims Validation (Parallel Track)

| Property | Detail |
|---|---|
| **File** | `backend/agents/claims_agent.py` |
| **Function** | `run_claims_validation_agent(patient_id, icd10_codes, cpt_codes, documentation_list) -> dict` |
| **Input** | Billing codes and documentation list from previous agents |
| **Output** | Risk score (LOW / MEDIUM / HIGH), issues found, recommendation (SUBMIT / HOLD / AUTO_CORRECT) |
| **Prompt** | `backend/prompts/claims_prompt.yaml` |

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **LLM Core** | Claude Sonnet 4 (`claude-sonnet-4-20250514`) | All agents — medical writing and reasoning |
| **Agent Framework** | LangGraph 0.0.55 | State machine with cyclic appeal loop |
| **Backend API** | FastAPI 0.111.0 | REST endpoints, async orchestration |
| **Frontend** | Flutter 3.x (Dart) | Cross-platform mobile & web UI |
| **Database** | Supabase / PostgreSQL 15 + SQLAlchemy 2.0.30 | Patient records, auth requests, audit logs |
| **Vector Store** | ChromaDB 0.5.0 | Policy document RAG |
| **Prompt Storage** | YAML files | Editable via UI, no server restart needed |
| **Auth** | Supabase Auth + JWT (`python-jose`) | User authentication |
| **Containerisation** | Docker + docker-compose | Local dev and production parity |
| **Deployment** | Render.com | Backend API + PostgreSQL |
| **Python Version** | 3.11+ | — |

---

## Data Flow

### Patient Intake → Authorization Flow

```
1. Hospital staff enters patient history + treatment via Flutter app
        │
2. POST /api/v1/authorize triggers LangGraph orchestrator
        │
3. Agent 1 (Intake) → structured patient JSON
        │
4. Agent 2 (Medical Analysis) → ICD-10 / CPT codes + clinical summary
   └─────────────────────────────────────────────────────┐
                                                         │ (parallel)
                                              Agent 7 (Claims Validation)
                                              → risk score + billing flags
        │
5. Agent 3 (Policy Intelligence) → ChromaDB RAG query
   → coverage gaps + required documentation
        │
6. Agent 4 (Justification Writer) → full auth letter (Claude Sonnet 4)
        │
7. Agent 5 (Submission) → sends to insurer
        │
   ┌────┴────┐
Approved   Denied
   │          │
Done      Agent 6 (Appeal) → reads denial → writes appeal letter
               │
          Re-submit via Agent 5 (up to 3 levels)
               │
          Level 3 denial → Human escalation flag
```

### Autonomous Appeal Loop (Technical Detail)

```python
# In orchestrator.py

def route_after_submission(state: AuthState) -> str:
    decision = state["submission_result"]["decision"]
    if decision == "approved":
        return "approved"              # → END
    elif decision == "denied" and state["appeal_level"] < 3:
        return "appeal"               # → appeal_node
    else:
        return "escalate"             # → human_escalation_node → END

def route_after_appeal(state: AuthState) -> str:
    if state["appeal_level"] >= 3:
        return "escalate"
    return "resubmit"                 # → back to submission_node
```

The graph edge `"resubmit": "submission"` creates the cycle. LangGraph handles this natively. Appeal level is tracked in state and incremented in `appeal_node`. Each appeal generates a new letter with escalating tone configured in `appeal_prompt.yaml`.

---

## Project Structure

```
MediAuth-AI/
│
├── backend/                           # Python FastAPI + LangGraph
│   ├── agents/
│   │   ├── orchestrator.py            # LangGraph state machine — entry point
│   │   ├── intake_agent.py            # Agent 1 — patient profile extraction
│   │   ├── medical_analysis_agent.py  # Agent 2 — ICD-10 / CPT coding
│   │   ├── policy_agent.py            # Agent 3 — RAG policy intelligence
│   │   ├── justification_agent.py     # Agent 4 — authorization letter writer
│   │   ├── submission_agent.py        # Agent 5 — insurer submission & monitor
│   │   ├── appeal_agent.py            # Agent 6 — autonomous denial & appeal
│   │   └── claims_agent.py            # Agent 7 — parallel claims validation
│   ├── api/
│   │   └── routes/
│   │       ├── auth.py                # Authorize endpoint
│   │       ├── prompts.py             # Prompt CRUD endpoints
│   │       └── main.py                # FastAPI app entry point
│   ├── models/
│   │   ├── init_db.py                 # Table creation
│   │   └── schemas.py                 # SQLAlchemy + Pydantic models
│   ├── prompts/                       # ⭐ All agent prompts — editable via UI
│   │   ├── intake_prompt.yaml
│   │   ├── medical_analysis_prompt.yaml
│   │   ├── policy_prompt.yaml
│   │   ├── justification_prompt.yaml
│   │   ├── submission_prompt.yaml
│   │   ├── appeal_prompt.yaml
│   │   └── claims_prompt.yaml
│   ├── knowledge_base/
│   │   ├── loader.py                  # Seeds ChromaDB with policy PDFs
│   │   └── sample_policies/           # Drop insurer PDFs here
│   ├── utils/
│   │   ├── claude_client.py           # Anthropic SDK wrapper (strips JSON fences)
│   │   └── prompt_loader.py           # YAML prompt loader
│   ├── tests/
│   │   ├── test_intake_agent.py
│   │   ├── test_medical_agent.py
│   │   ├── test_appeal_agent.py
│   │   └── postman_collection.json
│   ├── requirements.txt
│   ├── .env.example
│   └── Dockerfile
│
├── mediauth_flutter/                  # Flutter frontend (Dart)
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       │   ├── patient_intake_screen.dart       # Screen 1 — intake form
│       │   ├── authorization_status_screen.dart # Screen 2 — status + audit trail
│       │   └── prompt_editor_screen.dart        # Screen 3 — prompt config panel
│       └── services/
│           └── api_service.dart                 # HTTP client + base URL config
│
├── supabase_setup.sql                 # Supabase RLS + user sync trigger
├── docker-compose.yml                 # Multi-container local setup
├── Dockerfile                         # Backend container
├── render.yaml                        # Render.com deployment blueprint
└── README.md
```

---

## Setup & Installation

### Prerequisites

```bash
# Check versions
python --version        # must be 3.11+
flutter --version       # must be 3.x
docker --version        # any recent version

# API keys needed
- Anthropic API key      # Claude Sonnet 4 — all agents
- PostgreSQL 15+         # or Supabase project
```

### Backend Setup

```bash
git clone https://github.com/JainRamyak/MediAuth-AI.git
cd MediAuth-AI/backend

python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

pip install -r requirements.txt

cp .env.example .env
# Open .env and set ANTHROPIC_API_KEY and DATABASE_URL

# Create PostgreSQL database
psql postgres -c "CREATE DATABASE mediauth;"
psql postgres -c "CREATE USER mediauth_user WITH PASSWORD 'mediauth_pass';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE mediauth TO mediauth_user;"

# Initialize tables
python models/init_db.py

# Seed ChromaDB with sample policy PDFs
python knowledge_base/loader.py

# Start API server
uvicorn api.main:app --reload
```

Verify: `curl http://localhost:8000/health` → `{"status":"ok"}`

### Flutter Setup

```bash
cd mediauth_flutter
flutter pub get
flutter run -d chrome       # or: flutter run (for connected device)
```

### Docker (Single Command)

```bash
cd MediAuth-AI
# Create .env with ANTHROPIC_API_KEY and JWT_SECRET
docker-compose up --build
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env`. **Never commit `.env` to the repository.**

```env
# ── LLM ───────────────────────────────────────────────────────────
ANTHROPIC_API_KEY=sk-ant-...          # Claude Sonnet 4 — all 7 agents

# ── Database ──────────────────────────────────────────────────────
# Local:
DATABASE_URL=postgresql://mediauth_user:mediauth_pass@localhost:5432/mediauth
# Render / Supabase:
DATABASE_URL=postgresql://user:password@hostname/database_name

# ── Auth ──────────────────────────────────────────────────────────
JWT_SECRET=your-long-random-secret    # Generate: openssl rand -hex 32
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# ── App ───────────────────────────────────────────────────────────
ENVIRONMENT=development               # or: production
```

---

## Running the Project

### Demo Flow (Practice This)

```
1. Open Flutter app → Patient Intake tab
2. Paste sample patient history (from /backend/tests/sample_patient.txt)
3. Enter requested treatment (e.g. "MRI Lumbar Spine")
4. Tap Submit → watch status screen load

5. Agent Activity Trail shows each agent completing in sequence
6. View the generated justification letter

7. Open Prompt Editor tab → select "appeal_agent"
8. Change "Level 1: professional tone" to "Level 1: very formal tone"
9. Tap Save — change takes effect immediately on the next run

10. Re-submit to trigger a denial (use the mock denial payload)
11. Watch Agent 6 fire automatically → appeal letter generated
12. Watch Agent 5 re-submit → Level 2 appeal if denied again
```

### Adding a New Insurer (No Code Required)

```bash
# 1. Get the insurer's policy PDF
# 2. Drop it into:
cp Aetna.pdf backend/knowledge_base/sample_policies/

# 3. Re-run the loader
python backend/knowledge_base/loader.py

# Done — Agent 3 will now RAG over Aetna's policies automatically
```

---

## Prompt Configuration

All 7 agent system prompts are stored in `backend/prompts/*.yaml` and exposed through the **Prompt Editor** in the Flutter app.

```yaml
# backend/prompts/appeal_prompt.yaml (excerpt)

system: |
  You are a medical authorization appeal specialist with deep knowledge of
  insurance regulations and patient rights. Write formal appeal letters that
  are medically precise, well-cited, and strategically persuasive.

  APPEAL LEVEL INSTRUCTIONS:
  Level 1 — Professional and factual. Cite clinical evidence and patient records.
  Level 2 — Assertive. Reference the insurer's own coverage criteria against the denial.
  Level 3 — Invoke regulatory language. Reference CMS guidelines and state insurance
             commissioner escalation pathways. Make clear this is a final appeal.

  RULES:
  - Every clinical claim must be grounded in the patient record. No unsupported assertions.
  - Include the original denial reason and directly rebut each point.
  - Always end with a specific request: approval, reconsideration, or expedited review.
  - Never threaten litigation — reference regulatory oversight only.

user_template: |
  Denial Reason: {denial_reason}
  Appeal Level: {appeal_level}
  Patient Profile: {patient_profile}
  Clinical Analysis: {medical_analysis}
  Write the Level {appeal_level} appeal letter.
```

### Editing Prompts via Flutter UI

1. Open the app → **Prompts** tab
2. Select an agent from the dropdown
3. Edit the `system:` or `user_template:` field
4. Tap **Save** — the YAML file updates immediately
5. No server restart needed — next request uses the new prompt
6. Tap **Reset** to restore the original

---

## API Documentation

Full Postman collection: `backend/tests/postman_collection.json`

Interactive docs when server is running: `http://localhost:8000/docs`

### Key Endpoints

#### Authorization Pipeline (FastAPI — port 8000)

```
GET    /health                       Server health check
POST   /api/v1/authorize             Run full 7-agent authorization workflow
GET    /api/v1/authorize/{id}        Get status of an auth request
```

#### Prompt Management

```
GET    /api/v1/prompts/              List all agent names
GET    /api/v1/prompts/{agent}       Get a specific agent's prompt YAML
PUT    /api/v1/prompts/{agent}       Update a prompt (no restart needed)
```

#### Request / Response Example

```bash
# Trigger full workflow
curl -X POST http://localhost:8000/api/v1/authorize \
  -H "Content-Type: application/json" \
  -d '{
    "patient_text": "Patient: Jane Doe, 54F. Diagnoses: Type 2 Diabetes, Chronic Back Pain. Medications: Metformin 500mg, Ibuprofen PRN. Insurer: BlueCross.",
    "requested_treatment": "MRI Lumbar Spine without contrast"
  }'

# Response
{
  "auth_request_id": "uuid-...",
  "workflow_status": "approved",
  "appeal_level": 0,
  "justification_letter": "Prior Authorization Request...",
  "audit_trail": [
    {"agent": "intake_agent", "status": "success", "timestamp": "..."},
    {"agent": "medical_analysis_agent", "status": "success", "timestamp": "..."},
    ...
  ]
}
```

---

## Database Schema

### `patients`

| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | Auto-generated |
| name | VARCHAR(255) | |
| date_of_birth | VARCHAR(20) | |
| insurance_policy_number | VARCHAR(100) | |
| insurer_name | VARCHAR(255) | |
| diagnoses | JSON | List of strings |
| medications | JSON | List of strings |
| structured_profile | JSON | Full Agent 1 output |
| created_at / updated_at | TIMESTAMP | |

### `auth_requests`

| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| patient_id | UUID (FK → patients) | |
| status | VARCHAR(50) | pending / submitted / approved / denied / appealing / escalated |
| icd10_codes | JSON | From Agent 2 |
| cpt_codes | JSON | From Agent 2 |
| justification_letter | TEXT | From Agent 4 |
| denial_reason | TEXT | From Agent 5 on denial |
| appeal_level | INTEGER | 0–3 |

### `audit_logs`

| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| auth_request_id | UUID | |
| agent_name | VARCHAR(100) | Which agent ran |
| action | VARCHAR(255) | What it did |
| input_data | JSON | Input sent to agent |
| output_data | JSON | Output from agent |
| status | VARCHAR(50) | success / error / escalated |

### `claims`

| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| auth_request_id | UUID | |
| billing_codes | JSON | |
| risk_score | VARCHAR(10) | LOW / MEDIUM / HIGH |
| risk_flags | JSON | List of identified issues |
| status | VARCHAR(50) | pending_review / submitted / denied |

---

## Testing

### Run All Tests

```bash
cd backend
source venv/bin/activate
pytest tests/ -v
```

### Run a Single Agent Test

```bash
pytest tests/test_intake_agent.py -v
pytest tests/test_appeal_agent.py -v
```

### Import Postman Collection

```
1. Open Postman
2. Import → backend/tests/postman_collection.json
3. Ensure backend is running on port 8000
4. Run collection
```

### What the Mocks Do

Unit tests mock `call_claude_for_json` and `call_claude` using `unittest.mock.patch`. Tests run without an Anthropic API key and without network calls — they validate agent logic (input/output structure, error handling) independently of LLM quality.

> **All test data is fully synthetic. No real patient health information is used anywhere in this project.**

---

## Deployment

### Render.com (Recommended)

| Field | Value |
|---|---|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn api.main:app --host 0.0.0.0 --port $PORT` |
| Environment Variables | `ANTHROPIC_API_KEY`, `DATABASE_URL`, `JWT_SECRET`, `ENVIRONMENT=production` |

> **ChromaDB note:** Render's free tier has an ephemeral filesystem. Embeddings generated by `loader.py` will not survive a restart. Use a volume mount or migrate to a hosted vector store (e.g. Pinecone) before production deployment.

### Flutter Web Build

```bash
cd mediauth_flutter
flutter build web
# Output: mediauth_flutter/build/web/
# Deploy to Vercel, Netlify, or Render static site

# Update API base URL before building:
# lib/services/api_service.dart → static const String baseUrl = 'https://your-app.onrender.com';
```

### Docker

```bash
docker-compose up --build
# Backend: http://localhost:8000
# Frontend: http://localhost:5173 (or run Flutter separately)
```

---

## Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'fastapi'` | venv not activated | `source venv/bin/activate` |
| `psycopg2.OperationalError` | PostgreSQL not running | `brew services start postgresql@15` |
| `anthropic.AuthenticationError` | Bad API key | Check `ANTHROPIC_API_KEY` in `.env` |
| `json.JSONDecodeError` in `call_claude_for_json` | Claude returned markdown fences | The cleaner in `claude_client.py` handles this — check for extra text |
| `ChromaDB InvalidCollectionException` | Embeddings not loaded | Run `python knowledge_base/loader.py` |
| Flutter CORS error | Backend CORS misconfigured | Check `CORSMiddleware` in `api/main.py` |
| `LangGraph KeyError` on state | Missing field in initial state | Check `AuthState` TypedDict matches initial state dict |
| Render deploy: `No module named 'psycopg2'` | Wrong package | Use `psycopg2-binary` in requirements.txt |

---

## Future Additions

These features are fully designed and ready for the next build sprint:

### Real Insurer API Integration

Connect Agent 5 to live CMS/payer portals with OAuth. Generate HIPAA-compliant authorization request PDFs. Support EDI 278 transaction format for enterprise insurers.

### Prescription Interaction Check Agent

OCR prescription upload → RxNorm drug lookup → drug interaction check against patient medication history → patient-friendly safety report with severity ratings.

### Insurance Claim Navigation Agent

Upload a rejected claim → cross-reference rejection reason against policy documents via RAG → identify appeal grounds with clause citations → generate a ready-to-submit appeal letter as PDF.

### Longitudinal Authorization History

HistoryAgent queries past auth requests and appeal outcomes to optimize justification letter strategy for repeat submissions.

---

## AI Context Guide

> **This section is written for AI coding assistants (Cursor, GitHub Copilot, Claude Code) to understand the project before generating code.**

### Critical Architectural Rules

**1. All agent prompts live in `backend/prompts/*.yaml` — never hardcode prompts in agent files.**

```python
# ✅ CORRECT
class IntakeAgent(BaseAgent):
    def __init__(self):
        self.prompt = load_prompt("intake_agent")  # reads from prompts/*.yaml

# ❌ WRONG
class IntakeAgent(BaseAgent):
    PROMPT = "You are a patient intake specialist..."
```

**2. Agents do not call each other — the LangGraph orchestrator manages all wiring.**

```python
# ✅ CORRECT — orchestrator passes state
def medical_analysis_node(state: AuthState) -> AuthState:
    result = run_medical_analysis_agent(state["patient_profile"], state["treatment"])
    return {**state, "medical_analysis": result}

# ❌ WRONG — agents calling each other directly
class MedicalAgent:
    async def run(self):
        intake_result = await IntakeAgent().run(...)  # never do this
```

**3. The `route_after_submission` function in `orchestrator.py` owns all appeal routing logic. Do not put routing decisions inside agent files.**

**4. The LangGraph state object must never be mutated in place — always return a new dict.**

**5. No API keys in source code — ever. All secrets via `os.getenv()`.**

### Core Data Models

```python
class AuthState(TypedDict):
    patient_input: str
    requested_treatment: str
    patient_profile: dict          # Agent 1 output
    medical_analysis: dict         # Agent 2 output
    policy_check: dict             # Agent 3 output
    justification_letter: str      # Agent 4 output
    submission_result: dict        # Agent 5 output — includes "decision" key
    appeal_level: int              # 0–3
    appeal_letter: str             # Agent 6 output
    claims_validation: dict        # Agent 7 output
    workflow_status: str           # pending / approved / denied / appealing / escalated
    audit_trail: list[dict]        # One entry per agent invocation
```

---

---

## Hackathon Evaluation Mapping

| Criterion | Where it is satisfied |
|---|---|
| Agentic Architecture | 7 agent files + `orchestrator.py` LangGraph state machine |
| Autonomous Reasoning | `appeal_agent.py` + orchestrator appeal loop — no human input |
| Technical Depth | LangGraph cycles + ChromaDB RAG + Claude Sonnet 4 + async FastAPI |
| Code Quality | One agent per file, `utils/` shared code, Pydantic-typed models |
| Prompt Inspectability | `prompts/*.yaml` + Flutter Prompt Editor + `PUT /api/v1/prompts/{agent}` |
| Testing | `tests/test_*.py` (pytest) + `tests/postman_collection.json` |
| Security | All keys in `.env`, JWT auth, Supabase RLS |
| User Experience | Flutter: intake form + status dashboard + prompt editor |
| Innovation | Multi-level autonomous appeal loop — novel application to healthcare auth |
| Deployment | Render.com live URL + Docker + docker-compose |

---

## Disclaimer

> MediAuth AI is a prototype built for the Veersa Hackathon 2027. It does **not** replace qualified medical advice, authorization decisions, or legal compliance review. All AI-generated authorization letters are explicitly labelled as system-generated. All test data used in this project is fully synthetic. No real patient health information was used in development or demonstration.

---

<p align="center">
  Built with depth. Explained with clarity. Demonstrated with confidence.<br/>
  <strong>MediAuth AI — Veersa Hackathon 2027</strong>
</p>
