"""notification-service — Port 8007"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.database import connect_db, close_db
from core.firebase import init_firebase
from core.database import get_collection
from router import router
import crud


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    await connect_db()
    # Ensure 30-day TTL index exists on startup
    await crud.ensure_ttl_index(get_collection("notifications"))
    yield
    await close_db()


app = FastAPI(title="Khayal AI — Notification Service", version="1.0.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
app.include_router(router)

@app.get("/health")
async def health():
    return {"status": "ok", "service": "notification-service"}
