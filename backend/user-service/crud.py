"""
user-service CRUD — reads/updates the `users` collection.
This service only touches the calling user's own document.
"""
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorCollection


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def get_profile(collection: AsyncIOMotorCollection, uid: str) -> dict | None:
    return await collection.find_one({"uid": uid}, {"_id": 0})


async def update_profile(
    collection: AsyncIOMotorCollection,
    uid: str,
    updates: dict,
) -> dict | None:
    updates["updated_at"] = _now()
    # Remove None values so we don't overwrite existing fields with null
    clean = {k: v for k, v in updates.items() if v is not None}
    await collection.update_one({"uid": uid}, {"$set": clean})
    return await get_profile(collection, uid)
