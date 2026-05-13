"""
chat-service routes — Port 8005

Sessions:
  GET    /chat/sessions              → list sessions
  POST   /chat/sessions              → create session
  GET    /chat/sessions/{id}         → get session
  DELETE /chat/sessions/{id}         → delete session + messages

Messages:
  GET    /chat/sessions/{id}/messages        → paginated messages
  POST   /chat/sessions/{id}/messages        → add a message
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, Query, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import (
    ChatSessionCreate, ChatSessionResponse,
    ChatMessageCreate, ChatMessageResponse, PaginatedMessages,
)
import crud
from typing import List

router = APIRouter(prefix="/chat", tags=["chat"])


# ── Sessions ──────────────────────────────────────────────────────────────────

@router.get("/sessions", response_model=List[ChatSessionResponse])
async def list_sessions(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    user: dict = Depends(get_current_user),
):
    sessions_col = get_collection("chat_sessions")
    skip = (page - 1) * page_size
    docs = await crud.list_sessions(sessions_col, user["uid"], skip=skip, limit=page_size)
    return [ChatSessionResponse(**d) for d in docs]


@router.post("/sessions", response_model=ChatSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    body: ChatSessionCreate,
    user: dict = Depends(get_current_user),
):
    sessions_col = get_collection("chat_sessions")
    doc = await crud.create_session(sessions_col, user["uid"], body.title)
    return ChatSessionResponse(**doc)


@router.get("/sessions/{session_id}", response_model=ChatSessionResponse)
async def get_session(session_id: str, user: dict = Depends(get_current_user)):
    sessions_col = get_collection("chat_sessions")
    doc = await crud.get_session(sessions_col, user["uid"], session_id)
    if not doc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    return ChatSessionResponse(**doc)


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(session_id: str, user: dict = Depends(get_current_user)):
    sessions_col = get_collection("chat_sessions")
    messages_col = get_collection("chat_messages")
    deleted = await crud.delete_session(sessions_col, user["uid"], session_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    # Also purge messages for this session
    await messages_col.delete_many({"session_id": session_id, "user_id": user["uid"]})


# ── Messages ──────────────────────────────────────────────────────────────────

@router.get("/sessions/{session_id}/messages", response_model=PaginatedMessages)
async def list_messages(
    session_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    user: dict = Depends(get_current_user),
):
    sessions_col = get_collection("chat_sessions")
    messages_col = get_collection("chat_messages")
    skip = (page - 1) * page_size
    docs = await crud.list_messages(
        messages_col, sessions_col, user["uid"], session_id, skip=skip, limit=page_size
    )
    total = await messages_col.count_documents({"session_id": session_id, "user_id": user["uid"]})
    return PaginatedMessages(
        messages=[ChatMessageResponse(**d) for d in docs],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post(
    "/sessions/{session_id}/messages",
    response_model=ChatMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_message(
    session_id: str,
    body: ChatMessageCreate,
    user: dict = Depends(get_current_user),
):
    sessions_col = get_collection("chat_sessions")
    messages_col = get_collection("chat_messages")
    # Verify session ownership
    session = await crud.get_session(sessions_col, user["uid"], session_id)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    doc = await crud.add_message(
        messages_col, sessions_col, user["uid"], session_id, body.role.value, body.content
    )
    return ChatMessageResponse(**doc)
