import pytest
import uuid
from datetime import datetime
from models.auth_request import AuthRequest


class TestAuthRequestModel:
    """Tests for the AuthRequest SQLAlchemy model."""

    def test_create_auth_request(self, db_session, sample_auth_request):
        """Test creating an auth request with all fields."""
        assert sample_auth_request.id is not None
        assert isinstance(sample_auth_request.id, uuid.UUID)
        assert sample_auth_request.status == "pending"
        assert sample_auth_request.patient_id is not None

    def test_auth_request_id_is_uuid(self, sample_auth_request):
        """Test that auth request ID is a UUID."""
        assert isinstance(sample_auth_request.id, uuid.UUID)

    def test_auth_request_patient_id_foreign_key(
        self, sample_auth_request, sample_patient
    ):
        """Test that patient_id is a valid foreign key."""
        assert sample_auth_request.patient_id == sample_patient.id

    def test_auth_request_status_default(self, db_session, sample_patient):
        """Test that status defaults to 'pending'."""
        auth_request = AuthRequest(patient_id=sample_patient.id)
        db_session.add(auth_request)
        db_session.commit()
        db_session.refresh(auth_request)

        assert auth_request.status == "pending"

    def test_auth_request_icd10_codes_is_json(self, sample_auth_request):
        """Test that icd10_codes field stores JSON data."""
        assert isinstance(sample_auth_request.icd10_codes, list)
        assert len(sample_auth_request.icd10_codes) == 1
        assert sample_auth_request.icd10_codes[0]["code"] == "E11.9"

    def test_auth_request_cpt_codes_is_json(self, sample_auth_request):
        """Test that cpt_codes field stores JSON data."""
        assert isinstance(sample_auth_request.cpt_codes, list)
        assert sample_auth_request.cpt_codes[0]["code"] == "99213"

    def test_auth_request_clinical_summary_is_text(self, sample_auth_request):
        """Test that clinical_summary field stores text."""
        assert isinstance(sample_auth_request.clinical_summary, str)
        assert "Type 2 Diabetes" in sample_auth_request.clinical_summary

    def test_auth_request_justification_letter_nullable(self, sample_auth_request):
        """Test that justification_letter can be None."""
        assert sample_auth_request.justification_letter is None

    def test_auth_request_denial_reason_nullable(self, sample_auth_request):
        """Test that denial_reason can be None."""
        assert sample_auth_request.denial_reason is None

    def test_auth_request_appeal_level_default(self, db_session, sample_patient):
        """Test that appeal_level defaults to 0."""
        auth_request = AuthRequest(patient_id=sample_patient.id)
        db_session.add(auth_request)
        db_session.commit()
        db_session.refresh(auth_request)

        assert auth_request.appeal_level == 0

    def test_auth_request_appeal_level_update(self, db_session, sample_auth_request):
        """Test updating appeal_level."""
        sample_auth_request.appeal_level = 2
        sample_auth_request.denial_reason = "Not medically necessary"
        db_session.commit()
        db_session.refresh(sample_auth_request)

        assert sample_auth_request.appeal_level == 2
        assert sample_auth_request.denial_reason == "Not medically necessary"

    def test_auth_request_created_at_auto_set(self, sample_auth_request):
        """Test that created_at is automatically set."""
        assert sample_auth_request.created_at is not None
        assert isinstance(sample_auth_request.created_at, datetime)

    def test_auth_request_updated_at_auto_set(self, sample_auth_request):
        """Test that updated_at is automatically set."""
        assert sample_auth_request.updated_at is not None
        assert isinstance(sample_auth_request.updated_at, datetime)

    def test_auth_request_patient_required(self, db_session):
        """Test that patient_id is required (nullable=False)."""
        auth_request = AuthRequest(status="pending")
        db_session.add(auth_request)
        with pytest.raises(Exception):
            db_session.commit()

    def test_auth_request_status_update(self, db_session, sample_auth_request):
        """Test updating auth request status."""
        sample_auth_request.status = "approved"
        sample_auth_request.insurer_response = "Your request has been approved."
        db_session.commit()
        db_session.refresh(sample_auth_request)

        assert sample_auth_request.status == "approved"
        assert sample_auth_request.insurer_response == "Your request has been approved."

    def test_auth_request_justification_letter_update(
        self, db_session, sample_auth_request
    ):
        """Test updating justification_letter."""
        letter = "Dear Insurance Company,\n\nThis letter is to request authorization..."
        sample_auth_request.justification_letter = letter
        db_session.commit()
        db_session.refresh(sample_auth_request)

        assert sample_auth_request.justification_letter == letter

    def test_auth_request_retrieval(self, db_session, sample_auth_request):
        """Test retrieving an auth request from the database."""
        retrieved = (
            db_session.query(AuthRequest)
            .filter(AuthRequest.id == sample_auth_request.id)
            .first()
        )
        assert retrieved is not None
        assert retrieved.patient_id == sample_auth_request.patient_id
        assert retrieved.status == sample_auth_request.status

    def test_auth_request_multiple_per_patient(self, db_session, sample_patient):
        """Test that a patient can have multiple auth requests."""
        auth1 = AuthRequest(patient_id=sample_patient.id, status="pending")
        auth2 = AuthRequest(patient_id=sample_patient.id, status="approved")
        db_session.add_all([auth1, auth2])
        db_session.commit()

        patient_auth_requests = (
            db_session.query(AuthRequest)
            .filter(AuthRequest.patient_id == sample_patient.id)
            .all()
        )
        assert len(patient_auth_requests) >= 2

    def test_auth_request_delete(self, db_session, sample_auth_request):
        """Test deleting an auth request."""
        auth_id = sample_auth_request.id
        db_session.delete(sample_auth_request)
        db_session.commit()

        retrieved = (
            db_session.query(AuthRequest).filter(AuthRequest.id == auth_id).first()
        )
        assert retrieved is None
