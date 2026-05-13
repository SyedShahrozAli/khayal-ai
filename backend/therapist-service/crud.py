from datetime import datetime, timezone
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from typing import List


def _now(): return datetime.now(timezone.utc)

def _to_dict(doc):
    if doc and "_id" in doc:
        doc["id"] = str(doc.pop("_id"))
    return doc


# ── Therapist Profile ─────────────────────────────────────────────────────────

async def get_therapist(col: AsyncIOMotorCollection, uid: str) -> dict | None:
    doc = await col.find_one({"uid": uid})
    return _to_dict(doc) if doc else None


async def upsert_therapist(col: AsyncIOMotorCollection, uid: str, data: dict) -> dict:
    now = _now()
    data["uid"] = uid
    data["updated_at"] = now
    existing = await get_therapist(col, uid)
    if existing:
        await col.update_one({"uid": uid}, {"$set": data})
        return {**existing, **data}
    data["is_verified"] = False
    data["created_at"] = now
    await col.insert_one(data)
    data.pop("_id", None)
    return data


async def list_therapists(col: AsyncIOMotorCollection, skip=0, limit=20) -> List[dict]:
    cursor = col.find({"is_verified": True}, sort=[("created_at", -1)]).skip(skip).limit(limit)
    return [_to_dict(d) async for d in cursor]


# ── Slots ─────────────────────────────────────────────────────────────────────

async def create_slot(col: AsyncIOMotorCollection, therapist_id: str, data: dict) -> dict:
    now = _now()
    doc = {
        "therapist_id": therapist_id,
        "start_time": data["start_time"],
        "end_time": data["end_time"],
        "is_available": True,
        "created_at": now,
    }
    result = await col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


async def list_slots(col: AsyncIOMotorCollection, therapist_id: str, available_only=True) -> List[dict]:
    query = {"therapist_id": therapist_id}
    if available_only:
        query["is_available"] = True
    cursor = col.find(query, sort=[("start_time", 1)])
    return [_to_dict(d) async for d in cursor]


async def mark_slot_unavailable(col: AsyncIOMotorCollection, slot_id: str) -> bool:
    result = await col.update_one(
        {"_id": ObjectId(slot_id)}, {"$set": {"is_available": False}}
    )
    return result.modified_count > 0


# ── Appointments ──────────────────────────────────────────────────────────────

async def create_appointment(
    appts_col, slots_col, seeker_id: str, data: dict
) -> dict:
    now = _now()
    doc = {
        "seeker_id": seeker_id,
        "therapist_id": data["therapist_id"],
        "slot_id": data["slot_id"],
        "status": "pending",
        "notes": data.get("notes"),
        "created_at": now,
        "updated_at": now,
    }
    result = await appts_col.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    # Mark slot as booked
    await mark_slot_unavailable(slots_col, data["slot_id"])
    return doc


async def list_appointments(col: AsyncIOMotorCollection, uid: str, role: str) -> List[dict]:
    key = "seeker_id" if role == "seeker" else "therapist_id"
    cursor = col.find({key: uid}, sort=[("created_at", -1)])
    return [_to_dict(d) async for d in cursor]


async def update_appointment_status(
    col: AsyncIOMotorCollection, appt_id: str, status: str
) -> dict | None:
    await col.update_one(
        {"_id": ObjectId(appt_id)},
        {"$set": {"status": status, "updated_at": _now()}},
    )
    doc = await col.find_one({"_id": ObjectId(appt_id)})
    return _to_dict(doc) if doc else None
