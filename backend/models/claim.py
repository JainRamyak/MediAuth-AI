from sqlalchemy import Column, String, DateTime, Text, JSON, Float
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class Claim(Base):
    __tablename__ = "claims"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth_request_id = Column(UUID(as_uuid=True), nullable=False)
    billing_codes = Column(JSON)
    risk_score = Column(String(10))
    risk_flags = Column(JSON)
    status = Column(String(50), default="pending_review")
    corrected_codes = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)