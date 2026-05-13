from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    """Sent by the client on first login to register the user."""
    uid: str
    email: Optional[EmailStr] = None
    display_name: Optional[str] = None
    photo_url: Optional[str] = None


class UserResponse(BaseModel):
    """Returned to the client after registration or profile fetch."""
    uid: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    role: str = "seeker"          # "seeker" | "therapist" | "admin"
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
