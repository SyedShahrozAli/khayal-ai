"""
journal-service CRUD — operates on `journal_entries` and `mood_checkins`.
All queries are scoped to the calling user's uid.
"""
from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List, Optional
import re


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _doc_to_dict(doc: dict) -> dict:
    """Convert MongoDB doc's _id ObjectId to str id and normalize fields."""
    if not doc:
        return {}
    if "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    # Backwards compatibility: if content was stored instead of content_text
    if "content" in doc and "content_text" not in doc:
        doc["content_text"] = doc.pop("content")
    if "entry_type" not in doc:
        doc["entry_type"] = "text"
    if "language" not in doc:
        doc["language"] = "en"
    if "is_draft" not in doc:
        doc["is_draft"] = False
    if "is_deleted" not in doc:
        doc["is_deleted"] = False
    return doc


def _extract_keywords(text: str) -> List[str]:
    """Basic NLP token extraction for emotional & cognitive tags."""
    if not text:
        return []
    words = re.findall(r'\b[a-zA-Z\u0600-\u06FF]{4,}\b', text.lower())
    stop_words = {"this", "that", "with", "have", "from", "they", "will", "would", "about", "there"}
    filtered = [w for w in set(words) if w not in stop_words]
    return filtered[:6]


# ── Journal Entries ───────────────────────────────────────────────────────────

async def list_entries(
    collection: AsyncIOMotorCollection,
    uid: str,
    skip: int = 0,
    limit: int = 20,
    entry_type: Optional[str] = None,
    language: Optional[str] = None,
) -> List[dict]:
    query: dict = {
        "user_id": uid,
        "is_deleted": {"$ne": True},
    }
    if entry_type:
        query["entry_type"] = entry_type
    if language:
        query["language"] = language

    cursor = collection.find(
        query,
        sort=[("created_at", -1)],
    ).skip(skip).limit(limit)
    return [_doc_to_dict(doc) async for doc in cursor]


async def get_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    entry_id: str,
) -> dict | None:
    try:
        oid = ObjectId(entry_id)
        doc = await collection.find_one({"_id": oid, "user_id": uid, "is_deleted": {"$ne": True}})
    except Exception:
        doc = await collection.find_one({"id": entry_id, "user_id": uid, "is_deleted": {"$ne": True}})
    return _doc_to_dict(doc) if doc else None


async def create_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    data: dict,
) -> dict:
    now = _now()
    text = data.get("content_text") or data.get("content", "")
    keywords = _extract_keywords(text)
    
    doc = {
        "user_id": uid,
        "entry_type": data.get("entry_type", "text"),
        "content_text": text,
        "title": data.get("title"),
        "language": data.get("language", "en"),
        "sentiment": data.get("sentiment"),
        "detected_keywords": keywords,
        "tags": data.get("tags", []),
        "is_draft": data.get("is_draft", False),
        "is_deleted": False,
        "created_at": now,
        "updated_at": now,
        "synced_at": now if not data.get("is_draft", False) else None,
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
    if "content_text" in clean:
        clean["detected_keywords"] = _extract_keywords(clean["content_text"])
    clean["updated_at"] = _now()
    
    try:
        oid = ObjectId(entry_id)
        match_query = {"_id": oid, "user_id": uid}
    except Exception:
        match_query = {"id": entry_id, "user_id": uid}

    await collection.update_one(
        match_query,
        {"$set": clean},
    )
    return await get_entry(collection, uid, entry_id)


async def delete_entry(
    collection: AsyncIOMotorCollection,
    uid: str,
    entry_id: str,
    soft_delete: bool = True,
) -> bool:
    try:
        oid = ObjectId(entry_id)
        match_query = {"_id": oid, "user_id": uid}
    except Exception:
        match_query = {"id": entry_id, "user_id": uid}

    if soft_delete:
        res = await collection.update_one(
            match_query,
            {"$set": {"is_deleted": True, "updated_at": _now()}},
        )
        return res.modified_count > 0
    else:
        result = await collection.delete_one(match_query)
        return result.deleted_count > 0


async def batch_sync_entries(
    collection: AsyncIOMotorCollection,
    uid: str,
    entries: List[dict],
) -> tuple[int, List[str], List[str]]:
    """Batch synchronizes offline drafts with MongoDB (REL-1)."""
    now = _now()
    synced_ids = []
    failed_ids = []

    for item in entries:
        try:
            entry_id = item.get("id")
            doc = {
                "user_id": uid,
                "entry_type": item.get("entry_type", "text"),
                "content_text": item.get("content_text", ""),
                "title": item.get("title"),
                "language": item.get("language", "en"),
                "sentiment": item.get("sentiment"),
                "detected_keywords": item.get("detected_keywords") or _extract_keywords(item.get("content_text", "")),
                "tags": item.get("tags", []),
                "is_draft": False,
                "is_deleted": item.get("is_deleted", False),
                "created_at": item.get("created_at") or now,
                "updated_at": now,
                "synced_at": now,
            }
            
            try:
                oid = ObjectId(entry_id)
                query = {"_id": oid, "user_id": uid}
            except Exception:
                query = {"id": entry_id, "user_id": uid}
                doc["id"] = entry_id

            await collection.update_one(
                query,
                {"$set": doc},
                upsert=True,
            )
            synced_ids.append(entry_id)
        except Exception:
            failed_ids.append(item.get("id", "unknown"))

    return len(synced_ids), synced_ids, failed_ids


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
