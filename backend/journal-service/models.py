from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class MoodLevel(int, Enum):
    very_bad  = 1
    bad       = 2
    neutral   = 3
    good      = 4
    very_good = 5


# ── Journal Entry ────────────────────────────────────────────────────────────

class JournalEntryCreate(BaseModel):
    title: Optional[str] = None
    content: str
    tags: Optional[List[str]] = []
    is_private: bool = True


class JournalEntryUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None
    is_private: Optional[bool] = None


class JournalEntryResponse(BaseModel):
    id: str
    user_id: str
    title: Optional[str] = None
    content: str
    tags: List[str] = []
    is_private: bool = True
    sentiment_score: Optional[float] = None   # filled by AI pipeline later
    created_at: datetime
    updated_at: datetime


# ── Mood Check-in ─────────────────────────────────────────────────────────────

class MoodCheckinCreate(BaseModel):
    mood: MoodLevel
    note: Optional[str] = None
    date: str   # ISO date string e.g. "2024-05-12"


class MoodCheckinResponse(BaseModel):
    id: str
    user_id: str
    mood: int
    note: Optional[str] = None
    date: str
    created_at: datetime
