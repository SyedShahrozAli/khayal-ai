from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# ── Posts ─────────────────────────────────────────────────────────────────────

class PostCreate(BaseModel):
    title: str
    content: str
    tags: Optional[List[str]] = []
    is_anonymous: bool = True   # default anonymous


class PostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None


class PostResponse(BaseModel):
    id: str
    author_id: str                      # uid — hidden from response if anonymous
    display_name: Optional[str] = None  # "Anonymous" when is_anonymous=True
    title: str
    content: str
    tags: List[str] = []
    is_anonymous: bool = True
    upvotes: int = 0
    comment_count: int = 0
    is_flagged: bool = False            # moderation
    created_at: datetime
    updated_at: datetime


# ── Comments ──────────────────────────────────────────────────────────────────

class CommentCreate(BaseModel):
    content: str
    is_anonymous: bool = True


class CommentResponse(BaseModel):
    id: str
    post_id: str
    author_id: str
    display_name: Optional[str] = None
    content: str
    is_anonymous: bool = True
    is_flagged: bool = False
    created_at: datetime
