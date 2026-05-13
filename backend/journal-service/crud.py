"""
journal-service CRUD — operates on `journal_entries` and `mood_checkins`.
All queries are scoped to the calling user's uid.
"""
from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _doc_to_dict(doc: dict) -> dict:
    """Convert MongoDB doc's _id ObjectId to str id."""
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


# ── Journal Entries ───────────────────────────────────────────────────────────

async def list_entries(
    collection: AsyncIOMotorCollection,
    uid: str,
    skip: int = 0,
    limit: int = 20,
) -> List[dict]:
    cursor = collection.find(
        {"user_id": uid},
        sort=[("created_at", -1)],
    ).skip(skip).limit(limit)
    return [_doc_to_dict(doc) async for doc in cursor]


async def get_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    entry_id: str,
) -> dict | None:
    doc = await collection.find_one({"_id": ObjectId(entry_id), "user_id": uid})
    return _doc_to_dict(doc) if doc else None


async def create_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    data: dict,
) -> dict:
    now = _now()
    doc = {
        "user_id": uid,
        "title": data.get("title"),
        "content": data["content"],
        "tags": data.get("tags", []),
        "is_private": data.get("is_private", True),
        "sentiment_score": None,
        "created_at": now,
        "updated_at": now,
    }
    result = await collection.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def update_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    entry_id: str,
    data: dict,
) -> dict | None:
    clean = {k: v for k, v in data.items() if v is not None}
    clean["updated_at"] = _now()
    await collection.update_one(
        {"_id": ObjectId(entry_id), "user_id": uid},
        {"$set": clean},
    )
    return await get_entry(collection, uid, entry_id)


async def delete_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    entry_id: str,
) -> bool:
    result = await collection.delete_one({"_id": ObjectId(entry_id), "user_id": uid})
    return result.deleted_count > 0


# ── Mood Check-ins ────────────────────────────────────────────────────────────

async def create_checkin(
    collection: AsyncIOMotorCollection,
    uid: str,
    data: dict,
) -> dict:
    now = _now()
    doc = {
        "user_id": uid,
        "mood": data["mood"],
        "note": data.get("note"),
        "date": data["date"],
        "created_at": now,
    }
    result = await collection.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def list_checkins(
    collection: AsyncIOMotorCollection,
    uid: str,
    skip: int = 0,
    limit: int = 30,
) -> List[dict]:
    cursor = collection.find(
        {"user_id": uid},
        sort=[("date", -1)],
    ).skip(skip).limit(limit)
    return [_doc_to_dict(doc) async for doc in cursor]
