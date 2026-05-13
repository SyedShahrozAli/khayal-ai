from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class MessageRole(str, Enum):
    user      = "user"
    assistant = "assistant"
    system    = "system"


# ── Chat Session ──────────────────────────────────────────────────────────────

class ChatSessionCreate(BaseModel):
    title: Optional[str] = "New Chat"


class ChatSessionResponse(BaseModel):
    id: str
    user_id: str
    title: str
    message_count: int = 0
    created_at: datetime
    updated_at: datetime


# ── Chat Message ──────────────────────────────────────────────────────────────

class ChatMessageCreate(BaseModel):
    role: MessageRole
    content: str


class ChatMessageResponse(BaseModel):
    id: str
    session_id: str
    user_id: str
    role: str
    content: str
    created_at: datetime


# ── Paginated response ────────────────────────────────────────────────────────

class PaginatedMessages(BaseModel):
    messages: List[ChatMessageResponse]
    total: int
    page: int
    page_size: int
