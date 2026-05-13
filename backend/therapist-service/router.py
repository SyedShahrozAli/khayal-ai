"""
therapist-service routes — Port 8003

Therapist profile:
  GET    /therapists/                       → list all verified therapists
  POST   /therapists/profile                → create/update own therapist profile
  GET    /therapists/{uid}                  → get a specific therapist's profile

Availability slots (therapist manages their own):
  GET    /therapists/{uid}/slots            → list available slots for a therapist
  POST   /therapists/slots                  → add a slot (therapist only)

Appointments:
  POST   /therapists/appointments           → seeker books an appointment
  GET    /therapists/appointments/mine      → list own appointments (seeker or therapist)
  PATCH  /therapists/appointments/{id}/status → therapist updates status
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, Query, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import (
    TherapistProfileCreate, TherapistProfileResponse,
    SlotCreate, SlotResponse,
    AppointmentCreate, AppointmentResponse, AppointmentStatusUpdate,
)
import crud
from typing import List

router = APIRouter(prefix="/therapists", tags=["therapists"])


# ── Therapist Profile ─────────────────────────────────────────────────────────

@router.get("/", response_model=List[TherapistProfileResponse])
async def list_therapists(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    col = get_collection("therapists")
    skip = (page - 1) * page_size
    docs = await crud.list_therapists(col, skip=skip, limit=page_size)
    return [TherapistProfileResponse(**d) for d in docs]


@router.post("/profile", response_model=TherapistProfileResponse)
async def upsert_profile(body: TherapistProfileCreate, user: dict = Depends(get_current_user)):
    col = get_collection("therapists")
    doc = await crud.upsert_therapist(col, user["uid"], body.model_dump())
    return TherapistProfileResponse(**doc)


@router.get("/{uid}", response_model=TherapistProfileResponse)
async def get_therapist(uid: str, user: dict = Depends(get_current_user)):
    col = get_collection("therapists")
    doc = await crud.get_therapist(col, uid)
    if not doc:
        raise HTTPException(status_code=404, detail="Therapist not found.")
    return TherapistProfileResponse(**doc)


# ── Slots ─────────────────────────────────────────────────────────────────────

@router.get("/{uid}/slots", response_model=List[SlotResponse])
async def list_slots(
    uid: str,
    available_only: bool = Query(True),
    user: dict = Depends(get_current_user),
):
    col = get_collection("therapist_slots")
    docs = await crud.list_slots(col, therapist_id=uid, available_only=available_only)
    return [SlotResponse(**d) for d in docs]


@router.post("/slots", response_model=SlotResponse, status_code=status.HTTP_201_CREATED)
async def add_slot(body: SlotCreate, user: dict = Depends(get_current_user)):
    col = get_collection("therapist_slots")
    doc = await crud.create_slot(col, user["uid"], body.model_dump())
    return SlotResponse(**doc)


# ── Appointments ──────────────────────────────────────────────────────────────

@router.post("/appointments", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
async def book_appointment(body: AppointmentCreate, user: dict = Depends(get_current_user)):
    appts_col = get_collection("appointments")
    slots_col = get_collection("therapist_slots")
    doc = await crud.create_appointment(appts_col, slots_col, user["uid"], body.model_dump())
    return AppointmentResponse(**doc)


@router.get("/appointments/mine", response_model=List[AppointmentResponse])
async def my_appointments(
    role: str = Query("seeker", pattern="^(seeker|therapist)$"),
    user: dict = Depends(get_current_user),
):
    col = get_collection("appointments")
    docs = await crud.list_appointments(col, user["uid"], role)
    return [AppointmentResponse(**d) for d in docs]


@router.patch("/appointments/{appt_id}/status", response_model=AppointmentResponse)
async def update_status(
    appt_id: str,
    body: AppointmentStatusUpdate,
    user: dict = Depends(get_current_user),
):
    col = get_collection("appointments")
    doc = await crud.update_appointment_status(col, appt_id, body.status.value)
    if not doc:
        raise HTTPException(status_code=404, detail="Appointment not found.")
    return AppointmentResponse(**doc)
