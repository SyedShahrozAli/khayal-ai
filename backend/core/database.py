from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorCollection
from .config import settings


class _Database:
    client: AsyncIOMotorClient | None = None


_db = _Database()


async def connect_db() -> None:
    """Call this in the FastAPI lifespan startup."""
    _db.client = AsyncIOMotorClient(settings.MONGODB_URI)
    # Ping to confirm connection
    await _db.client.admin.command("ping")
    print(f"[DB] Connected to MongoDB Atlas — '{settings.MONGODB_DB_NAME}'")


async def close_db() -> None:
    """Call this in the FastAPI lifespan shutdown."""
    if _db.client is not None:
        _db.client.close()
        print("[DB] MongoDB connection closed")


def get_collection(name: str) -> AsyncIOMotorCollection:
    """Return a Motor collection by name."""
    if _db.client is None:
        raise RuntimeError("Database not connected. Did you call connect_db()?")
    return _db.client[settings.MONGODB_DB_NAME][name]
