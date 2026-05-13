from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime


class ProfileUpdate(BaseModel):
    """Fields the user is allowed to update on their own profile."""
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    bio: Optional[str] = None
    date_of_birth: Optional[str] = None  # ISO date string e.g. "1995-06-15"
    gender: Optional[str] = None         # "male" | "female" | "non_binary" | "prefer_not_to_say"


class UserProfileResponse(BaseModel):
    uid: str
    email: Optional[str] = None
    display_name: Optional[str] = None
    photo_url: Optional[str] = None
    bio: Optional[str] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    role: str = "seeker"
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
