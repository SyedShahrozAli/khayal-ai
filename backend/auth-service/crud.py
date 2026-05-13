"""
Auth service CRUD — all operations against the `users` collection.
"""
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorCollection


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def get_user_by_uid(collection: AsyncIOMotorCollection, uid: str) -> dict | None:
    return await collection.find_one({"uid": uid})


async def create_user(
    collection: AsyncIOMotorCollection,
    uid: str,
    email: str | None,
    display_name: str | None,
    photo_url: str | None,
) -> dict:
    now = _now()
    doc = {
        "uid": uid,
        "email": email,
        "display_name": display_name,
        "photo_url": photo_url,
        "role": "seeker",
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }
    await collection.insert_one(doc)
    return doc


async def upsert_user(
    collection: AsyncIOMotorCollection,
    uid: str,
    email: str | None,
    display_name: str | None,
    photo_url: str | None,
) -> dict:
    """
    Create if new, or return existing. Updates email/display_name/photo_url
    if they have changed (e.g. user updated profile in Firebase).
    """
    existing = await get_user_by_uid(collection, uid)
    if existing:
        # Refresh mutable fields from Firebase claims
        update = {
            "email": email or existing.get("email"),
            "display_name": display_name or existing.get("display_name"),
            "photo_url": photo_url or existing.get("photo_url"),
            "updated_at": _now(),
        }
        await collection.update_one({"uid": uid}, {"$set": update})
        return {**existing, **update}

    return await create_user(collection, uid, email, display_name, photo_url)
