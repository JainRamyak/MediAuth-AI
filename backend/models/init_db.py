from models.database import engine, Base
from models.patient import Patient
from models.auth_request import AuthRequest
from models.audit_log import AuditLog
from models.claim import Claim
from models.user import User 
def create_tables():
    Base.metadata.create_all(bind=engine)
    print("All tables created successfully.")

if __name__ == "__main__":
    create_tables()