"""
user-service routes — Port 8002
GET  /users/me         → return own profile
PATCH /users/me        → update own profile
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import ProfileUpdate, UserProfileResponse
import crud

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(user: dict = Depends(get_current_user)):
    """Returns the authenticated user's full profile."""
    collection = get_collection("users")
    doc = await crud.get_profile(collection, user["uid"])
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found. Call POST /auth/register first.",
        )
    return UserProfileResponse(**doc)


@router.patch("/me", response_model=UserProfileResponse)
async def update_my_profile(
    body: ProfileUpdate,
    user: dict = Depends(get_current_user),
):
    """Update mutable profile fields (display_name, bio, photo_url, etc.)."""
    collection = get_collection("users")
    updated = await crud.update_profile(
        collection,
        user["uid"],
        body.model_dump(exclude_unset=True),
    )
    if not updated:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
    return UserProfileResponse(**updated)
