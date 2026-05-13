"""therapist-service — Port 8003"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.database import connect_db, close_db
from core.firebase import init_firebase
from router import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    await connect_db()
    yield
    await close_db()


app = FastAPI(title="Khayal AI — Therapist Service", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
app.include_router(router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "therapist-service"}
