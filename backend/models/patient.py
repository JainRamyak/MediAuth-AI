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
    diagnoses = Column(JSON)
    medications = Column(JSON)
    allergies = Column(JSON)
    medical_history = Column(Text)
    structured_profile = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)