from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI(
    title="MediAuth AI",
    description="Autonomous Insurance Authorization & Appeal Agent",
    version="0.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "MediAuth AI",
        "version": "0.1.0",
        "environment": os.getenv("ENVIRONMENT", "development")
    }