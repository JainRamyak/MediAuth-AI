import pytest
import sys
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from models.database import Base, get_db
from models.patient import Patient
from models.auth_request import AuthRequest
from models.audit_log import AuditLog
from models.claim import Claim


# Use SQLite for testing
TEST_DATABASE_URL = "sqlite:///./test.db"


@pytest.fixture(scope="function")
def engine():
    """Create a test database engine."""
    eng = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    yield eng
    Base.metadata.drop_all(bind=eng)


@pytest.fixture(scope="function")
def db_session(engine):
    """Create a test database session."""
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


@pytest.fixture(scope="function")
def client(db_session):
    """Create a FastAPI test client with overridden database dependency."""
    from api.main import app

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def sample_patient_data():
    """Sample patient data for testing."""
    return {
        "name": "John Doe",
        "date_of_birth": "1990-01-15",
        "insurance_policy_number": "POL-123456",
        "insurer_name": "BlueCross",
        "diagnoses": ["Type 2 Diabetes", "Hypertension"],
        "medications": ["Metformin 500mg", "Lisinopril 10mg"],
        "allergies": ["Penicillin"],
        "medical_history": "Patient has a history of Type 2 Diabetes for 5 years.",
        "structured_profile": {"bmi": 28.5, "blood_pressure": "140/90"},
    }


@pytest.fixture
def sample_patient(db_session, sample_patient_data):
    """Create a sample patient in the database."""
    patient = Patient(**sample_patient_data)
    db_session.add(patient)
    db_session.commit()
    db_session.refresh(patient)
    return patient


@pytest.fixture
def sample_auth_request(db_session, sample_patient):
    """Create a sample auth request in the database."""
    auth_request = AuthRequest(
        patient_id=sample_patient.id,
        status="pending",
        icd10_codes=[
            {
                "code": "E11.9",
                "description": "Type 2 diabetes mellitus without complications",
            }
        ],
        cpt_codes=[{"code": "99213", "description": "Office visit"}],
        clinical_summary="Patient requires continued treatment for Type 2 Diabetes.",
        justification_letter=None,
        denial_reason=None,
        appeal_level=0,
        insurer_response=None,
    )
    db_session.add(auth_request)
    db_session.commit()
    db_session.refresh(auth_request)
    return auth_request


@pytest.fixture
def sample_audit_log(db_session, sample_auth_request):
    """Create a sample audit log in the database."""
    audit_log = AuditLog(
        auth_request_id=sample_auth_request.id,
        agent_name="intake",
        action="Patient intake completed",
        input_data={"patient_input": "John Doe has diabetes"},
        output_data={"name": "John Doe", "diagnoses": ["Type 2 Diabetes"]},
        status="success",
        error_message=None,
    )
    db_session.add(audit_log)
    db_session.commit()
    db_session.refresh(audit_log)
    return audit_log


@pytest.fixture
def sample_claim(db_session, sample_auth_request):
    """Create a sample claim in the database."""
    claim = Claim(
        auth_request_id=sample_auth_request.id,
        billing_codes=[{"code": "99213", "type": "CPT"}],
        risk_score="LOW",
        risk_flags=[],
        status="pending_review",
        corrected_codes=None,
    )
    db_session.add(claim)
    db_session.commit()
    db_session.refresh(claim)
    return claim
