"""
Auth service routes.

POST /auth/register  — called by Flutter on first sign-in to create a user doc
GET  /auth/me        — returns the current user's profile from MongoDB
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import UserResponse
import crud

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def register(user: dict = Depends(get_current_user)):
    """
    Upserts the user document in MongoDB using the Firebase JWT claims.
    Flutter should call this once after every successful Firebase sign-in.
    """
    collection = get_collection("users")
    doc = await crud.upsert_user(
        collection=collection,
        uid=user["uid"],
        email=user.get("email"),
        display_name=user.get("name"),
        photo_url=user.get("picture"),
    )
    return UserResponse(**doc)


@router.get("/me", response_model=UserResponse)
async def me(user: dict = Depends(get_current_user)):
    """Returns the authenticated user's MongoDB profile."""
    collection = get_collection("users")
    doc = await crud.get_user_by_uid(collection, user["uid"])
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found. Call POST /auth/register first.",
        )
    return UserResponse(**doc)
