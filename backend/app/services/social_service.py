"""Social service — likes, comments, friends, and direct messages."""

from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from app.models.models import (
    User, CommunityPost, PostLike, PostComment,
    FriendRequest, FriendRelationship, DirectMessage,
)


def _time_ago(dt: datetime) -> str:
    delta = datetime.utcnow() - dt
    secs = delta.total_seconds()
    if secs < 60:
        return "Just now"
    if secs < 3600:
        return f"{int(secs // 60)}m ago"
    if secs < 86400:
        return f"{int(secs // 3600)}h ago"
    return f"{int(secs // 86400)}d ago"


# ---------------- Likes ----------------

def toggle_like(db: Session, user: User, post_id: int) -> dict:
    existing = db.query(PostLike).filter(
        PostLike.post_id == post_id, PostLike.user_id == user.id).first()
    if existing:
        db.delete(existing)
        db.commit()
        liked = False
    else:
        db.add(PostLike(post_id=post_id, user_id=user.id))
        db.commit()
        liked = True
    count = db.query(PostLike).filter(PostLike.post_id == post_id).count()
    return {"liked": liked, "likes": count}


# ---------------- Comments ----------------

def add_comment(db: Session, user: User, post_id: int, content: str) -> dict:
    c = PostComment(post_id=post_id, user_id=user.id, content=content)
    db.add(c)
    db.commit()
    db.refresh(c)
    return {
        "id": c.id,
        "nickname": user.nickname,
        "flag": user.nation_flag,
        "content": c.content,
        "time": _time_ago(c.created_at),
    }


def list_comments(db: Session, post_id: int) -> list[dict]:
    comments = (
        db.query(PostComment)
        .filter(PostComment.post_id == post_id)
        .order_by(PostComment.created_at.asc())
        .all()
    )
    out = []
    for c in comments:
        author = c.user
        out.append({
            "id": c.id,
            "nickname": author.nickname if author else "Traveller",
            "flag": author.nation_flag if author else "🌍",
            "content": c.content,
            "time": _time_ago(c.created_at),
        })
    return out


# ---------------- Friends ----------------

def _are_friends(db: Session, a: int, b: int) -> bool:
    return db.query(FriendRelationship).filter(
        or_(
            and_(FriendRelationship.user_id == a, FriendRelationship.friend_id == b),
            and_(FriendRelationship.user_id == b, FriendRelationship.friend_id == a),
        )
    ).first() is not None


def send_friend_request(db: Session, user: User, to_user_id: int) -> dict:
    if to_user_id == user.id:
        return {"ok": False, "reason": "cannot friend yourself"}
    if _are_friends(db, user.id, to_user_id):
        return {"ok": False, "reason": "already friends"}
    # Existing pending request either direction?
    existing = db.query(FriendRequest).filter(
        or_(
            and_(FriendRequest.from_user_id == user.id,
                 FriendRequest.to_user_id == to_user_id),
            and_(FriendRequest.from_user_id == to_user_id,
                 FriendRequest.to_user_id == user.id),
        ),
        FriendRequest.status == "pending",
    ).first()
    if existing:
        return {"ok": False, "reason": "request already pending"}
    req = FriendRequest(from_user_id=user.id, to_user_id=to_user_id,
                        status="pending")
    db.add(req)
    db.commit()
    return {"ok": True}


def incoming_requests(db: Session, user: User) -> list[dict]:
    reqs = db.query(FriendRequest).filter(
        FriendRequest.to_user_id == user.id,
        FriendRequest.status == "pending",
    ).all()
    out = []
    for r in reqs:
        sender = db.query(User).filter(User.id == r.from_user_id).first()
        if sender:
            out.append({
                "request_id": r.id,
                "user_id": sender.id,
                "nickname": sender.nickname,
                "flag": sender.nation_flag,
                "nationality": sender.nationality,
            })
    return out


def respond_friend_request(db: Session, user: User, request_id: int,
                           accept: bool) -> dict:
    req = db.query(FriendRequest).filter(
        FriendRequest.id == request_id,
        FriendRequest.to_user_id == user.id,
        FriendRequest.status == "pending",
    ).first()
    if not req:
        return {"ok": False, "reason": "request not found"}
    if accept:
        req.status = "accepted"
        # Create a single friendship row (a<->b).
        db.add(FriendRelationship(user_id=req.from_user_id,
                                  friend_id=req.to_user_id))
    else:
        req.status = "rejected"
    db.commit()
    return {"ok": True, "accepted": accept}


def list_friends(db: Session, user: User) -> list[dict]:
    rels = db.query(FriendRelationship).filter(
        or_(FriendRelationship.user_id == user.id,
            FriendRelationship.friend_id == user.id)
    ).all()
    friend_ids = set()
    for r in rels:
        friend_ids.add(r.friend_id if r.user_id == user.id else r.user_id)
    out = []
    for fid in friend_ids:
        f = db.query(User).filter(User.id == fid).first()
        if f:
            out.append({
                "user_id": f.id,
                "nickname": f.nickname,
                "flag": f.nation_flag,
                "nationality": f.nationality,
            })
    return out


def friend_status(db: Session, user: User, other_id: int) -> str:
    """Returns: 'self' | 'friends' | 'pending_out' | 'pending_in' | 'none'."""
    if other_id == user.id:
        return "self"
    if _are_friends(db, user.id, other_id):
        return "friends"
    out = db.query(FriendRequest).filter(
        FriendRequest.from_user_id == user.id,
        FriendRequest.to_user_id == other_id,
        FriendRequest.status == "pending").first()
    if out:
        return "pending_out"
    inc = db.query(FriendRequest).filter(
        FriendRequest.from_user_id == other_id,
        FriendRequest.to_user_id == user.id,
        FriendRequest.status == "pending").first()
    if inc:
        return "pending_in"
    return "none"


# ---------------- Direct Messages ----------------

def send_message(db: Session, user: User, to_user_id: int,
                 content: str) -> dict | None:
    # Allow messaging any user (guides, bookings, friends all work).
    recipient = db.query(User).filter(User.id == to_user_id).first()
    # Only block if the target user doesn't exist and isn't a mock/demo user.
    is_mock_user = 70000 <= to_user_id <= 99999
    if recipient is None and not is_mock_user:
        return None
    m = DirectMessage(from_user_id=user.id, to_user_id=to_user_id,
                      content=content)
    db.add(m)
    db.commit()
    db.refresh(m)
    return {
        "id": m.id,
        "from_me": True,
        "content": m.content,
        "time": _time_ago(m.created_at),
    }


def get_conversation(db: Session, user: User, other_id: int) -> list[dict]:
    msgs = db.query(DirectMessage).filter(
        or_(
            and_(DirectMessage.from_user_id == user.id,
                 DirectMessage.to_user_id == other_id),
            and_(DirectMessage.from_user_id == other_id,
                 DirectMessage.to_user_id == user.id),
        )
    ).order_by(DirectMessage.created_at.asc()).all()
    return [
        {
            "id": m.id,
            "from_me": m.from_user_id == user.id,
            "content": m.content,
            "time": _time_ago(m.created_at),
        }
        for m in msgs
    ]
