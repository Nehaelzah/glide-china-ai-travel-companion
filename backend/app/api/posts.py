"""Community post routes."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User
from app.services import posts_service
from app.services.auth_service import get_current_user_dependency

router = APIRouter(prefix="/api/posts", tags=["Posts"])


class CreatePostRequest(BaseModel):
    content: str = Field(default="", max_length=2000)
    image: str | None = None  # base64 image data


@router.post("/")
def create_post(
    req: CreatePostRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if not req.content.strip() and not req.image:
        raise HTTPException(status_code=400, detail="Post is empty")
    return posts_service.create_post(db, current_user, req.content, req.image)


@router.get("/")
def list_posts(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return posts_service.list_posts(db, current_user.id)


@router.get("/counts")
def post_counts(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    """Lightweight: just like/comment counts + liked state per post.
    Used for polling so the feed doesn't re-download images."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return posts_service.post_counts(db, current_user.id)


@router.delete("/{post_id}", status_code=204)
def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    ok = posts_service.delete_post(db, current_user, post_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Post not found")


@router.get("/user/{user_id}")
def user_posts(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    """Get all posts by a specific user."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return posts_service.user_posts(db, user_id, current_user.id)
