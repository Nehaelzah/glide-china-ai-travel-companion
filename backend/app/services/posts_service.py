"""Community posts service — create, list, delete posts."""

from datetime import datetime
from sqlalchemy.orm import Session

from app.models.models import CommunityPost, PostLike, PostComment, User


def _time_ago(dt: datetime) -> str:
    """Human-friendly relative time."""
    delta = datetime.utcnow() - dt
    secs = delta.total_seconds()
    if secs < 60:
        return "Just now"
    if secs < 3600:
        return f"{int(secs // 60)}m ago"
    if secs < 86400:
        return f"{int(secs // 3600)}h ago"
    return f"{int(secs // 86400)}d ago"


def create_post(db: Session, user: User, content: str,
                image_b64: str | None) -> dict:
    post = CommunityPost(
        user_id=user.id,
        content=content,
        image_url=image_b64,
    )
    db.add(post)
    db.commit()
    db.refresh(post)
    return _post_to_dict(db, post, user.id)


def list_posts(db: Session, current_user_id: int) -> list[dict]:
    """All posts, newest first, with like/comment counts and whether the
    current user has liked each. Pads with mock examples when empty."""
    posts = (
        db.query(CommunityPost)
        .order_by(CommunityPost.created_at.desc())
        .limit(100)
        .all()
    )
    result = [_post_to_dict(db, p, current_user_id) for p in posts]
    # Seed mock example posts when the feed is empty so new users see content
    if len(result) < 2:
        mock_posts = [
            {
                "id": -1,
                "user_id": 80001,
                "nickname": "Sakura",
                "flag": "\U0001f1ef\U0001f1f5",
                "content": "Just arrived in Shanghai! The Bund at night is absolutely stunning. \U0001f303 Anyone want to grab dinner tomorrow? I'm looking for some authentic local food recommendations!",
                "image": None,
                "time": "2h ago",
                "likes": 12,
                "comment_count": 4,
                "liked": False,
                "is_mine": False,
            },
            {
                "id": -2,
                "user_id": 80002,
                "nickname": "Marco",
                "flag": "\U0001f1ee\U0001f1f9",
                "content": "Tried authentic Peking duck today \U0001f357\ufe0f Life changing! Does anyone know where to get good espresso in the hutongs? Also looking for a guide to the Great Wall next week.",
                "image": None,
                "time": "5h ago",
                "likes": 24,
                "comment_count": 8,
                "liked": False,
                "is_mine": False,
            },
            {
                "id": -3,
                "user_id": 80003,
                "nickname": "Emma",
                "flag": "\U0001f1ec\U0001f1e7",
                "content": "Lost my metro card at Jing'an Temple station. Has anyone found it? It's a blue physical card. Also, the subway system here is incredibly efficient! \U0001f687",
                "image": None,
                "time": "1d ago",
                "likes": 7,
                "comment_count": 3,
                "liked": False,
                "is_mine": False,
            },
        ]
        existing_ids = {p["id"] for p in result}
        for mp in mock_posts:
            if mp["id"] not in existing_ids:
                result.append(mp)
    return result


def delete_post(db: Session, user: User, post_id: int) -> bool:
    post = db.query(CommunityPost).filter(
        CommunityPost.id == post_id,
        CommunityPost.user_id == user.id,  # only your own
    ).first()
    if not post:
        return False
    # Clean up likes & comments for this post.
    db.query(PostLike).filter(PostLike.post_id == post_id).delete()
    db.query(PostComment).filter(PostComment.post_id == post_id).delete()
    db.delete(post)
    db.commit()
    return True


def post_counts(db: Session, current_user_id: int) -> list[dict]:
    """Lightweight counts for polling — no images, no content, just numbers."""
    posts = (
        db.query(CommunityPost)
        .order_by(CommunityPost.created_at.desc())
        .limit(100)
        .all()
    )
    out = []
    for p in posts:
        like_count = db.query(PostLike).filter(PostLike.post_id == p.id).count()
        comment_count = db.query(PostComment).filter(
            PostComment.post_id == p.id).count()
        liked = db.query(PostLike).filter(
            PostLike.post_id == p.id,
            PostLike.user_id == current_user_id,
        ).first() is not None
        out.append({
            "id": p.id,
            "likes": like_count,
            "comment_count": comment_count,
            "liked": liked,
        })
    return out


def user_posts(db: Session, target_user_id: int, current_user_id: int) -> list[dict]:
    """All posts by a specific user, newest first."""
    posts = (
        db.query(CommunityPost)
        .filter(CommunityPost.user_id == target_user_id)
        .order_by(CommunityPost.created_at.desc())
        .limit(50)
        .all()
    )
    return [_post_to_dict(db, p, current_user_id) for p in posts]


def _post_to_dict(db: Session, post: CommunityPost, current_user_id: int) -> dict:
    author = post.user
    like_count = db.query(PostLike).filter(PostLike.post_id == post.id).count()
    comment_count = db.query(PostComment).filter(
        PostComment.post_id == post.id).count()
    liked = db.query(PostLike).filter(
        PostLike.post_id == post.id,
        PostLike.user_id == current_user_id,
    ).first() is not None
    return {
        "id": post.id,
        "user_id": post.user_id,
        "nickname": author.nickname if author else "Traveller",
        "flag": author.nation_flag if author else "🌍",
        "content": post.content,
        "image": post.image_url,
        "time": _time_ago(post.created_at),
        "likes": like_count,
        "comment_count": comment_count,
        "liked": liked,
        "is_mine": post.user_id == current_user_id,
    }
