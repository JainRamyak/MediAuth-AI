# MediAuth AI — Complete Build Plan
### Veersa Hackathon 2027 | ABES Batch of 2027
> **Read this file first whenever you resume work.** Every phase has: what to do, how to do it, and how to verify it before moving on.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Tech Stack & Why](#2-tech-stack--why)
3. [Folder Structure](#3-folder-structure)
4. [Phase 0 — Environment Setup](#phase-0--environment-setup)
5. [Phase 1 — Backend Foundation](#phase-1--backend-foundation)
6. [Phase 2 — Database Layer](#phase-2--database-layer)
7. [Phase 3 — Prompt Config System](#phase-3--prompt-config-system)
8. [Phase 4 — ChromaDB Knowledge Base](#phase-4--chromadb-knowledge-base)
9. [Phase 5 — Agents 1–3 (Intake, Medical, Policy)](#phase-5--agents-13)
10. [Phase 6 — LangGraph Orchestrator Skeleton](#phase-6--langgraph-orchestrator-skeleton)
11. [Phase 7 — Agents 4–7 (Justify, Submit, Appeal, Claims)](#phase-7--agents-47)
12. [Phase 8 — Orchestrator Complete Wiring](#phase-8--orchestrator-complete-wiring)
13. [Phase 9 — FastAPI Routes](#phase-9--fastapi-routes)
14. [Phase 10 — Flutter Frontend](#phase-10--flutter-frontend)
15. [Phase 11 — Testing](#phase-11--testing)
16. [Phase 12 — Docker](#phase-12--docker)
17. [Phase 13 — Deployment](#phase-13--deployment)
18. [Phase 14 — Submission Polish](#phase-14--submission-polish)
19. [Troubleshooting Reference](#troubleshooting-reference)

---

## 1. Project Overview

**MediAuth AI** is a multi-agent agentic AI system that autonomously manages the full insurance authorization lifecycle:

```
Patient Input
     ↓
Agent 1: Intake & History       → Structured JSON patient profile
     ↓
Agent 2: Medical Analysis       → ICD-10 / CPT codes + clinical summary
     ↓
Agent 3: Policy Intelligence    → Documentation checklist (RAG over policy PDFs)
     ↓
Agent 4: Justification Writer   → Auth request letter + evidence package
     ↓
Agent 5: Submission & Monitor   → Submit + poll insurer for decision
     ↓
  APPROVED? ──────────────────────→ Notify user → END
     ↓ DENIED
Agent 6: Denial & Appeal        → Parse denial → counter-evidence → appeal letter → re-submit
     ↑_______________________________↑  (loop up to 3 levels)
     ↓ Max coverage secured
     END

Parallel track (always running):
Agent 7: Claims Validation      → Scan billing codes before submission → risk score
```

**Orchestrator** coordinates all agents, manages state, handles exceptions, and triggers human escalation only when necessary.

---

## 2. Tech Stack & Why

| Layer | Technology | Why |
|---|---|---|
| LLM / AI Core | Claude Sonnet 4 (Anthropic API) | Best clinical writing, long-context reasoning |
| Agent Framework | LangGraph (Python) | State-machine graph, supports cycles (needed for appeal loop), persistent state |
| Backend API | FastAPI (Python) | Fast, async, auto-generates OpenAPI docs |
| Frontend | Flutter (Dart) | Cross-platform, single codebase, rich UI components |
| Database | PostgreSQL + SQLAlchemy | Structured relational data, ORM speeds dev |
| Vector Store | ChromaDB (local) | Local RAG, no infra needed, Python-native |
| Prompt Store | YAML config files | Inspectable + editable by reviewers without touching code |
| Auth | JWT (python-jose) + env vars | No hardcoded secrets |
| Testing | pytest + Postman | 2+ test types required by hackathon |
| Deployment | Render.com (free tier) | One-click GitHub deploy |
| Containerization | Docker + docker-compose | Bonus points, simplifies deployment |

---

## 3. Folder Structure

```
mediauth-ai/
├── backend/
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── orchestrator.py          ← LangGraph state machine
│   │   ├── intake_agent.py
│   │   ├── medical_analysis_agent.py
│   │   ├── policy_agent.py
│   │   ├── justification_agent.py
│   │   ├── submission_agent.py
│   │   ├── appeal_agent.py
│   │   └── claims_agent.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── main.py                  ← FastAPI app entry point
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── auth.py
│   │       ├── patients.py
│   │       ├── authorization.py
│   │       └── prompts.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── database.py              ← SQLAlchemy engine + session
│   │   ├── patient.py
│   │   ├── auth_request.py
│   │   ├── audit_log.py
│   │   └── claim.py
│   ├── prompts/
│   │   ├── intake_prompt.yaml
│   │   ├── medical_analysis_prompt.yaml
│   │   ├── policy_prompt.yaml
│   │   ├── justification_prompt.yaml
│   │   ├── submission_prompt.yaml
│   │   ├── appeal_prompt.yaml
│   │   └── claims_prompt.yaml
│   ├── knowledge_base/
│   │   ├── __init__.py
│   │   ├── loader.py                ← Embeds policy PDFs into ChromaDB
│   │   └── sample_policies/        ← Sample insurer policy PDF files
│   ├── tests/
│   │   ├── test_intake_agent.py
│   │   ├── test_medical_agent.py
│   │   ├── test_appeal_agent.py
│   │   └── test_api.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── prompt_loader.py         ← Reads YAML prompts
│   │   └── claude_client.py        ← Anthropic API wrapper
│   ├── requirements.txt
│   ├── .env.example
│   └── Dockerfile
├── frontend/                        ← Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── patient_intake_screen.dart
│   │   │   ├── authorization_status_screen.dart
│   │   │   └── prompt_editor_screen.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   └── models/
│   │       └── patient_model.dart
│   └── pubspec.yaml
├── docker-compose.yml
├── README.md
└── architecture.png
```

---

## Phase 0 — Environment Setup

### What to do
Install all tools you need before writing a single line of project code.

### How to do it

**Install Python 3.11+**
```bash
python --version   # must be 3.11 or higher
# If not: https://www.python.org/downloads/
```

**Install Flutter**
```bash
# Mac (with Homebrew)
brew install --cask flutter

# Windows: download from https://docs.flutter.dev/get-started/install/windows
# Then add Flutter/bin to your PATH

flutter --version    # verify
flutter doctor       # check for missing dependencies
```

**Install PostgreSQL**
```bash
# Mac
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/WSL
sudo apt update && sudo apt install postgresql postgresql-contrib
sudo service postgresql start

# Windows: https://www.postgresql.org/download/windows/
```

**Create the database**
```bash
psql postgres
CREATE DATABASE mediauth;
CREATE USER mediauth_user WITH PASSWORD 'mediauth_pass';
GRANT ALL PRIVILEGES ON DATABASE mediauth TO mediauth_user;
\q
```

**Install Docker Desktop**
Download from https://www.docker.com/products/docker-desktop/

**Install Node.js (for any tooling)**
```bash
node --version   # should be 18+
# If not: https://nodejs.org/
```

### How to verify Phase 0 is complete
```bash
python --version          # 3.11+
flutter --version         # 3.x
psql -U mediauth_user -d mediauth -c "SELECT 1;"   # returns 1
docker --version          # 24+
```
All four commands must succeed before moving to Phase 1.

---

## Phase 1 — Backend Foundation

### What to do
Create the backend folder structure, virtual environment, install dependencies, and get a working FastAPI server running.

### How to do it

**Step 1 — Create folder structure**
```bash
cd mediauth-ai    # your project root

mkdir -p backend/{agents,api/routes,models,prompts,knowledge_base/sample_policies,tests,utils}
touch backend/agents/__init__.py
touch backend/api/__init__.py
touch backend/api/routes/__init__.py
touch backend/models/__init__.py
touch backend/utils/__init__.py
touch backend/knowledge_base/__init__.py
```

**Step 2 — Create virtual environment**
```bash
cd backend
python -m venv venv

# Activate:
source venv/bin/activate          # Mac/Linux
# venv\Scripts\activate           # Windows PowerShell
# venv\Scripts\activate.bat       # Windows CMD

# You should see (venv) prefix in your terminal
```

**Step 3 — Install dependencies**
```bash
pip install \
  fastapi==0.111.0 \
  uvicorn[standard]==0.29.0 \
  sqlalchemy==2.0.30 \
  psycopg2-binary==2.9.9 \
  python-dotenv==1.0.1 \
  pydantic==2.7.1 \
  langchain==0.2.0 \
  langgraph==0.0.55 \
  langchain-anthropic==0.1.15 \
  anthropic==0.28.0 \
  chromadb==0.5.0 \
  python-jose[cryptography]==3.3.0 \
  passlib[bcrypt]==1.7.4 \
  pyyaml==6.0.1 \
  pytest==8.2.0 \
  httpx==0.27.0 \
  pypdf==4.2.0

pip freeze > requirements.txt
```

**Step 4 — Create .env files**

Create `backend/.env.example`:
```
ANTHROPIC_API_KEY=your_anthropic_api_key_here
DATABASE_URL=postgresql://mediauth_user:mediauth_pass@localhost:5432/mediauth
JWT_SECRET=your_super_secret_jwt_key_here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
ENVIRONMENT=development
```

Create `backend/.env` (copy from example and fill in your real key):
```bash
cp .env.example .env
# Open .env and set your actual ANTHROPIC_API_KEY
```

**Step 5 — Create main FastAPI entry point**

Create `backend/api/main.py`:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(
    title="MediAuth AI",
    description="Autonomous Insurance Authorization & Appeal Agent",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "MediAuth AI",
        "version": "0.1.0",
        "environment": os.getenv("ENVIRONMENT", "development")
    }
```

**Step 6 — Run the server**
```bash
# From backend/ directory with venv activated
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

### How to verify Phase 1 is complete
```bash
curl http://localhost:8000/health
# Expected: {"status":"ok","service":"MediAuth AI","version":"0.1.0","environment":"development"}

curl http://localhost:8000/docs
# Should open FastAPI Swagger UI in browser
```
Both must work before moving to Phase 2.

---

## Phase 2 — Database Layer

### What to do
Define all SQLAlchemy models and create tables in PostgreSQL.

### How to do it

**Step 1 — Create database connection**

Create `backend/models/database.py`:
```python
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

**Step 2 — Create Patient model**

Create `backend/models/patient.py`:
```python
from sqlalchemy import Column, String, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class Patient(Base):
    __tablename__ = "patients"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    date_of_birth = Column(String(20))
    insurance_policy_number = Column(String(100))
    insurer_name = Column(String(255))
    diagnoses = Column(JSON)           # list of diagnosis strings
    medications = Column(JSON)         # list of medication strings
    allergies = Column(JSON)           # list of allergy strings
    medical_history = Column(Text)     # free text or parsed notes
    structured_profile = Column(JSON)  # full JSON output from Agent 1
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

**Step 3 — Create AuthRequest model**

Create `backend/models/auth_request.py`:
```python
from sqlalchemy import Column, String, DateTime, Text, Integer, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class AuthRequest(Base):
    __tablename__ = "auth_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    status = Column(String(50), default="pending")
    # pending | submitted | approved | denied | appealing | escalated | closed
    icd10_codes = Column(JSON)
    cpt_codes = Column(JSON)
    clinical_summary = Column(Text)
    justification_letter = Column(Text)
    denial_reason = Column(Text)
    appeal_level = Column(Integer, default=0)   # 0=none, 1=initial, 2=peer, 3=external
    insurer_response = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

**Step 4 — Create AuditLog model**

Create `backend/models/audit_log.py`:
```python
from sqlalchemy import Column, String, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth_request_id = Column(UUID(as_uuid=True), nullable=True)
    agent_name = Column(String(100))
    action = Column(String(255))
    input_data = Column(JSON)
    output_data = Column(JSON)
    status = Column(String(50))   # success | error | escalated
    error_message = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
```

**Step 5 — Create Claim model**

Create `backend/models/claim.py`:
```python
from sqlalchemy import Column, String, DateTime, Text, JSON, Float
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class Claim(Base):
    __tablename__ = "claims"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth_request_id = Column(UUID(as_uuid=True), nullable=False)
    billing_codes = Column(JSON)
    risk_score = Column(String(10))    # LOW | MEDIUM | HIGH
    risk_flags = Column(JSON)          # list of flagged issues
    status = Column(String(50), default="pending_review")
    # pending_review | submitted | denied | resubmitted
    corrected_codes = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
```

**Step 6 — Create all tables**

Create `backend/models/init_db.py`:
```python
from models.database import engine, Base
from models.patient import Patient
from models.auth_request import AuthRequest
from models.audit_log import AuditLog
from models.claim import Claim

def create_tables():
    Base.metadata.create_all(bind=engine)
    print("All tables created successfully.")

if __name__ == "__main__":
    create_tables()
```

Run it:
```bash
# From backend/ with venv active
python models/init_db.py
```

### How to verify Phase 2 is complete
```bash
psql -U mediauth_user -d mediauth -c "\dt"
```
You should see 4 tables: `patients`, `auth_requests`, `audit_logs`, `claims`.

```bash
psql -U mediauth_user -d mediauth -c "\d patients"
```
Should show all columns with correct types.

---

## Phase 3 — Prompt Config System

### What to do
Store all agent prompts as YAML files. No prompt goes inside Python code. Create a loader utility.

### How to do it

**Step 1 — Create each YAML prompt file**

Create `backend/prompts/intake_prompt.yaml`:
```yaml
system: |
  You are Agent 1 of MediAuth AI — the Intake & History Agent.
  Your job is to collect and structure patient medical information.
  
  Extract the following from the user's input and return ONLY a valid JSON object:
  {
    "name": "string",
    "date_of_birth": "YYYY-MM-DD or unknown",
    "insurance_policy_number": "string or unknown",
    "insurer_name": "string or unknown",
    "diagnoses": ["list of diagnosis strings"],
    "medications": ["list of current medications"],
    "allergies": ["list of known allergies"],
    "past_procedures": ["list of past medical procedures"],
    "medical_history": "free text summary",
    "missing_fields": ["list of fields not provided by the user"]
  }
  
  If any field is missing, add it to missing_fields. Do not guess.
  Return ONLY the JSON object — no explanation, no markdown, no preamble.

user_template: |
  Patient information provided:
  {patient_input}
  
  Extract and structure this into the required JSON format.
```

Create `backend/prompts/medical_analysis_prompt.yaml`:
```yaml
system: |
  You are Agent 2 of MediAuth AI — the Medical Analysis Agent.
  You are a clinical intelligence layer that maps patient health data to standardized medical codes.
  
  Given a structured patient profile, return ONLY a valid JSON object:
  {
    "icd10_codes": [{"code": "X00.0", "description": "diagnosis name"}],
    "cpt_codes": [{"code": "00000", "description": "procedure name"}],
    "clinical_necessity_summary": "2-3 paragraph clinical justification for the treatment",
    "treatment_follows_guidelines": true or false,
    "step_therapy_required": true or false,
    "step_therapy_notes": "explanation if required"
  }
  
  Return ONLY the JSON object.

user_template: |
  Patient Profile:
  {patient_profile}
  
  Requested Treatment/Procedure:
  {requested_treatment}
  
  Analyze and return the structured medical codes and clinical summary.
```

Create `backend/prompts/policy_prompt.yaml`:
```yaml
system: |
  You are Agent 3 of MediAuth AI — the Policy Intelligence Agent.
  You interpret insurance policy rules retrieved from the knowledge base.
  
  Given policy context from the database and the patient's case, return ONLY a valid JSON object:
  {
    "pre_auth_required": true or false,
    "qualifies_for_auto_approval": true or false,
    "required_documentation": ["list of required documents"],
    "available_documentation": ["list of documents the hospital currently has"],
    "missing_documentation": ["list of gaps"],
    "coverage_notes": "explanation of coverage rules relevant to this case"
  }
  
  Return ONLY the JSON object.

user_template: |
  Insurer: {insurer_name}
  Policy Context (from knowledge base):
  {policy_context}
  
  Patient Case:
  {patient_summary}
  
  Analyze coverage requirements and gaps.
```

Create `backend/prompts/justification_prompt.yaml`:
```yaml
system: |
  You are Agent 4 of MediAuth AI — the Justification Writer Agent.
  You write persuasive, medically accurate, insurer-compliant prior authorization letters.
  
  Write a professional clinical justification letter that:
  1. Opens with patient demographics and diagnosis
  2. Explains clinical necessity with supporting evidence
  3. References accepted clinical guidelines
  4. Addresses all insurer documentation requirements
  5. Closes with a clear request for authorization
  
  The letter must be formal, clinical, and specific. Use real patient data only — no generic templates.
  Return the complete letter as plain text.

user_template: |
  Patient Profile: {patient_profile}
  ICD-10 Codes: {icd10_codes}
  CPT Codes: {cpt_codes}
  Clinical Summary: {clinical_summary}
  Insurer: {insurer_name}
  Required Documentation Met: {documentation_status}
  
  Write the prior authorization justification letter.
```

Create `backend/prompts/appeal_prompt.yaml`:
```yaml
system: |
  You are Agent 6 of MediAuth AI — the Denial & Appeal Agent.
  You write formal medical insurance appeal letters.
  
  Given a denial reason and counter-evidence from the patient record, write an appeal letter that:
  1. Acknowledges the denial and quotes the specific denial reason
  2. Provides clinical counter-evidence directly refuting the denial
  3. References applicable state insurance law or federal mandates if relevant
  4. Requests reconsideration with a specific deadline
  5. Escalates tone appropriately based on appeal level (1=polite, 2=firm, 3=urgent/legal)
  
  Return the complete appeal letter as plain text.

user_template: |
  Original Denial Reason: {denial_reason}
  Appeal Level: {appeal_level} (1=initial, 2=peer-to-peer, 3=external review)
  Patient Profile: {patient_profile}
  Clinical Counter-Evidence: {counter_evidence}
  Insurer: {insurer_name}
  
  Write the appeal letter.
```

Create `backend/prompts/submission_prompt.yaml`:
```yaml
system: |
  You are Agent 5 of MediAuth AI — the Submission & Monitor Agent.
  Parse insurer portal responses and determine the decision status.
  
  Return ONLY a valid JSON object:
  {
    "decision": "approved | denied | pending | more_info_required",
    "decision_date": "YYYY-MM-DD or null",
    "denial_reason": "string or null",
    "reference_number": "string or null",
    "next_action": "description of what to do next"
  }

user_template: |
  Insurer Response:
  {insurer_response}
  
  Parse this response and return the structured decision.
```

Create `backend/prompts/claims_prompt.yaml`:
```yaml
system: |
  You are Agent 7 of MediAuth AI — the Claims Validation Agent.
  Scan outgoing claims for billing errors before submission.
  
  Return ONLY a valid JSON object:
  {
    "risk_score": "LOW | MEDIUM | HIGH",
    "issues_found": ["list of specific issues"],
    "corrected_codes": [{"original": "X", "corrected": "Y", "reason": "explanation"}],
    "missing_documentation": ["list of missing items"],
    "recommendation": "SUBMIT | HOLD_FOR_REVIEW | AUTO_CORRECT_AND_SUBMIT",
    "notes": "additional validation notes"
  }

user_template: |
  Claim Details:
  Patient ID: {patient_id}
  ICD-10 Codes: {icd10_codes}
  CPT Codes: {cpt_codes}
  Documentation Present: {documentation_list}
  
  Validate this claim and return the risk assessment.
```

**Step 2 — Create prompt loader utility**

Create `backend/utils/prompt_loader.py`:
```python
import yaml
import os

PROMPTS_DIR = os.path.join(os.path.dirname(__file__), "..", "prompts")

def load_prompt(agent_name: str) -> dict:
    """Load a prompt YAML file by agent name."""
    file_path = os.path.join(PROMPTS_DIR, f"{agent_name}_prompt.yaml")
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Prompt file not found: {file_path}")
    with open(file_path, "r") as f:
        return yaml.safe_load(f)

def get_system_prompt(agent_name: str) -> str:
    return load_prompt(agent_name)["system"]

def get_user_prompt(agent_name: str, **kwargs) -> str:
    template = load_prompt(agent_name)["user_template"]
    return template.format(**kwargs)

def update_prompt(agent_name: str, system: str, user_template: str) -> bool:
    """Update a prompt file from the UI editor."""
    file_path = os.path.join(PROMPTS_DIR, f"{agent_name}_prompt.yaml")
    data = {"system": system, "user_template": user_template}
    with open(file_path, "w") as f:
        yaml.dump(data, f, default_flow_style=False)
    return True
```

**Step 3 — Create Claude API wrapper**

Create `backend/utils/claude_client.py`:
```python
import anthropic
import os
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

def call_claude(system_prompt: str, user_message: str, max_tokens: int = 2000) -> str:
    """Call Claude API and return the text response."""
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=max_tokens,
        system=system_prompt,
        messages=[{"role": "user", "content": user_message}]
    )
    return message.content[0].text

def call_claude_for_json(system_prompt: str, user_message: str) -> dict:
    """Call Claude and parse the response as JSON."""
    import json
    response_text = call_claude(system_prompt, user_message, max_tokens=2000)
    # Strip markdown code fences if present
    cleaned = response_text.strip()
    if cleaned.startswith("```"):
        lines = cleaned.split("\n")
        cleaned = "\n".join(lines[1:-1])
    return json.loads(cleaned)
```

### How to verify Phase 3 is complete
```python
# Run from backend/ with venv active
python -c "
from utils.prompt_loader import get_system_prompt
print(get_system_prompt('intake'))
print('Prompt loader works.')
"
```
Should print the intake system prompt. No errors = Phase 3 complete.

---

## Phase 4 — ChromaDB Knowledge Base

### What to do
Set up ChromaDB to store insurance policy documents as vector embeddings. Agent 3 will query this.

### How to do it

**Step 1 — Add sample policy PDFs**

Put any 2–3 sample insurance policy PDF files in `backend/knowledge_base/sample_policies/`. For a hackathon demo, you can create simple text files and rename them `.pdf`, or download sample documents.

**Step 2 — Create the knowledge base loader**

Create `backend/knowledge_base/loader.py`:
```python
import chromadb
from chromadb.utils import embedding_functions
import os
import glob
from pypdf import PdfReader

# Initialize ChromaDB persistent client
CHROMA_DIR = os.path.join(os.path.dirname(__file__), "chroma_store")
client = chromadb.PersistentClient(path=CHROMA_DIR)

# Use default embedding function (sentence transformers)
embedding_fn = embedding_functions.DefaultEmbeddingFunction()

collection = client.get_or_create_collection(
    name="insurance_policies",
    embedding_function=embedding_fn
)

def load_pdf_text(pdf_path: str) -> str:
    """Extract text from a PDF file."""
    reader = PdfReader(pdf_path)
    text = ""
    for page in reader.pages:
        text += page.extract_text() or ""
    return text

def chunk_text(text: str, chunk_size: int = 500) -> list[str]:
    """Split text into overlapping chunks."""
    words = text.split()
    chunks = []
    for i in range(0, len(words), chunk_size - 50):
        chunk = " ".join(words[i:i + chunk_size])
        if chunk:
            chunks.append(chunk)
    return chunks

def ingest_policies():
    """Load all PDFs from sample_policies/ into ChromaDB."""
    pdf_dir = os.path.join(os.path.dirname(__file__), "sample_policies")
    pdf_files = glob.glob(os.path.join(pdf_dir, "*.pdf"))

    if not pdf_files:
        print("No PDFs found. Adding sample policy text for demo.")
        sample_text = """
        BlueCross Policy Coverage Rules:
        Prior authorization is required for all specialty medications exceeding $500/month.
        Mental health services require a referral from primary care physician.
        Step therapy is required: patient must try generic alternatives before brand-name drugs.
        MRI and CT scans require pre-authorization. X-rays do not require pre-authorization.
        Oncology treatments require specialist referral and diagnosis documentation.
        """
        collection.add(
            documents=[sample_text],
            ids=["sample_policy_1"],
            metadatas=[{"insurer": "BlueCross", "type": "general_coverage"}]
        )
        print("Sample policy loaded.")
        return

    for pdf_path in pdf_files:
        text = load_pdf_text(pdf_path)
        chunks = chunk_text(text)
        insurer_name = os.path.basename(pdf_path).replace(".pdf", "")
        
        ids = [f"{insurer_name}_chunk_{i}" for i in range(len(chunks))]
        metadatas = [{"insurer": insurer_name, "chunk": i} for i in range(len(chunks))]
        
        collection.add(documents=chunks, ids=ids, metadatas=metadatas)
        print(f"Loaded {len(chunks)} chunks from {insurer_name}")

def query_policies(query: str, insurer: str = None, n_results: int = 5) -> list[str]:
    """Query the knowledge base for relevant policy sections."""
    where = {"insurer": insurer} if insurer else None
    results = collection.query(
        query_texts=[query],
        n_results=n_results,
        where=where
    )
    return results["documents"][0] if results["documents"] else []

if __name__ == "__main__":
    ingest_policies()
    print("Knowledge base ready.")
    # Test query
    results = query_policies("prior authorization requirements for MRI")
    print(f"Test query returned {len(results)} results.")
```

**Step 3 — Run the loader**
```bash
cd backend
python knowledge_base/loader.py
```

### How to verify Phase 4 is complete
```bash
python -c "
from knowledge_base.loader import query_policies
results = query_policies('prior authorization requirements')
print(f'Got {len(results)} results from ChromaDB')
print(results[0][:200])
"
```
Should return at least 1 result with policy text.

---

## Phase 5 — Agents 1–3

### What to do
Build the first three agents: Intake, Medical Analysis, and Policy Intelligence.

### How to do it

**Step 1 — Agent 1: Intake & History Agent**

Create `backend/agents/intake_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json
import json

def run_intake_agent(patient_input: str) -> dict:
    """
    Takes raw patient text input.
    Returns structured patient profile as dict.
    """
    system = get_system_prompt("intake")
    user = get_user_prompt("intake", patient_input=patient_input)
    
    try:
        profile = call_claude_for_json(system, user)
        profile["agent"] = "intake"
        profile["status"] = "success"
        return profile
    except Exception as e:
        return {
            "agent": "intake",
            "status": "error",
            "error": str(e),
            "raw_input": patient_input
        }
```

**Step 2 — Agent 2: Medical Analysis Agent**

Create `backend/agents/medical_analysis_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json
import json

def run_medical_analysis_agent(patient_profile: dict, requested_treatment: str) -> dict:
    """
    Takes patient profile dict and treatment description.
    Returns ICD-10/CPT codes and clinical necessity summary.
    """
    system = get_system_prompt("medical_analysis")
    user = get_user_prompt(
        "medical_analysis",
        patient_profile=json.dumps(patient_profile, indent=2),
        requested_treatment=requested_treatment
    )
    
    try:
        result = call_claude_for_json(system, user)
        result["agent"] = "medical_analysis"
        result["status"] = "success"
        return result
    except Exception as e:
        return {
            "agent": "medical_analysis",
            "status": "error",
            "error": str(e)
        }
```

**Step 3 — Agent 3: Policy Intelligence Agent**

Create `backend/agents/policy_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json
from knowledge_base.loader import query_policies
import json

def run_policy_agent(patient_profile: dict, insurer_name: str) -> dict:
    """
    Takes patient profile and insurer name.
    Queries ChromaDB for relevant policy rules.
    Returns documentation requirements and gaps.
    """
    # RAG: fetch relevant policy sections
    query = f"prior authorization requirements {patient_profile.get('diagnoses', [''])[0]}"
    policy_chunks = query_policies(query, insurer=insurer_name)
    policy_context = "\n\n".join(policy_chunks) if policy_chunks else "No specific policy found."
    
    patient_summary = f"""
    Diagnoses: {patient_profile.get('diagnoses', [])}
    Medications: {patient_profile.get('medications', [])}
    Past Procedures: {patient_profile.get('past_procedures', [])}
    """
    
    system = get_system_prompt("policy")
    user = get_user_prompt(
        "policy",
        insurer_name=insurer_name,
        policy_context=policy_context,
        patient_summary=patient_summary
    )
    
    try:
        result = call_claude_for_json(system, user)
        result["agent"] = "policy"
        result["status"] = "success"
        return result
    except Exception as e:
        return {
            "agent": "policy",
            "status": "error",
            "error": str(e)
        }
```

### How to verify Phase 5 is complete
```python
# Run from backend/ with venv active
python -c "
from agents.intake_agent import run_intake_agent

test_input = '''
Patient: John Doe, DOB 1975-03-15
Insurance: BlueCross, policy #BCX-12345
Diagnoses: Type 2 Diabetes, Hypertension
Medications: Metformin 1000mg, Lisinopril 10mg
Allergies: Penicillin
Past procedures: Appendectomy 2010
'''

result = run_intake_agent(test_input)
print('Agent 1 result:', result)
print('Status:', result.get('status'))
"
```
Should print a structured JSON profile with `"status": "success"`.

---

## Phase 6 — LangGraph Orchestrator Skeleton

### What to do
Wire Agents 1–3 into a LangGraph state machine. This forms the backbone; you will add Agents 4–7 in Phase 7.

### How to do it

Create `backend/agents/orchestrator.py`:
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Optional
from agents.intake_agent import run_intake_agent
from agents.medical_analysis_agent import run_medical_analysis_agent
from agents.policy_agent import run_policy_agent
import json

# ─────────────────────────────────────────
# State definition — shared across all agents
# ─────────────────────────────────────────
class AuthState(TypedDict):
    # Input
    raw_patient_input: str
    requested_treatment: str
    
    # Agent outputs (built up step by step)
    patient_profile: Optional[dict]
    medical_analysis: Optional[dict]
    policy_check: Optional[dict]
    justification_letter: Optional[str]
    submission_result: Optional[dict]
    appeal_result: Optional[dict]
    claims_validation: Optional[dict]
    
    # Control flow
    current_agent: str
    workflow_status: str  # running | approved | denied | appealing | escalated | error
    appeal_level: int     # 0, 1, 2, 3
    error_message: Optional[str]
    audit_trail: list     # list of {agent, action, timestamp}

# ─────────────────────────────────────────
# Node functions
# ─────────────────────────────────────────
def intake_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 1: Intake")
    result = run_intake_agent(state["raw_patient_input"])
    state["patient_profile"] = result
    state["current_agent"] = "intake"
    state["audit_trail"].append({"agent": "intake", "status": result.get("status")})
    return state

def medical_analysis_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 2: Medical Analysis")
    result = run_medical_analysis_agent(
        state["patient_profile"],
        state["requested_treatment"]
    )
    state["medical_analysis"] = result
    state["current_agent"] = "medical_analysis"
    state["audit_trail"].append({"agent": "medical_analysis", "status": result.get("status")})
    return state

def policy_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 3: Policy Intelligence")
    insurer = state["patient_profile"].get("insurer_name", "Unknown")
    result = run_policy_agent(state["patient_profile"], insurer)
    state["policy_check"] = result
    state["current_agent"] = "policy"
    state["audit_trail"].append({"agent": "policy", "status": result.get("status")})
    return state

# Placeholder nodes — to be replaced in Phase 7
def justification_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 4: Justification Writer [PLACEHOLDER]")
    state["justification_letter"] = "PLACEHOLDER LETTER"
    state["current_agent"] = "justification"
    return state

def submission_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 5: Submission [PLACEHOLDER]")
    # Mock: simulate denial for testing the appeal loop
    state["submission_result"] = {"decision": "denied", "denial_reason": "Step therapy not completed"}
    state["workflow_status"] = "denied"
    state["current_agent"] = "submission"
    return state

def appeal_node(state: AuthState) -> AuthState:
    print(f"[Orchestrator] Running Agent 6: Appeal (Level {state['appeal_level'] + 1})")
    state["appeal_level"] += 1
    state["workflow_status"] = "appealing"
    state["current_agent"] = "appeal"
    return state

def claims_validation_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 7: Claims Validation [PLACEHOLDER]")
    state["claims_validation"] = {"risk_score": "LOW"}
    state["current_agent"] = "claims_validation"
    return state

# ─────────────────────────────────────────
# Routing logic (conditional edges)
# ─────────────────────────────────────────
def route_after_submission(state: AuthState) -> str:
    decision = state.get("submission_result", {}).get("decision", "pending")
    if decision == "approved":
        return "approved"
    elif decision == "denied" and state.get("appeal_level", 0) < 3:
        return "appeal"
    else:
        return "escalate"

def route_after_appeal(state: AuthState) -> str:
    if state.get("appeal_level", 0) >= 3:
        return "escalate"
    return "resubmit"

# ─────────────────────────────────────────
# Build the graph
# ─────────────────────────────────────────
def build_graph():
    graph = StateGraph(AuthState)
    
    # Add nodes
    graph.add_node("intake", intake_node)
    graph.add_node("medical_analysis", medical_analysis_node)
    graph.add_node("policy", policy_node)
    graph.add_node("justification", justification_node)
    graph.add_node("submission", submission_node)
    graph.add_node("appeal", appeal_node)
    graph.add_node("claims_validation", claims_validation_node)
    
    # Linear flow
    graph.set_entry_point("intake")
    graph.add_edge("intake", "medical_analysis")
    graph.add_edge("medical_analysis", "policy")
    graph.add_edge("policy", "justification")
    graph.add_edge("justification", "submission")
    
    # Conditional: after submission
    graph.add_conditional_edges(
        "submission",
        route_after_submission,
        {
            "approved": END,
            "appeal": "appeal",
            "escalate": END
        }
    )
    
    # Conditional: after appeal — loop back to submission
    graph.add_conditional_edges(
        "appeal",
        route_after_appeal,
        {
            "resubmit": "submission",
            "escalate": END
        }
    )
    
    return graph.compile()

def run_authorization_workflow(patient_input: str, treatment: str) -> AuthState:
    """Main entry point for the orchestrator."""
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
```

### How to verify Phase 6 is complete
```python
python -c "
from agents.orchestrator import run_authorization_workflow

result = run_authorization_workflow(
    patient_input='Patient: Jane Smith, DOB 1980-01-01, Insurance: BlueCross BCX-999, Diagnoses: Chronic Back Pain, Medications: Ibuprofen 400mg',
    treatment='MRI of lumbar spine'
)
print('Final status:', result['workflow_status'])
print('Appeal level reached:', result['appeal_level'])
print('Agents run:', [a['agent'] for a in result['audit_trail']])
"
```
Should print all agent names in the audit trail and show the appeal loop working.

---

## Phase 7 — Agents 4–7

### What to do
Replace placeholder nodes with real agent implementations.

### How to do it

**Step 1 — Agent 4: Justification Writer**

Create `backend/agents/justification_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude
import json

def run_justification_agent(
    patient_profile: dict,
    medical_analysis: dict,
    policy_check: dict
) -> str:
    """
    Generates the prior authorization justification letter.
    Returns the letter as a string.
    """
    insurer = patient_profile.get("insurer_name", "Unknown Insurer")
    
    missing_docs = policy_check.get("missing_documentation", [])
    available_docs = policy_check.get("available_documentation", [])
    doc_status = f"Available: {available_docs}. Missing: {missing_docs}."
    
    system = get_system_prompt("justification")
    user = get_user_prompt(
        "justification",
        patient_profile=json.dumps(patient_profile, indent=2),
        icd10_codes=json.dumps(medical_analysis.get("icd10_codes", []), indent=2),
        cpt_codes=json.dumps(medical_analysis.get("cpt_codes", []), indent=2),
        clinical_summary=medical_analysis.get("clinical_necessity_summary", ""),
        insurer_name=insurer,
        documentation_status=doc_status
    )
    
    letter = call_claude(system, user, max_tokens=3000)
    return letter
```

**Step 2 — Agent 5: Submission & Monitor**

Create `backend/agents/submission_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json
import time
import random

def submit_authorization(justification_letter: str, patient_profile: dict) -> dict:
    """
    Submits the authorization request.
    In production: calls insurer API or generates PDF.
    For demo: simulates submission and returns mock response.
    """
    print("[Submission Agent] Submitting authorization request...")
    time.sleep(1)  # Simulate network call
    
    # For hackathon demo: simulate insurer responses
    # In production: call real insurer API here
    mock_responses = [
        {"decision": "approved", "reference": "AUTH-2027-001", "denial_reason": None},
        {"decision": "denied", "denial_reason": "Step therapy not completed. Patient must try conservative treatment first.", "reference": "DEN-2027-001"},
    ]
    
    # Use "approved" for clean demo, or randomize for appeal loop demo
    response = mock_responses[0]  # Change to random.choice(mock_responses) for randomized demo
    
    return {
        "agent": "submission",
        "status": "success",
        "decision": response["decision"],
        "denial_reason": response.get("denial_reason"),
        "reference_number": response.get("reference"),
        "submitted_at": time.strftime("%Y-%m-%dT%H:%M:%SZ")
    }
```

**Step 3 — Agent 6: Denial & Appeal**

Create `backend/agents/appeal_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude
import json

def run_appeal_agent(
    denial_reason: str,
    patient_profile: dict,
    medical_analysis: dict,
    appeal_level: int
) -> str:
    """
    Writes an appeal letter based on the denial reason.
    appeal_level: 1 = initial, 2 = peer-to-peer, 3 = external review
    Returns the appeal letter as a string.
    """
    # Build counter-evidence from patient record
    counter_evidence = f"""
    Clinical evidence supporting medical necessity:
    - Diagnoses: {patient_profile.get('diagnoses', [])}
    - Current medications already tried: {patient_profile.get('medications', [])}
    - Clinical necessity summary: {medical_analysis.get('clinical_necessity_summary', '')}
    - ICD-10 codes: {[c['code'] for c in medical_analysis.get('icd10_codes', [])]}
    - Treatment follows guidelines: {medical_analysis.get('treatment_follows_guidelines', True)}
    """
    
    system = get_system_prompt("appeal")
    user = get_user_prompt(
        "appeal",
        denial_reason=denial_reason,
        appeal_level=appeal_level,
        patient_profile=json.dumps(patient_profile, indent=2),
        counter_evidence=counter_evidence,
        insurer_name=patient_profile.get("insurer_name", "Insurance Provider")
    )
    
    appeal_letter = call_claude(system, user, max_tokens=3000)
    return appeal_letter
```

**Step 4 — Agent 7: Claims Validation**

Create `backend/agents/claims_agent.py`:
```python
from utils.prompt_loader import get_system_prompt, get_user_prompt
from utils.claude_client import call_claude_for_json
import json

def run_claims_validation_agent(
    patient_id: str,
    icd10_codes: list,
    cpt_codes: list,
    documentation_list: list
) -> dict:
    """
    Validates the billing claim before submission.
    Returns risk score and any issues found.
    """
    system = get_system_prompt("claims")
    user = get_user_prompt(
        "claims",
        patient_id=patient_id,
        icd10_codes=json.dumps(icd10_codes, indent=2),
        cpt_codes=json.dumps(cpt_codes, indent=2),
        documentation_list=json.dumps(documentation_list, indent=2)
    )
    
    try:
        result = call_claude_for_json(system, user)
        result["agent"] = "claims_validation"
        result["status"] = "success"
        return result
    except Exception as e:
        return {
            "agent": "claims_validation",
            "status": "error",
            "error": str(e),
            "risk_score": "HIGH"
        }
```

**Step 5 — Update orchestrator with real agents**

Update the placeholder node functions in `orchestrator.py`:
```python
# Replace the placeholder imports at the top of orchestrator.py with:
from agents.justification_agent import run_justification_agent
from agents.submission_agent import submit_authorization
from agents.appeal_agent import run_appeal_agent
from agents.claims_agent import run_claims_validation_agent

# Replace justification_node:
def justification_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 4: Justification Writer")
    letter = run_justification_agent(
        state["patient_profile"],
        state["medical_analysis"],
        state["policy_check"]
    )
    state["justification_letter"] = letter
    state["current_agent"] = "justification"
    state["audit_trail"].append({"agent": "justification", "status": "success"})
    return state

# Replace submission_node:
def submission_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 5: Submission")
    result = submit_authorization(
        state["justification_letter"],
        state["patient_profile"]
    )
    state["submission_result"] = result
    state["workflow_status"] = result["decision"]
    state["current_agent"] = "submission"
    state["audit_trail"].append({"agent": "submission", "status": result["decision"]})
    return state

# Replace appeal_node:
def appeal_node(state: AuthState) -> AuthState:
    new_level = state["appeal_level"] + 1
    print(f"[Orchestrator] Running Agent 6: Appeal Level {new_level}")
    denial_reason = state["submission_result"].get("denial_reason", "Not specified")
    letter = run_appeal_agent(
        denial_reason,
        state["patient_profile"],
        state["medical_analysis"],
        new_level
    )
    state["appeal_result"] = {"letter": letter, "level": new_level}
    state["appeal_level"] = new_level
    state["workflow_status"] = "appealing"
    state["current_agent"] = "appeal"
    state["audit_trail"].append({"agent": f"appeal_level_{new_level}", "status": "submitted"})
    return state

# Replace claims_validation_node:
def claims_validation_node(state: AuthState) -> AuthState:
    print("[Orchestrator] Running Agent 7: Claims Validation")
    profile = state["patient_profile"]
    medical = state["medical_analysis"]
    result = run_claims_validation_agent(
        patient_id=str(profile.get("name", "unknown")),
        icd10_codes=medical.get("icd10_codes", []),
        cpt_codes=medical.get("cpt_codes", []),
        documentation_list=state["policy_check"].get("available_documentation", [])
    )
    state["claims_validation"] = result
    state["current_agent"] = "claims_validation"
    state["audit_trail"].append({"agent": "claims_validation", "risk": result.get("risk_score")})
    return state
```

### How to verify Phase 7 is complete
```python
python -c "
from agents.orchestrator import run_authorization_workflow

result = run_authorization_workflow(
    patient_input='Patient: John Doe, DOB 1975-03-15, Insurance: BlueCross BCX-123, Diagnoses: Chronic Lower Back Pain, Herniated Disc L4-L5, Medications: Ibuprofen 800mg daily for 6 months, Allergies: None',
    treatment='MRI of lumbar spine, CPT 72148'
)
print('Status:', result['workflow_status'])
print('Justification letter generated:', len(result.get('justification_letter', '')) > 100)
print('Claims validation risk:', result.get('claims_validation', {}).get('risk_score'))
"
```

---

## Phase 8 — Orchestrator Complete Wiring

### What to do
Add claims validation to the parallel track, persist audit logs to PostgreSQL, and add human escalation.

### How to do it

Add the following to `orchestrator.py` to integrate claims validation as a parallel step and save audit logs:

```python
# Add to the bottom of orchestrator.py

from models.database import SessionLocal
from models.audit_log import AuditLog
from datetime import datetime

def save_audit_log(auth_request_id: str, agent_name: str, action: str,
                   input_data: dict, output_data: dict, status: str):
    """Persist an audit log entry to PostgreSQL."""
    db = SessionLocal()
    try:
        log = AuditLog(
            auth_request_id=auth_request_id,
            agent_name=agent_name,
            action=action,
            input_data=input_data,
            output_data=output_data,
            status=status,
            timestamp=datetime.utcnow()
        )
        db.add(log)
        db.commit()
    except Exception as e:
        print(f"Audit log save failed: {e}")
    finally:
        db.close()

def human_escalation_node(state: AuthState) -> AuthState:
    """Triggered when all appeal levels are exhausted or evidence is insufficient."""
    print("[Orchestrator] ESCALATING TO HUMAN CLINICIAN")
    state["workflow_status"] = "escalated"
    state["audit_trail"].append({
        "agent": "human_escalation",
        "reason": "Maximum appeal levels reached or insufficient evidence",
        "timestamp": datetime.utcnow().isoformat()
    })
    return state
```

Update the graph to add `human_escalation` node and route `"escalate"` to it.

### How to verify Phase 8 is complete
Check the `audit_logs` table after running the workflow:
```bash
psql -U mediauth_user -d mediauth -c "SELECT agent_name, action, status, timestamp FROM audit_logs ORDER BY timestamp DESC LIMIT 10;"
```

---

## Phase 9 — FastAPI Routes

### What to do
Expose all agent functionality through REST API endpoints.

### How to do it

Create `backend/api/routes/authorization.py`:
```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from models.database import get_db
from models.patient import Patient
from models.auth_request import AuthRequest
from agents.orchestrator import run_authorization_workflow
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/api/v1", tags=["authorization"])

class PatientIntakeRequest(BaseModel):
    patient_text: str
    requested_treatment: str

class AuthorizationResponse(BaseModel):
    auth_request_id: str
    workflow_status: str
    appeal_level: int
    justification_letter: str | None
    audit_trail: list

@router.post("/authorize", response_model=AuthorizationResponse)
async def run_authorization(request: PatientIntakeRequest, db: Session = Depends(get_db)):
    """Run the full authorization workflow for a patient."""
    try:
        result = run_authorization_workflow(
            patient_input=request.patient_text,
            treatment=request.requested_treatment
        )
        
        # Save to database
        patient = Patient(
            name=result["patient_profile"].get("name", "Unknown"),
            insurance_policy_number=result["patient_profile"].get("insurance_policy_number"),
            insurer_name=result["patient_profile"].get("insurer_name"),
            diagnoses=result["patient_profile"].get("diagnoses"),
            medications=result["patient_profile"].get("medications"),
            structured_profile=result["patient_profile"]
        )
        db.add(patient)
        db.flush()
        
        auth_req = AuthRequest(
            patient_id=patient.id,
            status=result["workflow_status"],
            icd10_codes=result.get("medical_analysis", {}).get("icd10_codes"),
            cpt_codes=result.get("medical_analysis", {}).get("cpt_codes"),
            justification_letter=result.get("justification_letter"),
            appeal_level=result.get("appeal_level", 0)
        )
        db.add(auth_req)
        db.commit()
        
        return AuthorizationResponse(
            auth_request_id=str(auth_req.id),
            workflow_status=result["workflow_status"],
            appeal_level=result["appeal_level"],
            justification_letter=result.get("justification_letter"),
            audit_trail=result["audit_trail"]
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/authorize/{auth_request_id}")
async def get_authorization_status(auth_request_id: str, db: Session = Depends(get_db)):
    """Get the status of an authorization request."""
    auth_req = db.query(AuthRequest).filter(
        AuthRequest.id == auth_request_id
    ).first()
    if not auth_req:
        raise HTTPException(status_code=404, detail="Authorization request not found")
    return {
        "id": str(auth_req.id),
        "status": auth_req.status,
        "appeal_level": auth_req.appeal_level,
        "created_at": auth_req.created_at.isoformat()
    }
```

Create `backend/api/routes/prompts.py`:
```python
from fastapi import APIRouter, HTTPException
from utils.prompt_loader import load_prompt, update_prompt
from pydantic import BaseModel

router = APIRouter(prefix="/api/v1/prompts", tags=["prompts"])

AGENT_NAMES = ["intake", "medical_analysis", "policy", "justification", "appeal", "submission", "claims"]

@router.get("/")
def list_prompts():
    """List all available prompt names."""
    return {"agents": AGENT_NAMES}

@router.get("/{agent_name}")
def get_prompt(agent_name: str):
    """Get the current prompt for an agent."""
    if agent_name not in AGENT_NAMES:
        raise HTTPException(status_code=404, detail="Agent not found")
    try:
        return load_prompt(agent_name)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Prompt file not found")

class PromptUpdateRequest(BaseModel):
    system: str
    user_template: str

@router.put("/{agent_name}")
def update_agent_prompt(agent_name: str, request: PromptUpdateRequest):
    """Update a prompt from the UI editor."""
    if agent_name not in AGENT_NAMES:
        raise HTTPException(status_code=404, detail="Agent not found")
    success = update_prompt(agent_name, request.system, request.user_template)
    return {"success": success, "agent": agent_name}
```

Update `backend/api/main.py` to include routers:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes.authorization import router as auth_router
from api.routes.prompts import router as prompts_router
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(title="MediAuth AI", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(prompts_router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "MediAuth AI", "version": "0.1.0"}
```

### How to verify Phase 9 is complete
```bash
# Start server
uvicorn api.main:app --reload

# Test health
curl http://localhost:8000/health

# Test authorization (in another terminal)
curl -X POST http://localhost:8000/api/v1/authorize \
  -H "Content-Type: application/json" \
  -d '{"patient_text": "Patient: Jane Doe, Insurance: BlueCross, Diagnoses: Type 2 Diabetes", "requested_treatment": "Continuous glucose monitor"}'

# Test prompts endpoint
curl http://localhost:8000/api/v1/prompts/
```
All three curl commands should return valid JSON.

---

## Phase 10 — Flutter Frontend

### What to do
Build three screens in Flutter: Patient Intake Form, Authorization Status Dashboard, and Prompt Editor.

### How to do it

**Step 1 — Initialize Flutter project**
```bash
# From project root (mediauth-ai/)
flutter create frontend
cd frontend

# Clean up default files
rm lib/main.dart
```

**Step 2 — Update pubspec.yaml**

Replace contents of `frontend/pubspec.yaml`:
```yaml
name: mediauth_frontend
description: MediAuth AI Flutter Frontend
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.2
  go_router: ^13.2.0
  flutter_dotenv: ^5.1.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

```bash
flutter pub get
```

**Step 3 — Create API service**

Create `frontend/lib/services/api_service.dart`:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> submitAuthorization({
    required String patientText,
    required String treatment,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/authorize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patient_text': patientText,
        'requested_treatment': treatment,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Authorization failed: ${response.body}');
  }

  static Future<Map<String, dynamic>> getPrompt(String agentName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/prompts/$agentName'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load prompt');
  }

  static Future<bool> updatePrompt(
      String agentName, String system, String userTemplate) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/prompts/$agentName'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'system': system, 'user_template': userTemplate}),
    );
    return response.statusCode == 200;
  }
}
```

**Step 4 — Create Patient Intake Screen**

Create `frontend/lib/screens/patient_intake_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'authorization_status_screen.dart';

class PatientIntakeScreen extends StatefulWidget {
  const PatientIntakeScreen({super.key});

  @override
  State<PatientIntakeScreen> createState() => _PatientIntakeScreenState();
}

class _PatientIntakeScreenState extends State<PatientIntakeScreen> {
  final _patientController = TextEditingController();
  final _treatmentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_patientController.text.isEmpty || _treatmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.submitAuthorization(
        patientText: _patientController.text,
        treatment: _treatmentController.text,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuthorizationStatusScreen(result: result),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediAuth AI'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Enter the patient\'s medical history, insurance details, diagnoses, and medications.'),
            const SizedBox(height: 16),
            TextField(
              controller: _patientController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText:
                    'Patient: John Doe, DOB: 1975-03-15\nInsurance: BlueCross, Policy #BCX-12345\nDiagnoses: Type 2 Diabetes\nMedications: Metformin 1000mg\nAllergies: Penicillin',
                border: const OutlineInputBorder(),
                labelText: 'Patient Medical History',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _treatmentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Requested Treatment / Procedure',
                hintText: 'e.g. MRI of lumbar spine, CPT 72148',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit for Authorization',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 5 — Create Authorization Status Screen**

Create `frontend/lib/screens/authorization_status_screen.dart`:
```dart
import 'package:flutter/material.dart';

class AuthorizationStatusScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const AuthorizationStatusScreen({super.key, required this.result});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'appealing':
        return Colors.orange;
      case 'escalated':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = result['workflow_status'] ?? 'unknown';
    final appealLevel = result['appeal_level'] ?? 0;
    final auditTrail = result['audit_trail'] as List? ?? [];
    final letter = result['justification_letter'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authorization Status'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor(status)),
              ),
              child: Column(
                children: [
                  Text(status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status))),
                  if (appealLevel > 0)
                    Text('Appeal Level: $appealLevel / 3',
                        style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Agent Trail
            const Text('Agent Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...auditTrail.map((log) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(log['agent']?.toString() ?? ''),
                  subtitle: Text(log['status']?.toString() ?? ''),
                  dense: true,
                )),

            const SizedBox(height: 24),

            // Justification Letter Preview
            if (letter.isNotEmpty) ...[
              const Text('Justification Letter',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(letter, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

**Step 6 — Create Prompt Editor Screen**

Create `frontend/lib/screens/prompt_editor_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PromptEditorScreen extends StatefulWidget {
  const PromptEditorScreen({super.key});

  @override
  State<PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<PromptEditorScreen> {
  final agents = ['intake', 'medical_analysis', 'policy', 'justification', 'appeal', 'submission', 'claims'];
  String _selectedAgent = 'intake';
  final _systemController = TextEditingController();
  final _templateController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  Future<void> _loadPrompt() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPrompt(_selectedAgent);
      _systemController.text = data['system'] ?? '';
      _templateController.text = data['user_template'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePrompt() async {
    final success = await ApiService.updatePrompt(
        _selectedAgent, _systemController.text, _templateController.text);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Saved!' : 'Save failed')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Editor'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _savePrompt,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedAgent,
                    items: agents
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedAgent = val!);
                      _loadPrompt();
                    },
                    decoration: const InputDecoration(
                        labelText: 'Select Agent', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _systemController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                          labelText: 'System Prompt', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: _templateController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                          labelText: 'User Template', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
```

**Step 7 — Create main.dart**

Create `frontend/lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'screens/patient_intake_screen.dart';
import 'screens/prompt_editor_screen.dart';

void main() {
  runApp(const MediAuthApp());
}

class MediAuthApp extends StatelessWidget {
  const MediAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediAuth AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A5F)),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final _screens = const [
    PatientIntakeScreen(),
    PromptEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Authorize'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Prompts'),
        ],
      ),
    );
  }
}
```

### How to verify Phase 10 is complete
```bash
cd frontend
flutter run -d chrome    # For web
# OR
flutter run              # For connected device/emulator
```
The app should launch showing the Patient Intake Form. Fill in the fields and tap Submit — you should see the Authorization Status screen with agent activity.

---

## Phase 11 — Testing

### What to do
Write pytest unit tests (one per agent) and a Postman collection for API integration tests.

### How to do it

**Step 1 — Unit tests**

Create `backend/tests/test_intake_agent.py`:
```python
import pytest
from unittest.mock import patch

SAMPLE_INPUT = """
Patient: John Doe, DOB 1975-03-15
Insurance: BlueCross, Policy #BCX-12345
Diagnoses: Type 2 Diabetes, Hypertension
Medications: Metformin 1000mg, Lisinopril 10mg
Allergies: Penicillin
"""

def test_intake_agent_returns_dict():
    """Agent 1 must return a dict with at least name and diagnoses."""
    from agents.intake_agent import run_intake_agent
    with patch("agents.intake_agent.call_claude_for_json") as mock_claude:
        mock_claude.return_value = {
            "name": "John Doe",
            "diagnoses": ["Type 2 Diabetes"],
            "medications": ["Metformin 1000mg"],
            "missing_fields": []
        }
        result = run_intake_agent(SAMPLE_INPUT)
        assert result["status"] == "success"
        assert "name" in result or "diagnoses" in result

def test_intake_agent_handles_error():
    """Agent 1 must handle Claude API errors gracefully."""
    from agents.intake_agent import run_intake_agent
    with patch("agents.intake_agent.call_claude_for_json") as mock_claude:
        mock_claude.side_effect = Exception("API error")
        result = run_intake_agent(SAMPLE_INPUT)
        assert result["status"] == "error"
        assert "error" in result
```

Create `backend/tests/test_appeal_agent.py`:
```python
import pytest
from unittest.mock import patch

def test_appeal_agent_returns_letter():
    """Agent 6 must return a non-empty appeal letter string."""
    from agents.appeal_agent import run_appeal_agent
    with patch("agents.appeal_agent.call_claude") as mock_claude:
        mock_claude.return_value = "Dear Insurance Provider, we formally appeal your denial..."
        
        result = run_appeal_agent(
            denial_reason="Step therapy not completed",
            patient_profile={"name": "John Doe", "diagnoses": ["Chronic Back Pain"], "insurer_name": "BlueCross"},
            medical_analysis={"clinical_necessity_summary": "Patient requires MRI", "icd10_codes": []},
            appeal_level=1
        )
        assert isinstance(result, str)
        assert len(result) > 50

def test_appeal_agent_escalates_tone_at_level_3():
    """Level 3 appeal must be called with level=3."""
    from agents.appeal_agent import run_appeal_agent
    with patch("agents.appeal_agent.call_claude") as mock_claude:
        mock_claude.return_value = "URGENT LEGAL NOTICE..."
        
        result = run_appeal_agent(
            denial_reason="Not medically necessary",
            patient_profile={"name": "Jane Doe", "insurer_name": "Aetna", "diagnoses": []},
            medical_analysis={"clinical_necessity_summary": "", "icd10_codes": []},
            appeal_level=3
        )
        # Claude was called with level 3 in the user prompt
        call_args = mock_claude.call_args[0]
        assert "3" in call_args[1]  # appeal_level=3 appears in user message
```

Create `backend/tests/test_api.py`:
```python
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch
from api.main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_prompts_list():
    response = client.get("/api/v1/prompts/")
    assert response.status_code == 200
    data = response.json()
    assert "agents" in data
    assert "intake" in data["agents"]
```

**Step 2 — Run tests**
```bash
cd backend
pytest tests/ -v
```

**Step 3 — Create Postman Collection**

Create a file `backend/tests/postman_collection.json`:
```json
{
  "info": {"name": "MediAuth AI API Tests", "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"},
  "item": [
    {
      "name": "Health Check",
      "request": {"method": "GET", "url": "http://localhost:8000/health"}
    },
    {
      "name": "List Prompts",
      "request": {"method": "GET", "url": "http://localhost:8000/api/v1/prompts/"}
    },
    {
      "name": "Get Intake Prompt",
      "request": {"method": "GET", "url": "http://localhost:8000/api/v1/prompts/intake"}
    },
    {
      "name": "Submit Authorization",
      "request": {
        "method": "POST",
        "url": "http://localhost:8000/api/v1/authorize",
        "header": [{"key": "Content-Type", "value": "application/json"}],
        "body": {
          "mode": "raw",
          "raw": "{\"patient_text\": \"Patient: John Doe, Insurance: BlueCross, Diagnoses: Type 2 Diabetes\", \"requested_treatment\": \"Continuous glucose monitor\"}"
        }
      }
    }
  ]
}
```

### How to verify Phase 11 is complete
```bash
pytest tests/ -v --tb=short
```
All tests must pass. Postman collection should return 200 for all endpoints.

---

## Phase 12 — Docker

### What to do
Containerize the backend and database.

### How to do it

Create `backend/Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Create `docker-compose.yml` in project root:
```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mediauth
      POSTGRES_USER: mediauth_user
      POSTGRES_PASSWORD: mediauth_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://mediauth_user:mediauth_pass@db:5432/mediauth
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      JWT_SECRET: ${JWT_SECRET}
      ENVIRONMENT: production
    depends_on:
      - db
    volumes:
      - ./backend/prompts:/app/prompts
      - ./backend/knowledge_base:/app/knowledge_base

volumes:
  postgres_data:
```

Create `.env` in project root (for docker-compose):
```
ANTHROPIC_API_KEY=your_key_here
JWT_SECRET=your_jwt_secret_here
```

### How to verify Phase 12 is complete
```bash
docker-compose up --build
curl http://localhost:8000/health
```
Should return `{"status": "ok"}` from inside the Docker container.

---

## Phase 13 — Deployment

### What to do
Deploy backend to Render.com and Flutter web frontend to Vercel or Render.

### How to do it

**Backend to Render.com:**
1. Push your full repo to GitHub (public)
2. Go to https://render.com → New → Web Service
3. Connect your GitHub repo
4. Set: Root Directory = `backend`, Build Command = `pip install -r requirements.txt`, Start Command = `uvicorn api.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables: `ANTHROPIC_API_KEY`, `DATABASE_URL`, `JWT_SECRET`
6. Add a PostgreSQL database on Render → copy the connection string to `DATABASE_URL`
7. Click Deploy

**Flutter web frontend:**
```bash
cd frontend
flutter build web
# Upload the build/web/ folder to Vercel, Netlify, or Render static site
```

### How to verify Phase 13 is complete
```bash
curl https://your-app.onrender.com/health
```
Returns `{"status": "ok"}` from the live deployment URL.

---

## Phase 14 — Submission Polish

### What to do
Write README, record demo video, submit GitHub repo.

### How to do it

**README.md must include:**
- Project description (2 paragraphs)
- Architecture diagram (link to `architecture.png`)
- Live deployment URL
- Setup instructions (clone → .env → docker-compose up → flutter run)
- Tech stack table
- Team member GitHub accounts
- How to run tests

**Demo video (3–5 minutes):**
1. Show the Flutter app home screen
2. Enter patient details and submit
3. Show the agent progress in real time
4. Show the justification letter
5. Show the appeal loop (change mock to return "denied")
6. Open the Prompt Editor — edit a prompt live
7. Show the live deployment URL

### How to verify Phase 14 is complete
- [ ] README is complete with live URL
- [ ] `architecture.png` is in repo root
- [ ] GitHub repo is public
- [ ] All team members have commits from their own accounts
- [ ] Demo video is recorded and link is in README
- [ ] Hackathon submission form is filled

---

## Troubleshooting Reference

| Problem | Fix |
|---|---|
| `ModuleNotFoundError` | Make sure venv is activated: `source venv/bin/activate` |
| `psycopg2` install fails | Try `pip install psycopg2-binary` instead |
| ChromaDB import error | `pip install chromadb==0.5.0` exactly |
| Claude API 401 error | Check `ANTHROPIC_API_KEY` in `.env` |
| Flutter `http` not found | Run `flutter pub get` in frontend/ |
| Docker DB connection refused | Wait 10s for postgres to start, then try again |
| LangGraph cycle error | Ensure `END` is imported from `langgraph.graph` |
| CORS error from Flutter | Check `allow_origins=["*"]` in FastAPI middleware |
