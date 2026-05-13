"""
notification-service routes — Port 8007

GET    /notifications/              → list own notifications (paginated)
GET    /notifications/unread-count  → count of unread notifications
POST   /notifications/              → create a notification (internal/admin use)
PATCH  /notifications/{id}/read     → mark one as read
PATCH  /notifications/read-all      → mark all as read
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, Query, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import NotificationCreate, NotificationResponse
import crud
from typing import List

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/", response_model=List[NotificationResponse])
async def list_notifications(
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    col = get_collection("notifications")
    skip = (page - 1) * page_size
    docs = await crud.list_notifications(col, user["uid"], skip=skip, limit=page_size)
    return [NotificationResponse(**d) for d in docs]


@router.get("/unread-count")
async def unread_count(user: dict = Depends(get_current_user)):
    col = get_collection("notifications")
    count = await crud.unread_count(col, user["uid"])
    return {"unread_count": count}


@router.post("/", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
async def create_notification(
    body: NotificationCreate,
    user: dict = Depends(get_current_user),   # could add admin check here
):
    col = get_collection("notifications")
    doc = await crud.create_notification(col, body.model_dump())
    return NotificationResponse(**doc)


@router.patch("/{notif_id}/read", status_code=status.HTTP_200_OK)
async def mark_read(notif_id: str, user: dict = Depends(get_current_user)):
    col = get_collection("notifications")
    ok = await crud.mark_read(col, notif_id, user["uid"])
    if not ok:
        raise HTTPException(status_code=404, detail="Notification not found.")
    return {"marked_read": True}


@router.patch("/read-all", status_code=status.HTTP_200_OK)
async def mark_all_read(user: dict = Depends(get_current_user)):
    col = get_collection("notifications")
    count = await crud.mark_all_read(col, user["uid"])
    return {"marked_read_count": count}
