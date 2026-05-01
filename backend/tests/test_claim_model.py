import pytest
import uuid
from datetime import datetime
from models.claim import Claim


class TestClaimModel:
    """Tests for the Claim SQLAlchemy model."""

    def test_create_claim(self, db_session, sample_claim):
        """Test creating a claim with all fields."""
        assert sample_claim.id is not None
        assert isinstance(sample_claim.id, uuid.UUID)
        assert sample_claim.status == "pending_review"
        assert sample_claim.risk_score == "LOW"

    def test_claim_id_is_uuid(self, sample_claim):
        """Test that claim ID is a UUID."""
        assert isinstance(sample_claim.id, uuid.UUID)

    def test_claim_auth_request_id_required(self, sample_claim, sample_auth_request):
        """Test that auth_request_id is required."""
        assert sample_claim.auth_request_id == sample_auth_request.id

    def test_claim_billing_codes_is_json(self, sample_claim):
        """Test that billing_codes field stores JSON data."""
        assert isinstance(sample_claim.billing_codes, list)
        assert len(sample_claim.billing_codes) == 1
        assert sample_claim.billing_codes[0]["code"] == "99213"

    def test_claim_risk_score(self, sample_claim):
        """Test that risk_score field stores the risk score."""
        assert sample_claim.risk_score == "LOW"

    def test_claim_risk_score_values(self, db_session, sample_auth_request):
        """Test different risk score values."""
        risk_scores = ["LOW", "MEDIUM", "HIGH"]
        for score in risk_scores:
            claim = Claim(
                auth_request_id=sample_auth_request.id,
                risk_score=score,
            )
            db_session.add(claim)
            db_session.commit()
            db_session.refresh(claim)
            assert claim.risk_score == score

    def test_claim_risk_flags_is_json(self, sample_claim):
        """Test that risk_flags field stores JSON data."""
        assert isinstance(sample_claim.risk_flags, list)

    def test_claim_risk_flags_with_data(self, db_session, sample_auth_request):
        """Test risk_flags with actual flag data."""
        claim = Claim(
            auth_request_id=sample_auth_request.id,
            risk_flags=[
                {"flag": "Missing modifier", "severity": "medium"},
                {"flag": "Duplicate code", "severity": "high"},
            ],
        )
        db_session.add(claim)
        db_session.commit()
        db_session.refresh(claim)

        assert len(claim.risk_flags) == 2
        assert claim.risk_flags[0]["flag"] == "Missing modifier"

    def test_claim_status_default(self, db_session, sample_auth_request):
        """Test that status defaults to 'pending_review'."""
        claim = Claim(auth_request_id=sample_auth_request.id)
        db_session.add(claim)
        db_session.commit()
        db_session.refresh(claim)

        assert claim.status == "pending_review"

    def test_claim_status_update(self, db_session, sample_claim):
        """Test updating claim status."""
        sample_claim.status = "approved"
        db_session.commit()
        db_session.refresh(sample_claim)

        assert sample_claim.status == "approved"

    def test_claim_corrected_codes_nullable(self, sample_claim):
        """Test that corrected_codes can be None."""
        assert sample_claim.corrected_codes is None

    def test_claim_corrected_codes_set(self, db_session, sample_auth_request):
        """Test setting corrected_codes."""
        claim = Claim(
            auth_request_id=sample_auth_request.id,
            corrected_codes=[
                {
                    "original": "99213",
                    "corrected": "99214",
                    "reason": "Higher complexity",
                }
            ],
        )
        db_session.add(claim)
        db_session.commit()
        db_session.refresh(claim)

        assert claim.corrected_codes is not None
        assert claim.corrected_codes[0]["original"] == "99213"
        assert claim.corrected_codes[0]["corrected"] == "99214"

    def test_claim_created_at_auto_set(self, sample_claim):
        """Test that created_at is automatically set."""
        assert sample_claim.created_at is not None
        assert isinstance(sample_claim.created_at, datetime)

    def test_claim_retrieval(self, db_session, sample_claim):
        """Test retrieving a claim from the database."""
        retrieved = db_session.query(Claim).filter(Claim.id == sample_claim.id).first()
        assert retrieved is not None
        assert retrieved.auth_request_id == sample_claim.auth_request_id
        assert retrieved.risk_score == sample_claim.risk_score

    def test_claim_multiple_per_auth_request(self, db_session, sample_auth_request):
        """Test that an auth request can have multiple claims."""
        claim1 = Claim(auth_request_id=sample_auth_request.id, risk_score="LOW")
        claim2 = Claim(auth_request_id=sample_auth_request.id, risk_score="MEDIUM")
        db_session.add_all([claim1, claim2])
        db_session.commit()

        auth_claims = (
            db_session.query(Claim)
            .filter(Claim.auth_request_id == sample_auth_request.id)
            .all()
        )
        assert len(auth_claims) >= 2

    def test_claim_delete(self, db_session, sample_claim):
        """Test deleting a claim."""
        claim_id = sample_claim.id
        db_session.delete(sample_claim)
        db_session.commit()

        retrieved = db_session.query(Claim).filter(Claim.id == claim_id).first()
        assert retrieved is None

    def test_claim_full_workflow(self, db_session, sample_auth_request):
        """Test a complete claim workflow from creation to correction."""
        # Create claim
        claim = Claim(
            auth_request_id=sample_auth_request.id,
            billing_codes=[{"code": "99213", "type": "CPT"}],
            risk_score="MEDIUM",
            risk_flags=[{"flag": "Missing documentation"}],
            status="pending_review",
        )
        db_session.add(claim)
        db_session.commit()
        db_session.refresh(claim)

        assert claim.status == "pending_review"
        assert claim.risk_score == "MEDIUM"
        assert claim.corrected_codes is None

        # Update with corrections
        claim.corrected_codes = [
            {"original": "99213", "corrected": "99214", "reason": "Updated"}
        ]
        claim.status = "corrected"
        db_session.commit()
        db_session.refresh(claim)

        assert claim.corrected_codes is not None
        assert claim.status == "corrected"
