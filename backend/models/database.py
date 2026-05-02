from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

import json
import psycopg2.extras
from psycopg2.extensions import register_adapter, AsIs

from sqlalchemy import create_engine, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import json, os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(
    DATABASE_URL,
    json_serializer=lambda obj: json.dumps(obj),   # ← ADD THIS
    json_deserializer=lambda obj: json.loads(obj),  # ← ADD THIS
)

# Tell psycopg2 how to serialize Python dicts and lists → JSON strings
psycopg2.extras.register_default_jsonb(globally=True)
psycopg2.extras.register_default_json(globally=True)
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()