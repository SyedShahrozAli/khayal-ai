from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class AppointmentStatus(str, Enum):
    pending   = "pending"
    confirmed = "confirmed"
    cancelled = "cancelled"
    completed = "completed"


# ── Therapist Profile ─────────────────────────────────────────────────────────

class TherapistProfileCreate(BaseModel):
    specializations: List[str] = []
    bio: str
    license_number: str
    years_experience: int = 0
    languages: List[str] = ["English"]
    session_fee: float = 0.0
    currency: str = "USD"


class TherapistProfileResponse(BaseModel):
    uid: str
    specializations: List[str]
    bio: str
    license_number: str
    years_experience: int
    languages: List[str]
    session_fee: float
    currency: str
    is_verified: bool = False
    created_at: datetime
    updated_at: datetime


# ── Slots ─────────────────────────────────────────────────────────────────────

class SlotCreate(BaseModel):
    start_time: datetime    # ISO 8601 e.g. "2024-05-15T10:00:00Z"
    end_time: datetime
    is_available: bool = True


class SlotResponse(BaseModel):
    id: str
    therapist_id: str
    start_time: datetime
    end_time: datetime
    is_available: bool
    created_at: datetime


# ── Appointments ──────────────────────────────────────────────────────────────

class AppointmentCreate(BaseModel):
    therapist_id: str
    slot_id: str
    notes: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: str
    seeker_id: str
    therapist_id: str
    slot_id: str
    status: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class AppointmentStatusUpdate(BaseModel):
    status: AppointmentStatus
