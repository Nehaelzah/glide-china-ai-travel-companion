"""Social routes — likes, comments, friends, direct messages."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User
from app.services import social_service
from app.services.auth_service import get_current_user_dependency

router = APIRouter(prefix="/api/social", tags=["Social"])


def _auth(user):
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")


# ---------- Likes ----------

@router.post("/posts/{post_id}/like")
def toggle_like(post_id: int, db: Session = Depends(get_db),
                user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.toggle_like(db, user, post_id)


# ---------- Comments ----------

class CommentRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)


@router.post("/posts/{post_id}/comments")
def add_comment(post_id: int, req: CommentRequest,
                db: Session = Depends(get_db),
                user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.add_comment(db, user, post_id, req.content)


@router.get("/posts/{post_id}/comments")
def list_comments(post_id: int, db: Session = Depends(get_db),
                  user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.list_comments(db, post_id)


# ---------- Friends ----------

@router.post("/friends/request/{to_user_id}")
def send_request(to_user_id: int, db: Session = Depends(get_db),
                 user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.send_friend_request(db, user, to_user_id)


@router.get("/friends/requests")
def incoming(db: Session = Depends(get_db),
             user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.incoming_requests(db, user)


@router.post("/friends/respond/{request_id}")
def respond(request_id: int, accept: bool,
            db: Session = Depends(get_db),
            user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.respond_friend_request(db, user, request_id, accept)


@router.get("/friends")
def friends(db: Session = Depends(get_db),
            user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.list_friends(db, user)


@router.get("/friends/status/{other_id}")
def status(other_id: int, db: Session = Depends(get_db),
           user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return {"status": social_service.friend_status(db, user, other_id)}


# ---------- Direct Messages ----------

class MessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)


@router.post("/messages/{to_user_id}")
def send_message(to_user_id: int, req: MessageRequest,
                 db: Session = Depends(get_db),
                 user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    result = social_service.send_message(db, user, to_user_id, req.content)
    if result is None:
        raise HTTPException(status_code=403, detail="You can only message friends")
    return result


@router.get("/messages/{other_id}")
def get_conversation(other_id: int, db: Session = Depends(get_db),
                     user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    return social_service.get_conversation(db, user, other_id)
