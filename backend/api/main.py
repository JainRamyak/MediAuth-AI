# backend/api/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes.authorization import router as authorization_router
from api.routes.prompts import router as prompts_router
from api.routes.auth import router as auth_router
from models.init_db import create_tables
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(
    title="MediAuth AI",
    description="Autonomous Insurance Authorization & Appeal Agent System",
    version="0.1.0"
)

# CORS — allow Flutter web and mobile to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create DB tables on startup
@app.on_event("startup")
def startup_event():
    create_tables()

# Register routers
app.include_router(auth_router)
app.include_router(authorization_router)
app.include_router(prompts_router)


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "MediAuth AI",
        "version": "0.1.0",
        "environment": os.getenv("ENVIRONMENT", "development")
    }

@app.get("/debug/versions")
def debug_versions():
    import bcrypt
    import passlib
    import hashlib
    try:
        bcrypt_ver = getattr(bcrypt, "__version__", "unknown")
    except:
        bcrypt_ver = "error"
        
    return {
        "bcrypt": bcrypt_ver,
        "passlib": passlib.__version__,
        "sha256_available": hashlib.sha256().name
    }