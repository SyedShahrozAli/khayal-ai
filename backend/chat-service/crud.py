"""
chat-service CRUD — operates on `chat_sessions` and `chat_messages`.
All queries are scoped to the calling user's uid.
"""
from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _doc_to_dict(doc: dict) -> dict:
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


# ── Sessions ──────────────────────────────────────────────────────────────────

async def list_sessions(
    collection: AsyncIOMotorCollection,
    uid: str,
    skip: int = 0,
    limit: int = 20,
) -> List[dict]:
    cursor = collection.find(
        {"user_id": uid},
        sort=[("updated_at", -1)],
    ).skip(skip).limit(limit)
    return [_doc_to_dict(doc) async for doc in cursor]


async def get_session(
    collection: AsyncIOMotorCollection,
    uid: str,
    session_id: str,
) -> dict | None:
    doc = await collection.find_one({"_id": ObjectId(session_id), "user_id": uid})
    return _doc_to_dict(doc) if doc else None


async def create_session(
    collection: AsyncIOMotorCollection,
    uid: str,
    title: str,
) -> dict:
    now = _now()
    doc = {
        "user_id": uid,
        "title": title,
        "message_count": 0,
        "created_at": now,
        "updated_at": now,
    }
    result = await collection.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def delete_session(
    collection: AsyncIOMotorCollection,
    uid: str,
    session_id: str,
) -> bool:
    result = await collection.delete_one({"_id": ObjectId(session_id), "user_id": uid})
    return result.deleted_count > 0


# ── Messages ──────────────────────────────────────────────────────────────────

async def list_messages(
    messages_col: AsyncIOMotorCollection,
    sessions_col: AsyncIOMotorCollection,
    uid: str,
    session_id: str,
    skip: int = 0,
    limit: int = 50,
) -> List[dict]:
    # Verify session belongs to user
    session = await get_session(sessions_col, uid, session_id)
    if not session:
        return []
    cursor = messages_col.find(
        {"session_id": session_id, "user_id": uid},
        sort=[("created_at", 1)],
    ).skip(skip).limit(limit)
    return [_doc_to_dict(doc) async for doc in cursor]


async def add_message(
    messages_col: AsyncIOMotorCollection,
    sessions_col: AsyncIOMotorCollection,
    uid: str,
    session_id: str,
    role: str,
    content: str,
) -> dict:
    now = _now()
    doc = {
        "session_id": session_id,
        "user_id": uid,
        "role": role,
        "content": content,
        "created_at": now,
    }
    result = await messages_col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)

    # Update session's message_count and updated_at
    await sessions_col.update_one(
        {"_id": ObjectId(session_id), "user_id": uid},
        {"$inc": {"message_count": 1}, "$set": {"updated_at": now}},
    )
    return doc
