from sqlalchemy import Column, String, DateTime, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from models.database import Base
from datetime import datetime
import uuid

class AuditLog(Base):
    __tablename__ = "audit_logs"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    auth_request_id = Column(UUID(as_uuid=True), nullable=True)
    agent_name = Column(String(100))
    action = Column(String(255))
    input_data = Column(JSON)
    output_data = Column(JSON)
    status = Column(String(50))
    error_message = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)