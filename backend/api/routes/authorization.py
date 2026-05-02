# backend/api/routes/authorization.py
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from models.database import get_db
from models.patient import Patient
from models.auth_request import AuthRequest
from agents.orchestrator import run_authorization_workflow
import uuid

router = APIRouter(prefix="/api/v1", tags=["authorization"])


# ─── Request/Response schemas ───
class PatientIntakeRequest(BaseModel):
    patient_text: str
    requested_treatment: str


class AuthorizationResponse(BaseModel):
    auth_request_id: str
    workflow_status: str
    appeal_level: int
    justification_letter: str | None
    audit_trail: list


# ─── Endpoints ───
@router.post("/authorize", response_model=AuthorizationResponse)
async def run_authorization(request: PatientIntakeRequest, db: Session = Depends(get_db)):
    try:
        result = run_authorization_workflow(
            patient_input=request.patient_text,
            treatment=request.requested_treatment
        )

        profile = result.get("patient_profile", {}) or {}
        medical = result.get("medical_analysis", {}) or {}

        # ── Fix 1: pass lists directly — SQLAlchemy JSON columns handle serialization
        icd10 = medical.get("icd10_codes") or []
        cpt   = medical.get("cpt_codes") or []
        # Make sure they are plain Python lists, not strings
        if isinstance(icd10, str):
            import json; icd10 = json.loads(icd10)
        if isinstance(cpt, str):
            import json; cpt = json.loads(cpt)

        # ── Fix 2: justification_letter might be a dict {"status":..., "letter":...}
        raw_letter = result.get("justification_letter")
        if isinstance(raw_letter, dict):
            justification_letter = raw_letter.get("letter", str(raw_letter))
        elif isinstance(raw_letter, str):
            justification_letter = raw_letter
        else:
            justification_letter = ""

        # ── Fix 3: diagnoses/medications — pass as plain lists, not json.dumps()
        diagnoses  = profile.get("diagnoses") or []
        medications = profile.get("medications") or []
        if isinstance(diagnoses, str):
            import json; diagnoses = json.loads(diagnoses)
        if isinstance(medications, str):
            import json; medications = json.loads(medications)

        # Save patient
        patient = Patient(
            name=profile.get("name", "Unknown Patient"),
            insurance_policy_number=profile.get("insurance_policy_number"),
            insurer_name=profile.get("insurer_name"),
            diagnoses=diagnoses,
            medications=medications,
            structured_profile=profile          # pass dict directly
        )
        db.add(patient)
        db.flush()

        # Save auth request
        auth_req = AuthRequest(
            patient_id=patient.id,
            status=result.get("workflow_status", "unknown"),
            icd10_codes=icd10,                  # plain list — NOT json.dumps()
            cpt_codes=cpt,                       # plain list — NOT json.dumps()
            clinical_summary=medical.get("clinical_necessity_summary"),
            justification_letter=justification_letter,   # plain string now
            appeal_level=int(result.get("appeal_level") or 0),
            denial_reason=None,
            insurer_response=None
        )
        db.add(auth_req)
        db.commit()

        return AuthorizationResponse(
            auth_request_id=str(auth_req.id),
            workflow_status=result.get("workflow_status", "unknown"),
            appeal_level=int(result.get("appeal_level") or 0),
            justification_letter=justification_letter,
            audit_trail=result.get("audit_trail", [])
        )

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Workflow failed: {str(e)}")