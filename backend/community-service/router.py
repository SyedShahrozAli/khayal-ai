"""
community-service routes — Port 8006

Posts:
  GET    /community/posts              → public feed (paginated, filterable by tag)
  POST   /community/posts              → create post (anonymous by default)
  GET    /community/posts/{id}         → get one post
  DELETE /community/posts/{id}         → delete own post
  POST   /community/posts/{id}/upvote  → upvote
  POST   /community/posts/{id}/flag    → report/flag

Comments:
  GET    /community/posts/{id}/comments        → list comments
  POST   /community/posts/{id}/comments        → add comment
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi import APIRouter, Depends, HTTPException, Query, status
from core.dependencies import get_current_user
from core.database import get_collection
from models import PostCreate, PostResponse, CommentCreate, CommentResponse
import crud
from typing import List, Optional

router = APIRouter(prefix="/community", tags=["community"])


# ── Posts ─────────────────────────────────────────────────────────────────────

@router.get("/posts", response_model=List[PostResponse])
async def list_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    tag: Optional[str] = Query(None),
    user: dict = Depends(get_current_user),
):
    col = get_collection("community_posts")
    skip = (page - 1) * page_size
    docs = await crud.list_posts(col, skip=skip, limit=page_size, tag=tag)
    return [PostResponse(**d) for d in docs]


@router.post("/posts", response_model=PostResponse, status_code=status.HTTP_201_CREATED)
async def create_post(body: PostCreate, user: dict = Depends(get_current_user)):
    col = get_collection("community_posts")
    data = body.model_dump()
    data["display_name"] = None if body.is_anonymous else user.get("email", "User")
    doc = await crud.create_post(col, user["uid"], data)
    return PostResponse(**doc)


@router.get("/posts/{post_id}", response_model=PostResponse)
async def get_post(post_id: str, user: dict = Depends(get_current_user)):
    col = get_collection("community_posts")
    doc = await crud.get_post(col, post_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Post not found.")
    return PostResponse(**doc)


@router.delete("/posts/{post_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_post(post_id: str, user: dict = Depends(get_current_user)):
    col = get_collection("community_posts")
    deleted = await crud.delete_post(col, user["uid"], post_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Post not found or not yours.")


@router.post("/posts/{post_id}/upvote", status_code=status.HTTP_200_OK)
async def upvote_post(post_id: str, user: dict = Depends(get_current_user)):
    col = get_collection("community_posts")
    ok = await crud.upvote_post(col, post_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Post not found.")
    return {"upvoted": True}


@router.post("/posts/{post_id}/flag", status_code=status.HTTP_200_OK)
async def flag_post(post_id: str, user: dict = Depends(get_current_user)):
    col = get_collection("community_posts")
    ok = await crud.flag_post(col, post_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Post not found.")
    return {"flagged": True}


# ── Comments ──────────────────────────────────────────────────────────────────

@router.get("/posts/{post_id}/comments", response_model=List[CommentResponse])
async def list_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    user: dict = Depends(get_current_user),
):
    col = get_collection("community_comments")
    skip = (page - 1) * page_size
    docs = await crud.list_comments(col, post_id, skip=skip, limit=page_size)
    return [CommentResponse(**d) for d in docs]


@router.post(
    "/posts/{post_id}/comments",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_comment(
    post_id: str,
    body: CommentCreate,
    user: dict = Depends(get_current_user),
):
    comments_col = get_collection("community_comments")
    posts_col    = get_collection("community_posts")
    data = body.model_dump()
    data["display_name"] = None if body.is_anonymous else user.get("email", "User")
    doc = await crud.create_comment(comments_col, posts_col, user["uid"], post_id, data)
    return CommentResponse(**doc)
