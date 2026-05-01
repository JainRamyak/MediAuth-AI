# MediAuth AI — Complete Handoff Document
### Veersa Hackathon 2027 | ABES Batch of 2027
> **Purpose:** If someone new joins the project, the chat resets, or work is handed off between teammates, this document contains everything needed to understand the system, resume work, and make decisions without starting from scratch.

---

## 1. What Is This Project?

**MediAuth AI** is a multi-agent agentic AI system that automates insurance prior authorization and claims appeal for US healthcare. Instead of hospital staff spending hours on paperwork, 7 specialized AI agents coordinate to handle the entire process — from reading patient records to writing appeal letters and re-submitting denied claims.

**The core innovation** is Agent 6 (Denial & Appeal), which enters an autonomous loop: read denial → find counter-evidence from patient records → write formal appeal letter → re-submit. It continues for up to 3 appeal levels without human input.

**Why it matters:** Physicians spend 12+ hours/week on insurance paperwork. Over 70% of denials are due to preventable administrative errors. This system fixes both.

---

## 2. Repository Layout

```
mediauth-ai/                       ← GitHub repo root
├── backend/                       ← Python FastAPI + LangGraph
│   ├── agents/                    ← One file per AI agent
│   ├── api/routes/                ← FastAPI REST endpoints
│   ├── models/                    ← SQLAlchemy DB models
│   ├── prompts/                   ← All agent prompts as YAML (editable from UI)
│   ├── knowledge_base/            ← ChromaDB vector store for insurance policies
│   ├── utils/                     ← Shared utilities (Claude client, prompt loader)
│   ├── tests/                     ← pytest + Postman collection
│   ├── requirements.txt
│   ├── .env.example
│   └── Dockerfile
├── frontend/                      ← Flutter app
│   └── lib/
│       ├── main.dart
│       ├── screens/               ← 3 screens
│       └── services/              ← API service layer
├── docker-compose.yml
└── README.md
```

---

## 3. Tech Stack (Quick Reference)

| Component | Technology | Version |
|---|---|---|
| LLM | Claude Sonnet 4 via Anthropic API | claude-sonnet-4-20250514 |
| Agent orchestration | LangGraph | 0.0.55 |
| Backend framework | FastAPI | 0.111.0 |
| Frontend | Flutter | 3.x (Dart) |
| Database | PostgreSQL 15 + SQLAlchemy | 2.0.30 |
| Vector store | ChromaDB | 0.5.0 |
| Prompt storage | YAML files | — |
| Deployment | Render.com (free tier) | — |
| Containerization | Docker + docker-compose | — |
| Python version | 3.11+ | — |

---

## 4. Environment Variables

All secrets go in `backend/.env`. Never commit this file. The `.env.example` file shows the structure.

| Variable | Description | Where to get it |
|---|---|---|
| `ANTHROPIC_API_KEY` | Key to call Claude API | https://console.anthropic.com |
| `DATABASE_URL` | PostgreSQL connection string | Your local/Render PostgreSQL instance |
| `JWT_SECRET` | Any long random string for JWT signing | Generate: `openssl rand -hex 32` |
| `JWT_ALGORITHM` | Always `HS256` | Hardcode |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Hardcode |
| `ENVIRONMENT` | `development` or `production` | Set per environment |

**Local database URL format:**
```
postgresql://mediauth_user:mediauth_pass@localhost:5432/mediauth
```

**Render.com database URL format:**
```
postgresql://user:password@hostname/database_name
```

---

## 5. How to Start the Project (Fresh Machine)

### Prerequisites
```bash
python --version      # must be 3.11+
flutter --version     # must be 3.x
docker --version      # any recent version
psql --version        # PostgreSQL 15+
```

### Backend setup
```bash
git clone https://github.com/YOUR_TEAM/mediauth-ai.git
cd mediauth-ai/backend

python -m venv venv
source venv/bin/activate         # Mac/Linux
# venv\Scripts\activate          # Windows

pip install -r requirements.txt

cp .env.example .env
# Open .env and set your ANTHROPIC_API_KEY

# Create database (PostgreSQL must be running)
psql postgres -c "CREATE DATABASE mediauth;"
psql postgres -c "CREATE USER mediauth_user WITH PASSWORD 'mediauth_pass';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE mediauth TO mediauth_user;"

python models/init_db.py          # Creates all tables
python knowledge_base/loader.py   # Loads policy data into ChromaDB

uvicorn api.main:app --reload     # Starts server
```

Verify: `curl http://localhost:8000/health` → `{"status":"ok"}`

### Frontend setup
```bash
cd mediauth-ai/frontend
flutter pub get
flutter run -d chrome    # or: flutter run (for device/emulator)
```

### Docker (alternative to manual setup)
```bash
cd mediauth-ai
# Create .env in project root with ANTHROPIC_API_KEY and JWT_SECRET
docker-compose up --build
```

---

## 6. The 7 Agents — What Each One Does

### Agent 1 — Intake & History Agent
**File:** `backend/agents/intake_agent.py`  
**Function:** `run_intake_agent(patient_input: str) -> dict`  
**Input:** Raw patient text (free-form or structured)  
**Output:** Structured JSON patient profile with name, DOB, insurance, diagnoses, medications, allergies, past procedures  
**Called by:** Orchestrator as the first step  
**Prompt file:** `backend/prompts/intake_prompt.yaml`

### Agent 2 — Medical Analysis Agent
**File:** `backend/agents/medical_analysis_agent.py`  
**Function:** `run_medical_analysis_agent(patient_profile, requested_treatment) -> dict`  
**Input:** Patient profile dict from Agent 1 + treatment description string  
**Output:** ICD-10 codes, CPT codes, clinical necessity summary, step therapy flags  
**Called by:** Orchestrator after Agent 1  
**Prompt file:** `backend/prompts/medical_analysis_prompt.yaml`

### Agent 3 — Policy Intelligence Agent
**File:** `backend/agents/policy_agent.py`  
**Function:** `run_policy_agent(patient_profile, insurer_name) -> dict`  
**Input:** Patient profile + insurer name  
**How it works:** Queries ChromaDB (RAG) for relevant policy sections, sends to Claude  
**Output:** Required documentation list, missing documentation gaps, pre-auth required flag  
**Called by:** Orchestrator after Agent 2  
**Prompt file:** `backend/prompts/policy_prompt.yaml`

### Agent 4 — Justification Writer Agent
**File:** `backend/agents/justification_agent.py`  
**Function:** `run_justification_agent(patient_profile, medical_analysis, policy_check) -> str`  
**Input:** Outputs from Agents 1, 2, 3  
**Output:** Full prior authorization justification letter as plain text (2–3 pages)  
**Called by:** Orchestrator after Agent 3  
**Prompt file:** `backend/prompts/justification_prompt.yaml`  
**Note:** This is the "star" agent — the letter must use real patient data, not generic templates.

### Agent 5 — Submission & Monitor Agent
**File:** `backend/agents/submission_agent.py`  
**Function:** `submit_authorization(justification_letter, patient_profile) -> dict`  
**Input:** Justification letter + patient profile  
**Output:** Decision (approved/denied), denial reason if denied, reference number, timestamp  
**Called by:** Orchestrator after Agent 4 and again after each appeal  
**Note:** In the hackathon MVP, this uses a mock insurer response. In production, this would call the insurer's REST API or generate a PDF for fax.

### Agent 6 — Denial & Appeal Agent
**File:** `backend/agents/appeal_agent.py`  
**Function:** `run_appeal_agent(denial_reason, patient_profile, medical_analysis, appeal_level) -> str`  
**Input:** Denial reason string, patient data, appeal level (1, 2, or 3)  
**Output:** Formal appeal letter as plain text, tone escalates with appeal level  
**Called by:** Orchestrator on denial. Loops: submit → denied → appeal → re-submit → denied → appeal (up to 3 levels)  
**Prompt file:** `backend/prompts/appeal_prompt.yaml`  
**Loop logic lives in:** Orchestrator routing functions `route_after_submission` and `route_after_appeal`

### Agent 7 — Claims Validation Agent
**File:** `backend/agents/claims_agent.py`  
**Function:** `run_claims_validation_agent(patient_id, icd10_codes, cpt_codes, documentation_list) -> dict`  
**Input:** Billing codes and documentation list from previous agents  
**Output:** Risk score (LOW/MEDIUM/HIGH), issues found, recommendation (SUBMIT/HOLD/AUTO_CORRECT)  
**Called by:** Orchestrator as a parallel track — runs alongside the main authorization flow  
**Prompt file:** `backend/prompts/claims_prompt.yaml`

---

## 7. The Orchestrator — How It Works

**File:** `backend/agents/orchestrator.py`  
**Entry point:** `run_authorization_workflow(patient_input: str, treatment: str) -> AuthState`

### State Machine Flow

```
Entry: intake
  ↓
medical_analysis
  ↓
policy
  ↓
justification
  ↓
submission ──→ APPROVED ──→ END
     ↓ DENIED
appeal (level + 1)
     ↓
submission ──→ APPROVED ──→ END
     ↓ DENIED (level < 3)
appeal (level + 1)
     ↓
submission ──→ APPROVED ──→ END
     ↓ DENIED (level = 3)
human_escalation ──→ END

Parallel: claims_validation runs alongside
```

### Key Design Decisions

**Why LangGraph?** It's a state-machine framework that natively handles conditional edges and loops. The appeal loop (submission → appeal → submission) is a cycle in the graph. CrewAI and AutoGen can't do this cleanly.

**Why external YAML prompts?** The hackathon requires prompts to be inspectable and modifiable by reviewers. Every system prompt is a YAML file in `/prompts/` and surfaced in the Flutter Prompt Editor screen. No prompt is hardcoded in Python.

**Why ChromaDB?** Insurance policies differ across insurers. ChromaDB stores policy PDFs as vector embeddings. Adding a new insurer = uploading their PDF. No code changes needed.

---

## 8. Database Schema

### `patients` table
| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | Auto-generated |
| name | VARCHAR(255) | |
| date_of_birth | VARCHAR(20) | |
| insurance_policy_number | VARCHAR(100) | |
| insurer_name | VARCHAR(255) | |
| diagnoses | JSON | List of strings |
| medications | JSON | List of strings |
| allergies | JSON | List of strings |
| medical_history | TEXT | Free text |
| structured_profile | JSON | Full Agent 1 output |
| created_at | TIMESTAMP | |
| updated_at | TIMESTAMP | |

### `auth_requests` table
| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| patient_id | UUID (FK → patients) | |
| status | VARCHAR(50) | pending/submitted/approved/denied/appealing/escalated/closed |
| icd10_codes | JSON | From Agent 2 |
| cpt_codes | JSON | From Agent 2 |
| clinical_summary | TEXT | From Agent 2 |
| justification_letter | TEXT | From Agent 4 |
| denial_reason | TEXT | From Agent 5 on denial |
| appeal_level | INTEGER | 0–3 |
| insurer_response | TEXT | Raw insurer response |
| created_at / updated_at | TIMESTAMP | |

### `audit_logs` table
| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| auth_request_id | UUID | |
| agent_name | VARCHAR(100) | Which agent ran |
| action | VARCHAR(255) | What it did |
| input_data | JSON | Input sent to agent |
| output_data | JSON | Output from agent |
| status | VARCHAR(50) | success/error/escalated |
| error_message | TEXT | Nullable |
| timestamp | TIMESTAMP | |

### `claims` table
| Column | Type | Notes |
|---|---|---|
| id | UUID (PK) | |
| auth_request_id | UUID | |
| billing_codes | JSON | |
| risk_score | VARCHAR(10) | LOW/MEDIUM/HIGH |
| risk_flags | JSON | List of issues |
| status | VARCHAR(50) | pending_review/submitted/denied/resubmitted |
| corrected_codes | JSON | Auto-corrected codes if any |
| created_at | TIMESTAMP | |

---

## 9. API Endpoints Reference

Base URL (local): `http://localhost:8000`  
Base URL (production): `https://your-app.onrender.com`

| Method | Endpoint | Description | Request Body | Response |
|---|---|---|---|---|
| GET | `/health` | Server health check | None | `{"status":"ok"}` |
| POST | `/api/v1/authorize` | Run full authorization workflow | `{patient_text, requested_treatment}` | `{auth_request_id, workflow_status, appeal_level, justification_letter, audit_trail}` |
| GET | `/api/v1/authorize/{id}` | Get status of an auth request | None | `{id, status, appeal_level, created_at}` |
| GET | `/api/v1/prompts/` | List all agent names | None | `{"agents": [...]}` |
| GET | `/api/v1/prompts/{agent}` | Get a specific agent's prompt | None | `{system, user_template}` |
| PUT | `/api/v1/prompts/{agent}` | Update a prompt | `{system, user_template}` | `{success, agent}` |

**Interactive docs:** `http://localhost:8000/docs` (Swagger UI auto-generated by FastAPI)

---

## 10. Flutter Frontend — Screen Reference

### Screen 1: Patient Intake (`patient_intake_screen.dart`)
- **Purpose:** Entry point for submitting a new authorization request
- **Fields:** Patient medical history (large text area), requested treatment (text field)
- **On submit:** Calls `ApiService.submitAuthorization()` → navigates to Status screen
- **Loading state:** Button shows spinner while API call is in progress

### Screen 2: Authorization Status (`authorization_status_screen.dart`)
- **Purpose:** Shows the result of the authorization workflow
- **Displays:** Status banner (color-coded: green=approved, red=denied, orange=appealing), agent activity trail, justification letter preview
- **Data source:** Response from `POST /api/v1/authorize`

### Screen 3: Prompt Editor (`prompt_editor_screen.dart`)
- **Purpose:** Allows reviewers to inspect and edit any agent's system prompt without touching code
- **Interaction:** Dropdown to select agent → loads YAML from API → editable text fields → Save button
- **Calls:** `GET /api/v1/prompts/{agent}` to load, `PUT /api/v1/prompts/{agent}` to save

### Navigation
- Bottom navigation bar with 2 tabs: "Authorize" (Patient Intake) and "Prompts" (Prompt Editor)
- Status screen is pushed on top of Intake screen after submission

---

## 11. Adding a New Insurer

To support a new insurance company without writing any code:

1. Get the insurer's policy PDF document
2. Place it in `backend/knowledge_base/sample_policies/` — name it after the insurer (e.g., `Aetna.pdf`)
3. Re-run the loader: `python knowledge_base/loader.py`
4. ChromaDB now contains embeddings for the new policy
5. When a patient's insurer name matches, Agent 3 queries the relevant policy sections automatically

---

## 12. Modifying an Agent's Behavior

**Without restarting the server:**
1. Open the Flutter app → Prompts tab
2. Select the agent from the dropdown
3. Edit the system prompt or user template
4. Click Save — the YAML file is updated immediately
5. The next API call will use the new prompt (no restart needed)

**In the file system directly:**
1. Open `backend/prompts/{agent_name}_prompt.yaml`
2. Edit the `system:` or `user_template:` field
3. Save the file — changes are picked up on the next request

---

## 13. How the Appeal Loop Works (Technical Detail)

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

The graph edge `"resubmit": "submission"` creates the cycle. LangGraph handles this natively.  
Appeal level is tracked in `state["appeal_level"]` and incremented in `appeal_node`.  
Each appeal generates a new letter with escalating tone (configured in `appeal_prompt.yaml`).

---

## 14. Testing Reference

### Run all unit tests
```bash
cd backend
source venv/bin/activate
pytest tests/ -v
```

### Run a single test file
```bash
pytest tests/test_intake_agent.py -v
```

### Import Postman collection
1. Open Postman
2. Click Import → Upload `backend/tests/postman_collection.json`
3. Make sure backend is running on port 8000
4. Run collection

### What the mocks do
Unit tests mock `call_claude_for_json` and `call_claude` using `unittest.mock.patch`. This means tests run without an Anthropic API key and without network calls. They test the agent logic (input/output structure, error handling) not the LLM quality.

---

## 15. Deployment Reference

### Render.com deployment settings

| Field | Value |
|---|---|
| Root Directory | `backend` |
| Build Command | `pip install -r requirements.txt` |
| Start Command | `uvicorn api.main:app --host 0.0.0.0 --port $PORT` |
| Environment Variables | `ANTHROPIC_API_KEY`, `DATABASE_URL`, `JWT_SECRET`, `ENVIRONMENT=production` |

### Flutter web build
```bash
cd frontend
flutter build web
# Output is in: frontend/build/web/
# Upload this folder to Vercel, Netlify, or Render static site
```

### Update `api_service.dart` for production
```dart
// Change this line in lib/services/api_service.dart:
static const String baseUrl = 'https://your-app.onrender.com';
```

---

## 16. Common Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'fastapi'` | venv not activated | `source venv/bin/activate` |
| `psycopg2.OperationalError: could not connect to server` | PostgreSQL not running | `brew services start postgresql@15` or `sudo service postgresql start` |
| `anthropic.AuthenticationError` | Bad API key | Check `ANTHROPIC_API_KEY` in `.env` |
| `json.JSONDecodeError` in `call_claude_for_json` | Claude returned markdown fences around JSON | The cleaner in `claude_client.py` strips fences; check if Claude added extra text |
| ChromaDB `InvalidCollectionException` | Collection not initialized | Run `python knowledge_base/loader.py` |
| Flutter CORS error | Backend CORS middleware missing | Check `CORSMiddleware` in `api/main.py` with `allow_origins=["*"]` |
| LangGraph `KeyError` on state | Missing field in initial state | Check `AuthState` TypedDict matches `run_authorization_workflow` initial state dict |
| Render deploy fails: `No module named 'psycopg2'` | Binary package needed | Use `psycopg2-binary` in requirements.txt, not `psycopg2` |
| Flutter: `Null check operator used on a null value` | API response field missing | Add null checks (`?.` and `??`) in Dart screens |
| `LangGraph cycle detected` error | Old version of LangGraph | Upgrade: `pip install langgraph==0.0.55` |

---

## 17. Hackathon Evaluation Mapping

| Criterion | Where it's satisfied in the code |
|---|---|
| Agentic Architecture | 7 agent files + `orchestrator.py` with LangGraph state machine |
| Autonomous Reasoning | `appeal_agent.py` + orchestrator appeal loop (no human input) |
| Technical Depth | LangGraph cycles + ChromaDB RAG + Anthropic API + async FastAPI |
| Code Quality | One agent per file, `utils/` shared code, typed Python with Pydantic |
| Prompt Inspectability | `prompts/*.yaml` + `prompt_editor_screen.dart` + `PUT /api/v1/prompts/{agent}` |
| Testing | `tests/test_*.py` (pytest) + `tests/postman_collection.json` |
| Security | All keys in `.env`, `.env.example` provided, `python-jose` JWT |
| User Experience | Flutter app: intake form + status dashboard + prompt editor |
| Innovation | Multi-level autonomous appeal loop — novel application to healthcare |
| Deployment | Render.com live URL + Docker + docker-compose (bonus points) |

---

## 18. Team Responsibilities (Template)

> Fill in team member names and assign ownership.

| Area | Owner | GitHub Handle |
|---|---|---|
| Orchestrator + LangGraph | | |
| Agents 1–3 (Intake, Medical, Policy) | | |
| Agents 4–6 (Justify, Submit, Appeal) | | |
| Agent 7 + Claims Validation | | |
| FastAPI Routes | | |
| Flutter Frontend | | |
| Database Models | | |
| Testing | | |
| Docker + Deployment | | |
| README + Demo Video | | |

---

## 19. Definition of Done

The project is complete and ready to submit when:

- [ ] `curl https://your-app.onrender.com/health` returns `{"status":"ok"}`
- [ ] Flutter app loads and Patient Intake form submits successfully
- [ ] Authorization Status screen shows agent activity trail and justification letter
- [ ] Prompt Editor loads and saves prompts
- [ ] `pytest tests/ -v` shows all tests passing
- [ ] `docker-compose up --build` starts both backend and database
- [ ] README.md has live URL, setup instructions, and architecture diagram
- [ ] All team members have at least 1 commit each on the public GitHub repo
- [ ] Demo video is recorded and linked in README
- [ ] Hackathon submission form is submitted
