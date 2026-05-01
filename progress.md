# MediAuth AI — Progress Report

### Veersa Hackathon 2027 | ABES Batch of 2027

> **This is your live tracking file.** Update it every time you complete a step.
> If the chat resets, share this file first so work can resume exactly where you
> left off.

---

## Quick Resume Summary

> Fill this in every time you pause. When you resume, read only this box first.

```
Last updated      : _______________
Last phase done   : _______________
Last thing I did  : _______________
Next thing to do  : _______________
Blockers          : _______________
Backend running?  : YES / NO
DB tables created?: YES / NO
Flutter running?  : YES / NO
```

---

## Overall Progress

| Phase | Name                            | Status         | Verified |
| ----- | ------------------------------- | -------------- | -------- |
| 0     | Environment Setup               | 🔲 Not Started | 🔲       |
| 1     | Backend Foundation              | 🔲 Not Started | 🔲       |
| 2     | Database Layer                  | 🔲 Not Started | 🔲       |
| 3     | Prompt Config System            | 🔲 Not Started | 🔲       |
| 4     | ChromaDB Knowledge Base         | 🔲 Not Started | 🔲       |
| 5     | Agents 1–3                      | 🔲 Not Started | 🔲       |
| 6     | LangGraph Orchestrator Skeleton | 🔲 Not Started | 🔲       |
| 7     | Agents 4–7                      | 🔲 Not Started | 🔲       |
| 8     | Orchestrator Complete Wiring    | 🔲 Not Started | 🔲       |
| 9     | FastAPI Routes                  | 🔲 Not Started | 🔲       |
| 10    | Flutter Frontend                | 🔲 Not Started | 🔲       |
| 11    | Testing                         | 🔲 Not Started | 🔲       |
| 12    | Docker                          | 🔲 Not Started | 🔲       |
| 13    | Deployment                      | 🔲 Not Started | 🔲       |
| 14    | Submission Polish               | 🔲 Not Started | 🔲       |

**Status key:** 🔲 Not Started &nbsp;|&nbsp; 🟡 In Progress &nbsp;|&nbsp; ✅
Complete &nbsp;|&nbsp; ❌ Blocked

---

## Phase 0 — Environment Setup

**Goal:** All tools installed and working before writing any code.

- [ ] Python 3.11+ installed → verified with `python --version`
- [ ] Flutter installed → verified with `flutter --version`
- [ ] `flutter doctor` shows no critical errors
- [ ] PostgreSQL installed and running
- [ ] Database `mediauth` created
- [ ] User `mediauth_user` created with password
- [ ] Privileges granted to `mediauth_user` on `mediauth` database
- [ ] Docker Desktop installed → verified with `docker --version`

**Verification command output (paste here):**

```
python --version  →
flutter --version →
psql test result  →
docker --version  →
```

**Phase 0 Status:** 🔲 Not Started

---

## Phase 1 — Backend Foundation

**Goal:** FastAPI server running at `http://localhost:8000/health`

- [ ] `backend/` folder created
- [ ] Sub-folders created: `agents/`, `api/routes/`, `models/`, `prompts/`,
      `knowledge_base/sample_policies/`, `tests/`, `utils/`
- [ ] All `__init__.py` files created
- [ ] Python virtual environment created inside `backend/`
- [ ] Virtual environment activated (see `(venv)` in terminal)
- [ ] All pip packages installed
- [ ] `requirements.txt` generated with `pip freeze`
- [ ] `.env.example` created with all required keys
- [ ] `.env` created with real `ANTHROPIC_API_KEY` filled in
- [ ] `api/main.py` created with FastAPI app and `/health` endpoint
- [ ] Server starts without errors: `uvicorn api.main:app --reload`

**Verification:**

```
curl http://localhost:8000/health
Expected: {"status":"ok","service":"MediAuth AI","version":"0.1.0","environment":"development"}

Actual output →
```

**Phase 1 Status:** 🔲 Not Started

---

## Phase 2 — Database Layer

**Goal:** 4 tables created in PostgreSQL.

- [ ] `models/database.py` created (engine, SessionLocal, Base, get_db)
- [ ] `models/patient.py` created (Patient model with all columns)
- [ ] `models/auth_request.py` created (AuthRequest model)
- [ ] `models/audit_log.py` created (AuditLog model)
- [ ] `models/claim.py` created (Claim model)
- [ ] `models/init_db.py` created
- [ ] `python models/init_db.py` run successfully
- [ ] "All tables created successfully." printed in terminal

**Verification:**

```
psql -U mediauth_user -d mediauth -c "\dt"
Expected: 4 tables — patients, auth_requests, audit_logs, claims

Actual output →
```

**Phase 2 Status:** 🔲 Not Started

---

## Phase 3 — Prompt Config System

**Goal:** All 7 agent prompts stored as YAML. Prompt loader works.

- [ ] `prompts/intake_prompt.yaml` created
- [ ] `prompts/medical_analysis_prompt.yaml` created
- [ ] `prompts/policy_prompt.yaml` created
- [ ] `prompts/justification_prompt.yaml` created
- [ ] `prompts/appeal_prompt.yaml` created
- [ ] `prompts/submission_prompt.yaml` created
- [ ] `prompts/claims_prompt.yaml` created
- [ ] `utils/prompt_loader.py` created (load_prompt, get_system_prompt,
      get_user_prompt, update_prompt)
- [ ] `utils/claude_client.py` created (call_claude, call_claude_for_json)

**Verification:**

```
python -c "from utils.prompt_loader import get_system_prompt; print(get_system_prompt('intake'))"
Expected: Prints the intake system prompt text. No errors.

Actual output →
```

**Phase 3 Status:** 🔲 Not Started

---

## Phase 4 — ChromaDB Knowledge Base

**Goal:** ChromaDB loaded with policy data. Query returns results.

- [ ] `knowledge_base/loader.py` created
- [ ] Sample policy PDFs placed in `knowledge_base/sample_policies/` (or sample
      text used for demo)
- [ ] `python knowledge_base/loader.py` run successfully
- [ ] "Knowledge base ready." printed
- [ ] Test query returns at least 1 result

**Verification:**

```
python -c "from knowledge_base.loader import query_policies; r = query_policies('prior authorization'); print(len(r), 'results')"
Expected: "1 results" or more. No errors.

Actual output →
```

**Phase 4 Status:** 🔲 Not Started

---

## Phase 5 — Agents 1–3

**Goal:** First three agents built and individually testable.

### Agent 1 — Intake & History Agent

- [ ] `agents/intake_agent.py` created
- [ ] `run_intake_agent(patient_input)` function implemented
- [ ] Returns dict with `status: "success"` and structured profile fields
- [ ] Handles errors gracefully (returns `status: "error"`)
- [ ] Manually tested with sample patient text

**Agent 1 test output:**

```
Agent 1 status  →
Has "name" key  →
Has "diagnoses" →
```

### Agent 2 — Medical Analysis Agent

- [ ] `agents/medical_analysis_agent.py` created
- [ ] `run_medical_analysis_agent(patient_profile, requested_treatment)`
      implemented
- [ ] Returns dict with `icd10_codes`, `cpt_codes`, `clinical_necessity_summary`
- [ ] Manually tested

**Agent 2 test output:**

```
Agent 2 status        →
ICD-10 codes returned →
CPT codes returned    →
```

### Agent 3 — Policy Intelligence Agent

- [ ] `agents/policy_agent.py` created
- [ ] `run_policy_agent(patient_profile, insurer_name)` implemented
- [ ] Calls ChromaDB for RAG query
- [ ] Returns `required_documentation`, `missing_documentation`,
      `pre_auth_required`
- [ ] Manually tested

**Agent 3 test output:**

```
Agent 3 status              →
Pre-auth required field     →
Missing documentation field →
```

**Phase 5 Status:** 🔲 Not Started

---

## Phase 6 — LangGraph Orchestrator Skeleton

**Goal:** Agents 1–3 wired in LangGraph. End-to-end flow runs (with placeholders
for 4–7).

- [ ] `agents/orchestrator.py` created
- [ ] `AuthState` TypedDict defined with all fields
- [ ] Node functions created for all 7 agents (placeholder nodes for 4–7 are
      fine)
- [ ] Routing functions `route_after_submission` and `route_after_appeal`
      implemented
- [ ] Graph built with `StateGraph` and `compile()`
- [ ] `run_authorization_workflow(patient_input, treatment)` entry point works
- [ ] Appeal loop confirmed working (state loops through submission → appeal →
      submission)

**Verification:**

```
python -c "from agents.orchestrator import run_authorization_workflow; r = run_authorization_workflow('Patient: Jane, Insurance: BC, Diagnoses: Back Pain', 'MRI'); print('Status:', r['workflow_status']); print('Agents:', [a['agent'] for a in r['audit_trail']])"

Actual output →
Appeal level reached →
```

**Phase 6 Status:** 🔲 Not Started

---

## Phase 7 — Agents 4–7

**Goal:** All 7 agents fully implemented and integrated into orchestrator.

### Agent 4 — Justification Writer Agent

- [ ] `agents/justification_agent.py` created
- [ ] `run_justification_agent(patient_profile, medical_analysis, policy_check)`
      implemented
- [ ] Generates full clinical justification letter (not a template — uses real
      patient data)
- [ ] Orchestrator `justification_node` updated to call this function
- [ ] Tested: letter is non-empty and patient-specific

**Agent 4 output check:**

```
Letter generated       →  YES / NO
Letter length (chars)  →
Contains patient name  →  YES / NO
```

### Agent 5 — Submission & Monitor Agent

- [ ] `agents/submission_agent.py` created
- [ ] `submit_authorization(justification_letter, patient_profile)` implemented
- [ ] Mock response returns `approved` or `denied` with denial reason
- [ ] Orchestrator `submission_node` updated to call this function
- [ ] Audit log entry created on submission

**Agent 5 output check:**

```
Decision returned     →
Reference number      →
Timestamp present     →  YES / NO
```

### Agent 6 — Denial & Appeal Agent

- [ ] `agents/appeal_agent.py` created
- [ ] `run_appeal_agent(denial_reason, patient_profile, medical_analysis, appeal_level)`
      implemented
- [ ] Appeal letter cites denial reason and counter-evidence
- [ ] Tone escalates at levels 2 and 3
- [ ] Orchestrator `appeal_node` updated to call this function
- [ ] Loop confirmed: appeal level increments on each cycle

**Agent 6 output check:**

```
Appeal letter generated     →  YES / NO
Letter references denial    →  YES / NO
Loop increments correctly   →  YES / NO
```

### Agent 7 — Claims Validation Agent

- [ ] `agents/claims_agent.py` created
- [ ] `run_claims_validation_agent(patient_id, icd10_codes, cpt_codes, documentation_list)`
      implemented
- [ ] Returns `risk_score` (LOW/MEDIUM/HIGH) and `issues_found`
- [ ] Returns `recommendation` (SUBMIT / HOLD_FOR_REVIEW /
      AUTO_CORRECT_AND_SUBMIT)
- [ ] Orchestrator `claims_validation_node` updated to call this function

**Agent 7 output check:**

```
Risk score returned         →
Issues found (count)        →
Recommendation returned     →
```

**Phase 7 Status:** 🔲 Not Started

---

## Phase 8 — Orchestrator Complete Wiring

**Goal:** Full orchestrator with audit logging, human escalation, and parallel
claims validation.

- [ ] `save_audit_log()` function added to `orchestrator.py`
- [ ] Each agent node calls `save_audit_log()` after running
- [ ] `human_escalation_node` added and wired to `"escalate"` edge
- [ ] Graph recompiled with new node
- [ ] End-to-end run saves entries to `audit_logs` table in database

**Verification:**

```
psql -U mediauth_user -d mediauth -c "SELECT agent_name, status FROM audit_logs ORDER BY timestamp DESC LIMIT 5;"

Actual output →
```

**Phase 8 Status:** 🔲 Not Started

---

## Phase 9 — FastAPI Routes

**Goal:** REST API endpoints working for authorization workflow and prompt
management.

- [ ] `api/routes/authorization.py` created
- [ ] `POST /api/v1/authorize` endpoint working
- [ ] `GET /api/v1/authorize/{id}` endpoint working
- [ ] `api/routes/prompts.py` created
- [ ] `GET /api/v1/prompts/` lists all agents
- [ ] `GET /api/v1/prompts/{agent_name}` returns prompt YAML content
- [ ] `PUT /api/v1/prompts/{agent_name}` updates prompt from UI
- [ ] Routers registered in `api/main.py`
- [ ] Swagger UI at `http://localhost:8000/docs` shows all endpoints

**Verification:**

```
curl http://localhost:8000/health                →
curl http://localhost:8000/api/v1/prompts/       →
curl http://localhost:8000/docs                  →  Opens Swagger UI? YES / NO

POST /api/v1/authorize test result →
```

**Phase 9 Status:** 🔲 Not Started

---

## Phase 10 — Flutter Frontend

**Goal:** Flutter app with 3 screens running and talking to the backend.

- [x] `flutter create frontend` run (or existing folder initialized)
- [x] `pubspec.yaml` updated with http, provider, go_router dependencies
- [x] `flutter pub get` run successfully
- [ ] `lib/services/api_service.dart` created
  - [ ] `submitAuthorization()` calls `POST /api/v1/authorize`
  - [ ] `getPrompt()` calls `GET /api/v1/prompts/{agent}`
  - [ ] `updatePrompt()` calls `PUT /api/v1/prompts/{agent}`
- [x] `lib/screens/patient_intake_screen.dart` (now `s05_treatment_request`)
      created
  - [x] Patient text input field
  - [x] Treatment input field
  - [ ] Submit button with loading state
  - [x] Navigates to status screen on success
- [x] `lib/screens/authorization_status_screen.dart` (now `s03_dashboard`)
      created
  - [x] Status banner with color-coded status
  - [x] Agent activity trail list
  - [ ] Justification letter preview
- [x] `lib/screens/prompt_editor_screen.dart` (now `s13_prompt_editor`) created
  - [x] Agent dropdown selector
  - [x] System prompt editable text field
  - [x] User template editable text field
  - [x] Save button
- [x] `lib/main.dart` created with bottom navigation
- [x] `flutter run` launches without errors

**Verification:**

```
flutter run -d chrome   →  App loads? YES / NO
Submit form test        →  Status screen shows? YES / NO
Prompt editor test      →  Loads & saves prompt? YES / NO
CORS error?             →  YES (fix backend) / NO
```

**Phase 10 Status:** 🔲 Not Started

---

## Phase 11 — Testing

**Goal:** 2+ types of tests passing. Postman collection ready for reviewers.

### pytest Unit Tests

- [ ] `tests/test_intake_agent.py` created (2 tests)
- [ ] `tests/test_appeal_agent.py` created (2 tests)
- [ ] `tests/test_api.py` created (health + prompts endpoint tests)
- [ ] All tests pass: `pytest tests/ -v`

**Test run output:**

```
pytest result →
Tests passed  →
Tests failed  →
```

### Postman Collection

- [ ] `tests/postman_collection.json` created
- [ ] Health Check request — returns 200
- [ ] List Prompts request — returns agents array
- [ ] Get Intake Prompt — returns YAML content
- [ ] Submit Authorization — returns auth result

**Postman results:**

```
Health Check         →  200 YES / NO
List Prompts         →  200 YES / NO
Get Intake Prompt    →  200 YES / NO
Submit Authorization →  200 YES / NO
```

**Phase 11 Status:** 🔲 Not Started

---

## Phase 12 — Docker

**Goal:** Entire backend + DB runs in Docker containers with one command.

- [ ] `backend/Dockerfile` created
- [ ] `docker-compose.yml` created in project root
- [ ] `.env` file in project root with `ANTHROPIC_API_KEY` and `JWT_SECRET`
- [ ] `docker-compose up --build` runs without errors
- [ ] Backend container starts
- [ ] PostgreSQL container starts
- [ ] Backend connects to DB successfully (no connection errors in logs)

**Verification:**

```
docker-compose up --build result →
curl http://localhost:8000/health →
DB connection in logs?            →  YES / NO
```

**Phase 12 Status:** 🔲 Not Started

---

## Phase 13 — Deployment

**Goal:** Live deployment URL accessible from the internet.

### Backend — Render.com

- [ ] GitHub repo is public
- [ ] Render.com account created
- [ ] New Web Service created and connected to GitHub repo
- [ ] Build settings configured (root dir: `backend`, start: uvicorn command)
- [ ] PostgreSQL database added on Render
- [ ] Environment variables set in Render dashboard
- [ ] First deploy completes successfully
- [ ] `/health` endpoint accessible at live URL

**Backend live URL:** `https://___________________________`

**Verification:**

```
curl https://your-app.onrender.com/health  →
```

### Frontend — Flutter Web

- [ ] `flutter build web` runs successfully
- [ ] `build/web/` folder generated
- [ ] Frontend deployed (Vercel / Netlify / Render static)
- [ ] `baseUrl` in `api_service.dart` updated to production backend URL
- [ ] Frontend loads and connects to live backend

**Frontend live URL:** `https://___________________________`

**Phase 13 Status:** 🔲 Not Started

---

## Phase 14 — Submission Polish

**Goal:** Complete submission package ready.

- [ ] `README.md` written and complete
  - [ ] Project description
  - [ ] Live deployment URL
  - [ ] Architecture diagram link
  - [ ] Setup instructions
  - [ ] Tech stack table
  - [ ] How to run tests
  - [ ] Team member GitHub accounts
- [ ] `architecture.png` created and added to repo root
- [ ] Demo video recorded (3–5 minutes)
  - [ ] Shows patient intake form
  - [ ] Shows agent progress in real time
  - [ ] Shows justification letter
  - [ ] Shows appeal loop
  - [ ] Shows prompt editor
  - [ ] Shows live deployment URL
- [ ] Demo video link added to README
- [ ] All team members have commits from their own GitHub accounts
- [ ] GitHub repo is public and link is ready
- [ ] Hackathon submission form filled and submitted

**Phase 14 Status:** 🔲 Not Started

---

## Agent Build Status

| # | Agent                | File Created | Implemented | Orchestrator Wired | Manually Tested |
| - | -------------------- | ------------ | ----------- | ------------------ | --------------- |
| 1 | Intake & History     | 🔲           | 🔲          | 🔲                 | 🔲              |
| 2 | Medical Analysis     | 🔲           | 🔲          | 🔲                 | 🔲              |
| 3 | Policy Intelligence  | 🔲           | 🔲          | 🔲                 | 🔲              |
| 4 | Justification Writer | 🔲           | 🔲          | 🔲                 | 🔲              |
| 5 | Submission & Monitor | 🔲           | 🔲          | 🔲                 | 🔲              |
| 6 | Denial & Appeal      | 🔲           | 🔲          | 🔲                 | 🔲              |
| 7 | Claims Validation    | 🔲           | 🔲          | 🔲                 | 🔲              |
| — | Master Orchestrator  | 🔲           | 🔲          | N/A                | 🔲              |

---

## API Endpoints Status

| Method | Endpoint                  | Built | Returns 200 |
| ------ | ------------------------- | ----- | ----------- |
| GET    | `/health`                 | 🔲    | 🔲          |
| POST   | `/api/v1/authorize`       | 🔲    | 🔲          |
| GET    | `/api/v1/authorize/{id}`  | 🔲    | 🔲          |
| GET    | `/api/v1/prompts/`        | 🔲    | 🔲          |
| GET    | `/api/v1/prompts/{agent}` | 🔲    | 🔲          |
| PUT    | `/api/v1/prompts/{agent}` | 🔲    | 🔲          |

---

## Flutter Screens Status

| Screen               | File Created | Renders | API Connected |
| -------------------- | ------------ | ------- | ------------- |
| Patient Intake       | ✅           | ✅      | 🔲            |
| Authorization Status | ✅           | ✅      | 🔲            |
| Prompt Editor        | ✅           | ✅      | 🔲            |

---

## Blockers & Notes Log

> Add a new entry whenever you hit something that slows you down.

```
[Date/Time] Phase X — BLOCKER: describe the issue
[Date/Time] Phase X — RESOLVED: how you fixed it
[Date/Time] Phase X — NOTE: anything worth remembering
```

---

## Hackathon Evaluation Checklist

> Use this to self-grade before submitting.

| Criterion             | Requirement                                         | Status |
| --------------------- | --------------------------------------------------- | ------ |
| Agentic Architecture  | 7 agents + orchestrator with clear goals and tools  | 🔲     |
| Autonomous Reasoning  | Appeal agent loops without human input              | 🔲     |
| Technical Depth       | LangGraph + RAG + LLM + async API                   | 🔲     |
| Code Quality          | Modular structure, one agent per file, typed Python | 🔲     |
| Prompt Inspectability | All prompts in YAML, editable from Flutter UI       | 🔲     |
| Testing               | pytest unit tests + Postman collection (2+ types)   | 🔲     |
| Security              | API keys in .env, JWT auth, Pydantic validation     | 🔲     |
| User Experience       | Flutter intake form + status dashboard              | 🔲     |
| Innovation            | Autonomous multi-level appeal loop                  | 🔲     |
| Deployment            | Live Render.com URL + Docker (bonus)                | 🔲     |
