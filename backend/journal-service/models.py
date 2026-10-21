from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


class EntryType(str, Enum):
    text = "text"
    voice = "voice"


class Language(str, Enum):
    en = "en"
    ur = "ur"
    romanized_ur = "romanized_ur"


class MoodLevel(int, Enum):
    very_bad  = 1
    bad       = 2
    neutral   = 3
    good      = 4
    very_good = 5


class SentimentScore(BaseModel):
    primary_emotion: Optional[str] = None
    confidence: Optional[float] = None
    emotion_scores: Optional[Dict[str, float]] = None


# ── Journal Entry ────────────────────────────────────────────────────────────

class JournalEntryCreate(BaseModel):
    title: Optional[str] = None
    content_text: str
    entry_type: EntryType = EntryType.text
    language: Language = Language.en
    tags: Optional[List[str]] = []
    is_draft: bool = False


class JournalEntryUpdate(BaseModel):
    title: Optional[str] = None
    content_text: Optional[str] = None
    entry_type: Optional[EntryType] = None
    language: Optional[Language] = None
    tags: Optional[List[str]] = None
    is_draft: Optional[bool] = None


class JournalEntryResponse(BaseModel):
    id: str
    user_id: str
    entry_type: str = "text"
    content_text: str
    title: Optional[str] = None
    language: str = "en"
    sentiment: Optional[SentimentScore] = None
    detected_keywords: List[str] = []
    tags: List[str] = []
    is_draft: bool = False
    is_deleted: bool = False
    created_at: datetime
    updated_at: datetime
    synced_at: Optional[datetime] = None


class JournalBatchSyncRequest(BaseModel):
    entries: List[JournalEntryResponse]


class JournalBatchSyncResponse(BaseModel):
    synced_count: int
    synced_ids: List[str]
    failed_ids: List[str] = []


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
