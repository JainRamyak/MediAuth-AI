# backend/api/routes/authorization.py
import json
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt
from sqlalchemy.orm import Session
from sqlalchemy import cast, String
from pydantic import BaseModel
from models.database import get_db
from models.patient import Patient
from models.auth_request import AuthRequest
from models.audit_log import AuditLog
from models.claim import Claim
from agents.orchestrator import run_authorization_workflow, run_appeal_workflow, AuthState
import uuid

router = APIRouter(prefix="/api/v1", tags=["authorization"])

security = HTTPBearer(auto_error=False)

def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        return None
    try:
        payload = jwt.get_unverified_claims(credentials.credentials)
        return payload.get("sub")
    except Exception:
        return None


# ─── Request/Response schemas ───
class PatientIntakeRequest(BaseModel):
    patient_text: str
    requested_treatment: str
    structured_profile: dict | None = None


class AuthorizationResponse(BaseModel):
    auth_request_id: str
    workflow_status: str
    appeal_level: int
    justification_letter: str | None
    audit_trail: list
    denial_reason: str | None = None


class AuthHistoryItem(BaseModel):
    auth_request_id: str
    workflow_status: str
    appeal_level: int
    insurer: str | None
    policy_number: str | None
    patient_name: str | None
    requested_treatment: str | None
    justification_letter: str | None
    denial_reason: str | None
    icd10_codes: list | None = []
    cpt_codes: list | None = []
    created_at: str


# ─── Endpoints ───
@router.post("/authorize", response_model=AuthorizationResponse)
def run_authorization(
    request: PatientIntakeRequest, 
    db: Session = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    try:
        result = run_authorization_workflow(
            patient_input=request.patient_text,
            treatment=request.requested_treatment,
            structured_profile=request.structured_profile
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
            date_of_birth=profile.get("date_of_birth"),
            insurance_policy_number=profile.get("insurance_policy_number"),
            insurer_name=profile.get("insurer_name"),
            diagnoses=diagnoses,
            medications=medications,
            allergies=profile.get("allergies"),
            medical_history=profile.get("medical_history"),
            structured_profile=profile          # pass dict directly
        )
        db.add(patient)
        db.flush()

        # Save auth request
        auth_req = AuthRequest(
            patient_id=patient.id,
            user_id=user_id,
            status=result.get("workflow_status", "unknown"),
            requested_treatment=request.requested_treatment,
            icd10_codes=icd10,                  # plain list — NOT json.dumps()
            cpt_codes=cpt,                       # plain list — NOT json.dumps()
            clinical_summary=medical.get("clinical_necessity_summary"),
            justification_letter=justification_letter,   # plain string now
            appeal_level=int(result.get("appeal_level") or 0),
            denial_reason=result.get("submission_result", {}).get("denial_reason"),
            insurer_response=None
        )
        db.add(auth_req)
        db.flush()

        # Save Audit Logs
        for entry in result.get("audit_trail", []):
            al = AuditLog(
                auth_request_id=auth_req.id,
                agent_name=entry.get("agent"),
                action=entry.get("status"),
                status=entry.get("status"),
                input_data=None,
                output_data=entry,
                error_message=entry.get("error") if "error" in entry else None
            )
            db.add(al)

        # Save Claim Validation if exists
        cv = result.get("claims_validation")
        if cv:
            cl = Claim(
                auth_request_id=auth_req.id,
                billing_codes={"icd10": icd10, "cpt": cpt},
                risk_score=cv.get("risk_score"),
                risk_flags=cv.get("issues_found"),
                corrected_codes=cv.get("corrected_codes"),
                status="processed"
            )
            db.add(cl)

        db.commit()

        return AuthorizationResponse(
            auth_request_id=str(auth_req.id),
            workflow_status=result.get("workflow_status", "unknown"),
            appeal_level=int(result.get("appeal_level") or 0),
            justification_letter=justification_letter,
            audit_trail=result.get("audit_trail", []),
            denial_reason=result.get("submission_result", {}).get("denial_reason")
        )

    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Workflow failed: {str(e)}")


@router.post("/authorize/{auth_request_id}/appeal", response_model=AuthorizationResponse)
def run_appeal(auth_request_id: str, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    try:
        req_uuid = uuid.UUID(auth_request_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid authorization ID")

    query = (db.query(AuthRequest, Patient)
               .join(Patient, AuthRequest.patient_id == Patient.id)
               .filter(AuthRequest.id == req_uuid))
    
    if user_id:
        query = query.filter(cast(AuthRequest.user_id, String) == str(user_id))
        
    row = query.first()
    if row is None:
        raise HTTPException(status_code=404, detail="Authorization request not found")
        
    ar, p = row
    
    if (ar.appeal_level or 0) >= 3:
        raise HTTPException(status_code=400, detail="Max appeal levels reached")

    # Manually reconstruct the AuthState from DB state to skip initial extraction nodes
    state = AuthState(
        raw_patient_input="",
        requested_treatment="",
        patient_profile=p.structured_profile or {"name": p.name, "insurer_name": p.insurer_name},
        medical_analysis={"clinical_necessity_summary": ar.clinical_summary, "icd10_codes": ar.icd10_codes, "cpt_codes": ar.cpt_codes},
        policy_check=None,
        justification_letter=ar.justification_letter,
        submission_result={"decision": "denied", "denial_reason": ar.denial_reason},
        appeal_result=None,
        claims_validation=None,
        current_agent="submission",
        workflow_status="denied",
        appeal_level=ar.appeal_level or 0,
        error_message=None,
        audit_trail=[]
    )

    result = run_appeal_workflow(state)

    ar.appeal_level = int(result.get("appeal_level") or ar.appeal_level or 0)
    
    raw_letter = result.get("justification_letter")
    if isinstance(raw_letter, dict):
        ar.justification_letter = raw_letter.get("letter", str(raw_letter))
    elif isinstance(raw_letter, str):
        ar.justification_letter = raw_letter
        
    ar.status = result.get("workflow_status", "unknown")
    ar.denial_reason = result.get("submission_result", {}).get("denial_reason")

    # Save incremental Audit Logs
    for entry in result.get("audit_trail", []):
        al = AuditLog(
            auth_request_id=ar.id,
            agent_name=entry.get("agent"),
            action=entry.get("status"),
            status=entry.get("status"),
            input_data=None,
            output_data=entry,
            error_message=entry.get("error") if "error" in entry else None
        )
        db.add(al)

    db.commit()

    return AuthorizationResponse(
        auth_request_id=str(ar.id),
        workflow_status=ar.status,
        appeal_level=ar.appeal_level,
        justification_letter=ar.justification_letter,
        audit_trail=result.get("audit_trail", []),
        denial_reason=ar.denial_reason
    )


# ─── GET /history, /authorize — list all requests (newest first) ───
@router.get("/history", response_model=list[AuthHistoryItem])
@router.get("/authorize", response_model=list[AuthHistoryItem])
def list_authorizations(limit: int = 50, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    """Returns the most recent authorization requests with patient info joined."""
    query = (
        db.query(AuthRequest, Patient)
        .join(Patient, AuthRequest.patient_id == Patient.id)
    )
    
    if user_id:
        query = query.filter(cast(AuthRequest.user_id, String) == str(user_id))
        
    rows = query.order_by(AuthRequest.created_at.desc()).limit(limit).all()
    return [
        AuthHistoryItem(
            auth_request_id=str(ar.id),
            workflow_status=ar.status or "unknown",
            appeal_level=ar.appeal_level or 0,
            insurer=p.insurer_name,
            policy_number=p.insurance_policy_number,
            patient_name=p.name,
            requested_treatment=ar.requested_treatment,
            justification_letter=ar.justification_letter,
            denial_reason=ar.denial_reason,
            icd10_codes=ar.icd10_codes or [],
            cpt_codes=ar.cpt_codes or [],
            created_at=ar.created_at.isoformat() if ar.created_at else "",
        )
        for ar, p in rows
    ]


# ─── GET /authorize/{auth_request_id} — single request detail ───
@router.get("/authorize/{auth_request_id}", response_model=AuthHistoryItem)
def get_authorization(auth_request_id: str, db: Session = Depends(get_db), user_id: str = Depends(get_current_user_id)):
    """Returns a single authorization request by ID."""
    try:
        req_uuid = uuid.UUID(auth_request_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid authorization ID")

    query = (
        db.query(AuthRequest, Patient)
        .join(Patient, AuthRequest.patient_id == Patient.id)
        .filter(AuthRequest.id == req_uuid)
    )
    
    if user_id:
        query = query.filter(cast(AuthRequest.user_id, String) == str(user_id))
        
    row = query.first()
    if row is None:
        raise HTTPException(status_code=404, detail="Authorization request not found")

    ar, p = row
    return AuthHistoryItem(
        auth_request_id=str(ar.id),
        workflow_status=ar.status or "unknown",
        appeal_level=ar.appeal_level or 0,
        insurer=p.insurer_name,
        policy_number=p.insurance_policy_number,
        patient_name=p.name,
        requested_treatment=ar.requested_treatment,
        justification_letter=ar.justification_letter,
        denial_reason=ar.denial_reason,
        icd10_codes=ar.icd10_codes or [],
        cpt_codes=ar.cpt_codes or [],
        created_at=ar.created_at.isoformat() if ar.created_at else "",
    )
