# backend/models/database.py
import json
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set")

# Supabase requires SSL. The ?sslmode=require in the URL handles psycopg2,
# but we also pass connect_args for robustness.
engine = create_engine(
    DATABASE_URL,
    connect_args={"sslmode": "require"} if "supabase.co" in DATABASE_URL else {},
    json_serializer=lambda obj: json.dumps(obj),
    json_deserializer=lambda obj: json.loads(obj),
    pool_pre_ping=True,   # detect stale connections
    pool_size=5,
    max_overflow=10,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()