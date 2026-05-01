# backend/api/routes/authorization.py
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
    """
    Run the full multi-agent authorization workflow.
    This is the main endpoint — Flutter calls this on form submit.
    """
    try:
        # Run orchestrator
        result = run_authorization_workflow(
            patient_input=request.patient_text,
            treatment=request.requested_treatment
        )

        # Save patient to database
        patient = Patient(
            name=result["patient_profile"].get("name", "Unknown Patient"),
            insurance_policy_number=result["patient_profile"].get("insurance_policy_number"),
            insurer_name=result["patient_profile"].get("insurer_name"),
            diagnoses=result["patient_profile"].get("diagnoses"),
            medications=result["patient_profile"].get("medications"),
            structured_profile=result["patient_profile"]
        )
        db.add(patient)
        db.flush()  # Get patient.id without committing

        # Save authorization request to database
        auth_req = AuthRequest(
            patient_id=patient.id,
            status=result["workflow_status"],
            icd10_codes=result.get("medical_analysis", {}).get("icd10_codes"),
            cpt_codes=result.get("medical_analysis", {}).get("cpt_codes"),
            clinical_summary=result.get("medical_analysis", {}).get("clinical_necessity_summary"),
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
        raise HTTPException(status_code=500, detail=f"Workflow failed: {str(e)}")


@router.get("/authorize/{auth_request_id}")
async def get_authorization_status(auth_request_id: str, db: Session = Depends(get_db)):
    """Get status of a previously submitted authorization request."""
    auth_req = db.query(AuthRequest).filter(
        AuthRequest.id == auth_request_id
    ).first()

    if not auth_req:
        raise HTTPException(status_code=404, detail="Authorization request not found")

    return {
        "id": str(auth_req.id),
        "status": auth_req.status,
        "appeal_level": auth_req.appeal_level,
        "justification_letter": auth_req.justification_letter,
        "created_at": auth_req.created_at.isoformat()
    }