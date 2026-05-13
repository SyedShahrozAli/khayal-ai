from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List


def _now(): return datetime.now(timezone.utc)

def _to_dict(doc):
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


async def ensure_ttl_index(col: AsyncIOMotorCollection):
    """Create TTL index on created_at — MongoDB auto-deletes docs after 30 days."""
    await col.create_index("created_at", expireAfterSeconds=30 * 24 * 3600)


async def create_notification(col: AsyncIOMotorCollection, data: dict) -> dict:
    now = _now()
    doc = {
        "user_id": data["user_id"],
        "type": data["type"],
        "title": data["title"],
        "body": data["body"],
        "data": data.get("data", {}),
        "is_read": False,
        "created_at": now,
    }
    result = await col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def list_notifications(
    col: AsyncIOMotorCollection, uid: str, skip=0, limit=30
) -> List[dict]:
    cursor = col.find(
        {"user_id": uid},
        sort=[("created_at", -1)],
    ).skip(skip).limit(limit)
    return [_to_dict(d) async for d in cursor]


async def mark_read(col: AsyncIOMotorCollection, notif_id: str, uid: str) -> bool:
    result = await col.update_one(
        {"_id": ObjectId(notif_id), "user_id": uid},
        {"$set": {"is_read": True}},
    )
    return result.modified_count > 0


async def mark_all_read(col: AsyncIOMotorCollection, uid: str) -> int:
    result = await col.update_many(
        {"user_id": uid, "is_read": False},
        {"$set": {"is_read": True}},
    )
    return result.modified_count


async def unread_count(col: AsyncIOMotorCollection, uid: str) -> int:
    return await col.count_documents({"user_id": uid, "is_read": False})
