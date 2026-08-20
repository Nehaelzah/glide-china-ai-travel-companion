"""Radar (nearby tourists) service."""

import random
from datetime import datetime
from sqlalchemy.orm import Session

from app.models.models import User, RadarProfile
from app.schemas.schemas import RadarVisibilityRequest

COLORS = ["#06B6D4", "#10B981", "#14B8A6", "#F2A93B", "#7F9CF5", "#F472B6", "#A78BFA", "#FB923C"]


def _days_since(created_at) -> int:
    """Day of trip counted from registration date. Day 1 = signup day."""
    if not created_at:
        return 1
    return max(1, (datetime.utcnow().date() - created_at.date()).days + 1)


def get_or_create_radar_profile(db: Session, user: User) -> RadarProfile:
    profile = db.query(RadarProfile).filter(RadarProfile.user_id == user.id).first()
    if not profile:
        profile = RadarProfile(
            user_id=user.id,
            interests=random.sample(["Foodie", "Photography", "History", "Culture", "Hiking", "Music", "Tech", "Nature"], 3),
            languages=["English"],
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile


def update_radar_visibility(db: Session, user: User, data: RadarVisibilityRequest) -> RadarProfile:
    profile = get_or_create_radar_profile(db, user)
    updates = data.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(profile, key, value)
    db.commit()
    db.refresh(profile)
    return profile


def get_nearby_tourists(db: Session, user: User) -> list[dict]:
    """Return tourists who have show_on_radar=True, excluding current user."""
    profiles = (
        db.query(RadarProfile)
        .join(User)
        .filter(RadarProfile.user_id != user.id, RadarProfile.show_on_radar == True)
        .all()
    )
    result = []
    for i, rp in enumerate(profiles):
        u = rp.user
        if not u:
            continue
        result.append({
            "id": u.id,
            "nickname": u.nickname,
            "country": u.nationality,
            "flag": u.nation_flag,
            "days_in_china": _days_since(u.created_at),
            "distance_meters": random.randint(100, 2000),
            "languages": rp.languages or ["English"],
            "interests": rp.interests or [],
            "online": True,
            "avatar_color": COLORS[i % len(COLORS)],
            "dx": random.uniform(-0.6, 0.6),
            "dy": random.uniform(-0.5, 0.5),
        })
    return result
