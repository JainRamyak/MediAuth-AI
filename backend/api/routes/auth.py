from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from models.database import get_db
from models.user import User
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta
import os
import hashlib

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = os.getenv("JWT_SECRET", "fallback-secret")
ALGORITHM = "HS256"
TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours


# ── Schemas ──────────────────────────────────────────
class RegisterRequest(BaseModel):
    full_name: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user_id: str
    full_name: str
    email: str


# ── Helpers ──────────────────────────────────────────
def hash_password(password: str) -> str:
    # Pre-hash with SHA256 to handle passwords > 72 chars (bcrypt limit)
    pwd_hash = hashlib.sha256(password.encode()).hexdigest()
    return pwd_context.hash(pwd_hash)

def verify_password(plain: str, hashed: str) -> bool:
    pwd_hash = hashlib.sha256(plain.encode()).hexdigest()
    return pwd_context.verify(pwd_hash, hashed)

def create_token(user_id: str, email: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": user_id, "email": email, "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM
    )


# ── Endpoints ─────────────────────────────────────────
@router.post("/register", response_model=TokenResponse)
def register(request: RegisterRequest, db: Session = Depends(get_db)):
    # Check if email already exists
    existing = db.query(User).filter(User.email == request.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        full_name=request.full_name,
        email=request.email,
        hashed_password=hash_password(request.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_token(str(user.id), user.email)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email
    )


@router.post("/login", response_model=TokenResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_token(str(user.id), user.email)
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user_id=str(user.id),
        full_name=user.full_name,
        email=user.email
    )


@router.get("/me")
def get_me(db: Session = Depends(get_db)):
    """Test endpoint — verify your token works."""
    return {"message": "Token valid. Auth system working."}

@router.get("/fix-db")
def fix_db(db: Session = Depends(get_db)):
    from sqlalchemy import text
    try:
        db.execute(text("DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;"))
        db.execute(text("DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;"))
        db.execute(text("DROP FUNCTION IF EXISTS public.handle_user_sync();"))
        db.execute(text("DROP TABLE IF EXISTS public.users CASCADE;"))
        db.commit()
        from models.init_db import create_tables
        create_tables()
        return {"success": True, "message": "Users table dropped and recreated via SQLAlchemy."}
    except Exception as e:
        db.rollback()
        return {"success": False, "error": str(e)}