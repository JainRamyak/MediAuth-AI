# MediAuth AI — Build Plan
> Veersa Hackathon 2027 | 2-Day MVP

---

## Project Overview

**System:** Multi-agent agentic AI for autonomous insurance authorization & appeal  
**Stack:** Python · FastAPI · LangGraph · Claude API · React + Vite · ChromaDB · PostgreSQL  
**Goal:** 7 specialized agents + 1 orchestrator covering the full insurance auth lifecycle

---

## Day 1 — Foundation + Core Agents

### Phase 1A — Repository & Infrastructure Setup
- [ ] Create GitHub repository (public)
- [ ] Define folder structure (`mediauth-ai/backend/`, `frontend/`, etc.)
- [ ] Initialize frontend with React + Vite ✅ *(already done)*
- [ ] Initialize backend with FastAPI skeleton (see Backend Init section below)
- [ ] Create `.env.example` with all required keys (Anthropic API key, DB URL, JWT secret)
- [ ] Set up `docker-compose.yml` for backend + PostgreSQL
- [ ] Verify `/health` endpoint returns `200 OK`
- [ ] Set up GitHub Actions or confirm Docker container runs cleanly

### Phase 1B — Database & Prompt Config
- [ ] Define SQLAlchemy models: `Patient`, `AuthRequest`, `AuditLog`, `Claim`
- [ ] Run initial migrations / create tables
- [ ] Create `/backend/prompts/` directory with YAML files for each agent:
  - [ ] `intake_prompt.yaml`
  - [ ] `medical_analysis_prompt.yaml`
  - [ ] `policy_prompt.yaml`
  - [ ] `justification_prompt.yaml`
  - [ ] `appeal_prompt.yaml`
  - [ ] `submission_prompt.yaml`
  - [ ] `claims_prompt.yaml`

### Phase 1C — Core Agents (Agents 1–3) + LangGraph State Machine
- [ ] **Agent 1 — Intake & History Agent**
  - [ ] Accept free-text or form input
  - [ ] Extract: demographics, diagnoses, medications, history, allergies, policy number
  - [ ] Output structured JSON patient profile
  - [ ] Handle missing fields with clarifying prompts
- [ ] **Agent 2 — Medical Analysis Agent**
  - [ ] Assign ICD-10 and CPT codes from patient history
  - [ ] Validate clinical necessity against accepted guidelines
  - [ ] Output clinical necessity summary
- [ ] **Agent 3 — Policy Intelligence Agent**
  - [ ] Set up ChromaDB locally with sample insurance policy PDFs
  - [ ] Implement semantic search over embedded policy text (RAG)
  - [ ] Determine required documentation per insurer
  - [ ] Flag gaps between available docs and insurer requirements
- [ ] **Orchestrator skeleton** — wire Agents 1→2→3 in LangGraph state machine
- [ ] Test patient intake API end-to-end via Postman

---

## Day 2 — Key Agents + Frontend + Deploy

### Phase 2A — Key Agents (Agents 4–7)
- [ ] **Agent 4 — Justification Writer Agent** *(star agent)*
  - [ ] Generate clinical narrative from patient history + diagnosis + treatment
  - [ ] Attach supporting evidence (labs, imaging, physician notes)
  - [ ] Adapt letter format to insurer template
  - [ ] Prompts fully configurable from YAML (no hardcoded prompts)
- [ ] **Agent 5 — Submission & Monitor Agent**
  - [ ] Submit authorization request (mock insurer API or PDF/fax output)
  - [ ] Poll for decision status on configurable schedule
  - [ ] Log all events with timestamps (audit trail)
  - [ ] Trigger Agent 6 on denial, notify user on approval
- [ ] **Agent 6 — Denial & Appeal Agent** *(key differentiator)*
  - [ ] Parse denial letter → extract specific rejection reason
  - [ ] Search patient record for counter-evidence
  - [ ] Write formal appeal letter citing applicable law
  - [ ] Re-submit via Agent 5
  - [ ] Loop up to 3 appeal levels (initial → peer-to-peer → external review)
  - [ ] Escalate to human when evidence is insufficient
- [ ] **Agent 7 — Claims Validation Agent**
  - [ ] Scan outgoing claims for missing/incorrect ICD-10/CPT codes
  - [ ] Verify all referenced documentation exists in system
  - [ ] Assign denial risk score: Low / Medium / High
  - [ ] Block High-risk claims for human review; auto-correct Low-risk issues
- [ ] **Orchestrator — complete wiring**
  - [ ] Full state machine: intake → analysis → policy → justify → submit → [approve | deny loop]
  - [ ] Branching logic: approval → end; denial → appeal loop; error → escalate
  - [ ] Persistent audit log for every agent action
  - [ ] Human-in-the-loop interface for physician sign-off cases

### Phase 2B — Frontend UI
- [ ] **Patient Intake Form** (`PatientIntake.jsx`)
  - [ ] Fields: demographics, diagnoses, medications, allergies, insurance policy number
  - [ ] File upload for medical records (PDF)
  - [ ] Submit button triggers orchestrator
- [ ] **Authorization Status Dashboard** (`AuthorizationStatus.jsx`)
  - [ ] Real-time agent progress indicator (which agent is currently active)
  - [ ] Approval / denial status display
  - [ ] Appeal history and current loop level
- [ ] **Prompt Editor Page** (`PromptEditor.jsx`)
  - [ ] Load and display all YAML prompt files
  - [ ] Allow reviewers to edit any agent's prompt from the UI
  - [ ] Save changes back to YAML (or hot-reload in memory for demo)

### Phase 2C — Testing
- [ ] **pytest unit tests** — at least one test per agent's core logic
- [ ] **Postman collection** — API integration tests for all major endpoints
- [ ] Confirm 2+ test types satisfy hackathon requirements

### Phase 2D — Deployment & Submission Polish
- [ ] Deploy backend to **Render.com** (free tier, connect from GitHub)
- [ ] Deploy frontend to **Render.com** or **Vercel**
- [ ] Confirm live deployment URL is accessible
- [ ] Write `README.md`:
  - [ ] Project description
  - [ ] Setup instructions (clone → `.env` → `docker-compose up`)
  - [ ] Architecture diagram (`architecture.png`)
  - [ ] Live deployment link
- [ ] Record demo video (walkthrough of patient intake → approval/denial → appeal)
- [ ] Submit GitHub repo link

---

## Backend Initialization (Do This Now)

Run the following in your terminal from the project root to initialize the backend:

```bash
# 1. Create backend folder structure
mkdir -p backend/{agents,api/routes,prompts,models,knowledge_base,tests}

# 2. Create a Python virtual environment
cd backend
python -m venv venv
source venv/bin/activate        # Mac/Linux
# venv\Scripts\activate         # Windows

# 3. Install core dependencies
pip install fastapi uvicorn sqlalchemy psycopg2-binary python-dotenv \
            pydantic langchain langgraph langchain-anthropic \
            chromadb python-jose[cryptography] pytest httpx

# 4. Freeze requirements
pip freeze > requirements.txt

# 5. Create the FastAPI entry point
touch api/main.py

# 6. Create placeholder agent files
touch agents/orchestrator.py \
      agents/intake_agent.py \
      agents/medical_analysis_agent.py \
      agents/policy_agent.py \
      agents/justification_agent.py \
      agents/submission_agent.py \
      agents/appeal_agent.py \
      agents/claims_agent.py

# 7. Create .env.example
touch .env.example
```

Paste this into `api/main.py` as the skeleton:

```python
from fastapi import FastAPI

app = FastAPI(title="MediAuth AI", version="0.1.0")

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "MediAuth AI"}
```

Paste this into `.env.example`:

```
ANTHROPIC_API_KEY=your_key_here
DATABASE_URL=postgresql://user:password@localhost:5432/mediauth
JWT_SECRET=your_jwt_secret_here
```

Run the server to verify:

```bash
uvicorn api.main:app --reload
# Visit http://localhost:8000/health
```

---

## Folder Structure Reference

```
mediauth-ai/
├── backend/
│   ├── agents/
│   │   ├── orchestrator.py
│   │   ├── intake_agent.py
│   │   ├── medical_analysis_agent.py
│   │   ├── policy_agent.py
│   │   ├── justification_agent.py
│   │   ├── submission_agent.py
│   │   ├── appeal_agent.py
│   │   └── claims_agent.py
│   ├── api/
│   │   ├── routes/
│   │   └── main.py
│   ├── prompts/          ← All agent prompts as YAML
│   ├── models/           ← SQLAlchemy DB models
│   ├── knowledge_base/   ← ChromaDB insurance policy vectors
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example
├── frontend/             ← React + Vite ✅
├── docker-compose.yml
└── README.md
```