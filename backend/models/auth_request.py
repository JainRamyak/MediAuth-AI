from sqlalchemy import Column, String, DateTime, Text, Integer, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class AuthRequest(Base):
    __tablename__ = "auth_requests"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.id"), nullable=False)
    user_id = Column(UUID(as_uuid=True), nullable=True)
    status = Column(String(50), default="pending")
    requested_treatment = Column(Text, nullable=True)
    icd10_codes = Column(JSON)
    cpt_codes = Column(JSON)
    clinical_summary = Column(Text)
    justification_letter = Column(Text)
    denial_reason = Column(Text)
    appeal_level = Column(Integer, default=0)
    insurer_response = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)