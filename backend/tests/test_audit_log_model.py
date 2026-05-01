import pytest
import uuid
from datetime import datetime
from models.audit_log import AuditLog


class TestAuditLogModel:
    """Tests for the AuditLog SQLAlchemy model."""

    def test_create_audit_log(self, db_session, sample_audit_log):
        """Test creating an audit log with all fields."""
        assert sample_audit_log.id is not None
        assert isinstance(sample_audit_log.id, uuid.UUID)
        assert sample_audit_log.agent_name == "intake"
        assert sample_audit_log.action == "Patient intake completed"

    def test_audit_log_id_is_uuid(self, sample_audit_log):
        """Test that audit log ID is a UUID."""
        assert isinstance(sample_audit_log.id, uuid.UUID)

    def test_audit_log_auth_request_id_nullable(self, db_session):
        """Test that auth_request_id can be None."""
        audit_log = AuditLog(
            agent_name="intake",
            action="Test action",
            status="success",
        )
        db_session.add(audit_log)
        db_session.commit()
        db_session.refresh(audit_log)

        assert audit_log.auth_request_id is None

    def test_audit_log_auth_request_id_linked(
        self, sample_audit_log, sample_auth_request
    ):
        """Test that auth_request_id can be linked to an auth request."""
        assert sample_audit_log.auth_request_id == sample_auth_request.id

    def test_audit_log_input_data_is_json(self, sample_audit_log):
        """Test that input_data field stores JSON data."""
        assert isinstance(sample_audit_log.input_data, dict)
        assert "patient_input" in sample_audit_log.input_data

    def test_audit_log_output_data_is_json(self, sample_audit_log):
        """Test that output_data field stores JSON data."""
        assert isinstance(sample_audit_log.output_data, dict)
        assert "name" in sample_audit_log.output_data

    def test_audit_log_status_field(self, sample_audit_log):
        """Test that status field stores the status."""
        assert sample_audit_log.status == "success"

    def test_audit_log_error_message_nullable(self, sample_audit_log):
        """Test that error_message can be None."""
        assert sample_audit_log.error_message is None

    def test_audit_log_error_message_set(self, db_session):
        """Test setting error_message on failure."""
        audit_log = AuditLog(
            agent_name="medical_analysis",
            action="Failed to analyze",
            input_data={"patient_id": "123"},
            output_data=None,
            status="error",
            error_message="API timeout occurred",
        )
        db_session.add(audit_log)
        db_session.commit()
        db_session.refresh(audit_log)

        assert audit_log.error_message == "API timeout occurred"
        assert audit_log.status == "error"

    def test_audit_log_timestamp_auto_set(self, sample_audit_log):
        """Test that timestamp is automatically set."""
        assert sample_audit_log.timestamp is not None
        assert isinstance(sample_audit_log.timestamp, datetime)

    def test_audit_log_agent_name(self, sample_audit_log):
        """Test agent_name field stores agent identifier."""
        assert sample_audit_log.agent_name == "intake"

    def test_audit_log_action(self, sample_audit_log):
        """Test action field stores action description."""
        assert isinstance(sample_audit_log.action, str)
        assert len(sample_audit_log.action) > 0

    def test_audit_log_multiple_entries(self, db_session, sample_auth_request):
        """Test creating multiple audit log entries."""
        logs = [
            AuditLog(
                auth_request_id=sample_auth_request.id,
                agent_name="intake",
                action="Intake completed",
                status="success",
            ),
            AuditLog(
                auth_request_id=sample_auth_request.id,
                agent_name="medical_analysis",
                action="Analysis completed",
                status="success",
            ),
            AuditLog(
                auth_request_id=sample_auth_request.id,
                agent_name="policy",
                action="Policy check failed",
                status="error",
                error_message="Policy not found",
            ),
        ]
        db_session.add_all(logs)
        db_session.commit()

        auth_logs = (
            db_session.query(AuditLog)
            .filter(AuditLog.auth_request_id == sample_auth_request.id)
            .all()
        )
        assert len(auth_logs) >= 3

    def test_audit_log_retrieval(self, db_session, sample_audit_log):
        """Test retrieving an audit log from the database."""
        retrieved = (
            db_session.query(AuditLog)
            .filter(AuditLog.id == sample_audit_log.id)
            .first()
        )
        assert retrieved is not None
        assert retrieved.agent_name == sample_audit_log.agent_name
        assert retrieved.action == sample_audit_log.action

    def test_audit_log_without_auth_request(self, db_session):
        """Test creating audit log without linking to auth request."""
        audit_log = AuditLog(
            agent_name="system",
            action="System startup",
            status="success",
        )
        db_session.add(audit_log)
        db_session.commit()
        db_session.refresh(audit_log)

        assert audit_log.auth_request_id is None
        assert audit_log.id is not None

    def test_audit_log_delete(self, db_session, sample_audit_log):
        """Test deleting an audit log."""
        log_id = sample_audit_log.id
        db_session.delete(sample_audit_log)
        db_session.commit()

        retrieved = db_session.query(AuditLog).filter(AuditLog.id == log_id).first()
        assert retrieved is None
