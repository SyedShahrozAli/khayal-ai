from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    appointment  = "appointment"
    message      = "message"
    community    = "community"
    system       = "system"
    reminder     = "reminder"


class NotificationCreate(BaseModel):
    user_id: str                              # recipient
    type: NotificationType
    title: str
    body: str
    data: Optional[dict] = {}                 # arbitrary extra payload


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    body: str
    data: dict = {}
    is_read: bool = False
    created_at: datetime                      # TTL index on this field (30 days)
