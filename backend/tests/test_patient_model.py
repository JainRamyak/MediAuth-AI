import pytest
import uuid
from datetime import datetime
from models.patient import Patient


class TestPatientModel:
    """Tests for the Patient SQLAlchemy model."""

    def test_create_patient(self, db_session, sample_patient_data):
        """Test creating a patient with all fields."""
        patient = Patient(**sample_patient_data)
        db_session.add(patient)
        db_session.commit()
        db_session.refresh(patient)

        assert patient.id is not None
        assert isinstance(patient.id, uuid.UUID)
        assert patient.name == "John Doe"
        assert patient.date_of_birth == "1990-01-15"
        assert patient.insurance_policy_number == "POL-123456"
        assert patient.insurer_name == "BlueCross"

    def test_patient_id_is_uuid(self, sample_patient):
        """Test that patient ID is a UUID."""
        assert isinstance(sample_patient.id, uuid.UUID)

    def test_patient_name_required(self, db_session):
        """Test that patient name is required (nullable=False)."""
        patient = Patient(
            date_of_birth="1990-01-15",
            insurance_policy_number="POL-123456",
        )
        db_session.add(patient)
        with pytest.raises(Exception):
            db_session.commit()

    def test_patient_diagnoses_is_json(self, sample_patient):
        """Test that diagnoses field stores JSON data."""
        assert isinstance(sample_patient.diagnoses, list)
        assert "Type 2 Diabetes" in sample_patient.diagnoses

    def test_patient_medications_is_json(self, sample_patient):
        """Test that medications field stores JSON data."""
        assert isinstance(sample_patient.medications, list)
        assert len(sample_patient.medications) == 2

    def test_patient_allergies_is_json(self, sample_patient):
        """Test that allergies field stores JSON data."""
        assert isinstance(sample_patient.allergies, list)
        assert "Penicillin" in sample_patient.allergies

    def test_patient_structured_profile_is_json(self, sample_patient):
        """Test that structured_profile field stores JSON data."""
        assert isinstance(sample_patient.structured_profile, dict)
        assert sample_patient.structured_profile["bmi"] == 28.5

    def test_patient_medical_history_is_text(self, sample_patient):
        """Test that medical_history field stores text."""
        assert isinstance(sample_patient.medical_history, str)
        assert "Type 2 Diabetes" in sample_patient.medical_history

    def test_patient_created_at_auto_set(self, db_session, sample_patient_data):
        """Test that created_at is automatically set."""
        patient = Patient(**sample_patient_data)
        db_session.add(patient)
        db_session.commit()
        db_session.refresh(patient)

        assert patient.created_at is not None
        assert isinstance(patient.created_at, datetime)

    def test_patient_updated_at_auto_set(self, db_session, sample_patient_data):
        """Test that updated_at is automatically set."""
        patient = Patient(**sample_patient_data)
        db_session.add(patient)
        db_session.commit()
        db_session.refresh(patient)

        assert patient.updated_at is not None
        assert isinstance(patient.updated_at, datetime)

    def test_patient_optional_fields_can_be_none(self, db_session):
        """Test that optional fields can be None."""
        patient = Patient(name="Jane Doe")
        db_session.add(patient)
        db_session.commit()
        db_session.refresh(patient)

        assert patient.date_of_birth is None
        assert patient.insurance_policy_number is None
        assert patient.insurer_name is None
        assert patient.diagnoses is None
        assert patient.medications is None
        assert patient.allergies is None
        assert patient.medical_history is None
        assert patient.structured_profile is None

    def test_patient_name_max_length(self, db_session, sample_patient_data):
        """Test patient name field accepts 255 characters."""
        sample_patient_data["name"] = "A" * 255
        patient = Patient(**sample_patient_data)
        db_session.add(patient)
        db_session.commit()
        assert patient.name == "A" * 255

    def test_patient_retrieval(self, db_session, sample_patient):
        """Test retrieving a patient from the database."""
        retrieved = (
            db_session.query(Patient).filter(Patient.id == sample_patient.id).first()
        )
        assert retrieved is not None
        assert retrieved.name == sample_patient.name
        assert (
            retrieved.insurance_policy_number == sample_patient.insurance_policy_number
        )

    def test_patient_update(self, db_session, sample_patient):
        """Test updating a patient record."""
        sample_patient.name = "John Smith"
        db_session.commit()
        db_session.refresh(sample_patient)

        assert sample_patient.name == "John Smith"

    def test_patient_delete(self, db_session, sample_patient):
        """Test deleting a patient record."""
        patient_id = sample_patient.id
        db_session.delete(sample_patient)
        db_session.commit()

        retrieved = db_session.query(Patient).filter(Patient.id == patient_id).first()
        assert retrieved is None

    def test_patient_default_empty_patient(self, db_session):
        """Test creating a patient with only required fields."""
        patient = Patient(name="Test Patient")
        db_session.add(patient)
        db_session.commit()
        db_session.refresh(patient)

        assert patient.id is not None
        assert patient.name == "Test Patient"
