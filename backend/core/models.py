from pydantic import BaseModel, Field, ConfigDict
from bson import ObjectId
from typing import Any


class PyObjectId(str):
    """Custom type that serialises MongoDB ObjectId as a plain string."""

    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v: Any) -> str:
        if isinstance(v, ObjectId):
            return str(v)
        if isinstance(v, str) and ObjectId.is_valid(v):
            return v
        raise ValueError(f"Invalid ObjectId: {v!r}")


class BaseDocument(BaseModel):
    """Base model for all MongoDB documents returned from the API."""
    model_config = ConfigDict(
        populate_by_name=True,
        arbitrary_types_allowed=True,
    )

    id: PyObjectId | None = Field(default=None, alias="_id")


class ErrorResponse(BaseModel):
    detail: str
