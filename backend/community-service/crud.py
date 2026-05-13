from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List


def _now(): return datetime.now(timezone.utc)

def _to_dict(doc):
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


# ── Posts ─────────────────────────────────────────────────────────────────────

async def list_posts(col: AsyncIOMotorCollection, skip=0, limit=20, tag=None) -> List[dict]:
    query = {"is_flagged": False}
    if tag:
        query["tags"] = tag
    cursor = col.find(query, sort=[("created_at", -1)]).skip(skip).limit(limit)
    return [_to_dict(d) async for d in cursor]


async def get_post(col: AsyncIOMotorCollection, post_id: str) -> dict | None:
    doc = await col.find_one({"_id": ObjectId(post_id), "is_flagged": False})
    return _to_dict(doc) if doc else None


async def create_post(col: AsyncIOMotorCollection, uid: str, data: dict) -> dict:
    now = _now()
    doc = {
        "author_id": uid,
        "display_name": None if data.get("is_anonymous", True) else data.get("display_name"),
        "title": data["title"],
        "content": data["content"],
        "tags": data.get("tags", []),
        "is_anonymous": data.get("is_anonymous", True),
        "upvotes": 0,
        "comment_count": 0,
        "is_flagged": False,
        "created_at": now,
        "updated_at": now,
    }
    result = await col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def upvote_post(col: AsyncIOMotorCollection, post_id: str) -> bool:
    result = await col.update_one(
        {"_id": ObjectId(post_id)}, {"$inc": {"upvotes": 1}}
    )
    return result.modified_count > 0


async def flag_post(col: AsyncIOMotorCollection, post_id: str) -> bool:
    result = await col.update_one(
        {"_id": ObjectId(post_id)}, {"$set": {"is_flagged": True}}
    )
    return result.modified_count > 0


async def delete_post(col: AsyncIOMotorCollection, uid: str, post_id: str) -> bool:
    result = await col.delete_one({"_id": ObjectId(post_id), "author_id": uid})
    return result.deleted_count > 0


# ── Comments ──────────────────────────────────────────────────────────────────

async def list_comments(col: AsyncIOMotorCollection, post_id: str, skip=0, limit=50) -> List[dict]:
    cursor = col.find(
        {"post_id": post_id, "is_flagged": False},
        sort=[("created_at", 1)],
    ).skip(skip).limit(limit)
    return [_to_dict(d) async for d in cursor]


async def create_comment(
    comments_col, posts_col, uid: str, post_id: str, data: dict
) -> dict:
    now = _now()
    doc = {
        "post_id": post_id,
        "author_id": uid,
        "display_name": None if data.get("is_anonymous", True) else data.get("display_name"),
        "content": data["content"],
        "is_anonymous": data.get("is_anonymous", True),
        "is_flagged": False,
        "created_at": now,
    }
    result = await comments_col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    await posts_col.update_one({"_id": ObjectId(post_id)}, {"$inc": {"comment_count": 1}})
    return doc
