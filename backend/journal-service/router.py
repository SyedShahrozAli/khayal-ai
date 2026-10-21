"""
journal-service routes — Port 8004

Journal entries:
  GET    /journal/entries              → list (paginated, with language/type filter)
  POST   /journal/entries              → create entry
  GET    /journal/entries/{id}         → get one
  PATCH  /journal/entries/{id}         → update entry
  DELETE /journal/entries/{id}         → soft delete
  POST   /journal/sync                 → batch sync offline drafts (REL-1)

Mood check-ins:
  GET    /journal/mood                 → list (paginated)
  POST   /journal/mood                 → create today's check-in
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, Query, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import (
    JournalEntryCreate, JournalEntryUpdate, JournalEntryResponse,
    JournalBatchSyncRequest, JournalBatchSyncResponse,
    MoodCheckinCreate, MoodCheckinResponse,
)
import crud
from typing import List, Optional

router = APIRouter(prefix="/journal", tags=["journal"])


# ── Journal Entries ───────────────────────────────────────────────────────────

@router.get("/entries", response_model=List[JournalEntryResponse])
async def list_entries(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    entry_type: Optional[str] = None,
    language: Optional[str] = None,
    user: dict = Depends(get_current_user),
):
    collection = get_collection("journal_entries")
    skip = (page - 1) * page_size
    docs = await crud.list_entries(
        collection, user["uid"], skip=skip, limit=page_size,
        entry_type=entry_type, language=language
    )
    return [JournalEntryResponse(**d) for d in docs]


@router.post("/entries", response_model=JournalEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_entry(
    body: JournalEntryCreate,
    user: dict = Depends(get_current_user),
):
    collection = get_collection("journal_entries")
    doc = await crud.create_entry(collection, user["uid"], body.model_dump())
    return JournalEntryResponse(**doc)


@router.get("/entries/{entry_id}", response_model=JournalEntryResponse)
async def get_entry(entry_id: str, user: dict = Depends(get_current_user)):
    collection = get_collection("journal_entries")
    doc = await crud.get_entry(collection, user["uid"], entry_id)
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found.")
    return JournalEntryResponse(**doc)


@router.patch("/entries/{entry_id}", response_model=JournalEntryResponse)
async def update_entry(
    entry_id: str,
    body: JournalEntryUpdate,
    user: dict = Depends(get_current_user),
):
    collection = get_collection("journal_entries")
    doc = await crud.update_entry(
        collection, user["uid"], entry_id, body.model_dump(exclude_unset=True)
    )
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found.")
    return JournalEntryResponse(**doc)


@router.delete("/entries/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_entry(
    entry_id: str,
    soft: bool = Query(True, description="Perform soft delete"),
    user: dict = Depends(get_current_user),
):
    collection = get_collection("journal_entries")
    deleted = await crud.delete_entry(collection, user["uid"], entry_id, soft_delete=soft)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found.")


@router.post("/sync", response_model=JournalBatchSyncResponse)
async def batch_sync(
    body: JournalBatchSyncRequest,
    user: dict = Depends(get_current_user),
):
    """Batch synchronizes offline journal drafts with MongoDB, ensuring zero data loss (REL-1)."""
    collection = get_collection("journal_entries")
    count, synced, failed = await crud.batch_sync_entries(
        collection, user["uid"], [e.model_dump() for e in body.entries]
    )
    return JournalBatchSyncResponse(
        synced_count=count,
        synced_ids=synced,
        failed_ids=failed,
    )


# ── Mood Check-ins ────────────────────────────────────────────────────────────

@router.get("/mood", response_model=List[MoodCheckinResponse])
async def list_mood_checkins(
    page: int = Query(1, ge=1),
    page_size: int = Query(30, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    collection = get_collection("mood_checkins")
    skip = (page - 1) * page_size
    docs = await crud.list_checkins(collection, user["uid"], skip=skip, limit=page_size)
    return [MoodCheckinResponse(**d) for d in docs]


@router.post("/mood", response_model=MoodCheckinResponse, status_code=status.HTTP_201_CREATED)
async def create_mood_checkin(
    body: MoodCheckinCreate,
    user: dict = Depends(get_current_user),
):
    collection = get_collection("mood_checkins")
    doc = await crud.create_checkin(collection, user["uid"], body.model_dump())
    return MoodCheckinResponse(**doc)
