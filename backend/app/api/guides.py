"""Insider routes — registration, verification, availability, jobs."""

import re
import random
import logging
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import (
    User, RadarProfile, GuideProfile, GuideAvailability, GuideJob,
)
from app.services.auth_service import get_current_user_dependency

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/guides", tags=["Guides"])


def _auth(user):
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")


# ---------------- Registration ----------------

class GuideRegisterRequest(BaseModel):
    china_id: str = Field(..., description="Chinese citizenship ID")
    id_front: str | None = None   # base64
    id_back: str | None = None    # base64
    languages: list[dict] = []    # [{"language": "English", "level": "Native"}]
    cert_uploaded: str | None = None
    interests: list[str] = []
    accepted_terms: bool = False


@router.post("/register")
def register_guide(req: GuideRegisterRequest,
                   db: Session = Depends(get_db),
                   user: User | None = Depends(get_current_user_dependency)):
    """Complete guide registration. DEMO: any 18-digit ID + photos passes."""
    logger.info(f"[GuideRegister] User {user.id if user else 'None'} attempting registration")
    _auth(user)
    digits = re.sub(r"\D", "", req.china_id or "")
    logger.info(f"[GuideRegister] ID digits length: {len(digits)}, accepted_terms: {req.accepted_terms}, interests: {req.interests}")
    if len(digits) != 18:
        logger.warning(f"[GuideRegister] ID validation failed: got {len(digits)} digits")
        raise HTTPException(status_code=400, detail="ID must be 18 digits")
    if not req.accepted_terms:
        logger.warning("[GuideRegister] Terms not accepted")
        raise HTTPException(status_code=400, detail="You must accept the terms")
    if len(req.interests) > 5:
        logger.warning(f"[GuideRegister] Too many interests: {len(req.interests)}")
        raise HTTPException(status_code=400, detail="Max 5 interests")

    profile = db.query(GuideProfile).filter(
        GuideProfile.user_id == user.id).first()
    if not profile:
        profile = GuideProfile(user_id=user.id)
        db.add(profile)
    profile.china_id = digits
    profile.id_front = req.id_front
    profile.id_back = req.id_back
    profile.languages = req.languages
    profile.cert_uploaded = req.cert_uploaded
    profile.interests = req.interests
    profile.accepted_terms = True

    user.is_local_guide = True
    db.commit()
    logger.info(f"[GuideRegister] User {user.id} successfully registered as Insider")
    return {"ok": True, "is_local_guide": True}


@router.get("/status")
def guide_status(db: Session = Depends(get_db),
                 user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    prof = db.query(GuideProfile).filter(GuideProfile.user_id == user.id).first()
    return {
        "is_local_guide": bool(getattr(user, "is_local_guide", False)),
        "interests": (prof.interests if prof else []),
        "languages": (prof.languages if prof else []),
    }


# ---------------- Availability ----------------

class AvailabilityRequest(BaseModel):
    date: str = Field(..., description="YYYY-MM-DD")
    available: bool


@router.post("/availability")
def set_availability(req: AvailabilityRequest,
                     db: Session = Depends(get_db),
                     user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    row = db.query(GuideAvailability).filter(
        GuideAvailability.guide_id == user.id,
        GuideAvailability.date == req.date).first()
    if row:
        row.available = req.available
    else:
        db.add(GuideAvailability(
            guide_id=user.id, date=req.date, available=req.available))
    db.commit()
    return {"ok": True, "date": req.date, "available": req.available}


@router.get("/availability")
def my_availability(db: Session = Depends(get_db),
                    user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    rows = db.query(GuideAvailability).filter(
        GuideAvailability.guide_id == user.id).all()
    return [{"date": r.date, "available": r.available} for r in rows]


# ---------------- Jobs ----------------

@router.get("/jobs")
def my_jobs(db: Session = Depends(get_db),
            user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    today = datetime.utcnow().strftime("%Y-%m-%d")
    jobs = db.query(GuideJob).filter(
        GuideJob.guide_id == user.id,
        GuideJob.date >= today,
        GuideJob.status == "upcoming",
    ).order_by(GuideJob.date.asc()).all()
    out = []
    for j in jobs:
        tourist = db.query(User).filter(User.id == j.tourist_id).first()
        out.append({
            "id": j.id,
            "date": j.date,
            "note": j.note,
            "tourist_name": tourist.nickname if tourist else "Traveller",
            "tourist_flag": tourist.nation_flag if tourist else "🌍",
            "tourist_id": j.tourist_id,
        })
    return out


class BookJobRequest(BaseModel):
    guide_id: int
    date: str
    note: str | None = None


@router.post("/jobs/book")
def book_job(req: BookJobRequest,
             db: Session = Depends(get_db),
             user: User | None = Depends(get_current_user_dependency)):
    _auth(user)
    job = GuideJob(guide_id=req.guide_id, tourist_id=user.id,
                   date=req.date, note=req.note)
    db.add(job)
    db.commit()
    return {"ok": True}


# ---------------- Nearby guides (tourist view) ----------------

@router.get("/profile/{user_id}")
def public_guide_profile(user_id: int,
                         db: Session = Depends(get_db),
                         user: User | None = Depends(get_current_user_dependency)):
    """Public guide details for viewing someone's profile."""
    _auth(user)
    target = db.query(User).filter(User.id == user_id).first()
    if not target or not getattr(target, "is_local_guide", False):
        return {"is_local_guide": False}
    prof = db.query(GuideProfile).filter(
        GuideProfile.user_id == user_id).first()
    return {
        "is_local_guide": True,
        "languages": (prof.languages if prof and prof.languages else []),
        "interests": (prof.interests if prof and prof.interests else []),
        "has_certificate": bool(prof and prof.cert_uploaded),
    }


@router.get("/nearby")
def nearby_guides(date: str | None = None,
                  db: Session = Depends(get_db),
                  user: User | None = Depends(get_current_user_dependency)):
    """List nearby verified guides. If [date] is given, include each guide's
    availability for that date: 'available' / 'unavailable' / 'unknown'."""
    logger.info(f"[NearbyGuides] User {user.id if user else 'None'} requesting nearby guides, date={date}")
    _auth(user)
    guides = (
        db.query(User)
        .filter(User.is_local_guide == True, User.id != user.id)
        .limit(50)
        .all()
    )
    out = []
    for g in guides:
        rp = db.query(RadarProfile).filter(RadarProfile.user_id == g.id).first()
        prof = db.query(GuideProfile).filter(
            GuideProfile.user_id == g.id).first()
        availability = "unknown"
        if date:
            av = db.query(GuideAvailability).filter(
                GuideAvailability.guide_id == g.id,
                GuideAvailability.date == date).first()
            if av is not None:
                availability = "available" if av.available else "unavailable"
        langs = []
        if prof and prof.languages:
            langs = [l.get("language") for l in prof.languages if l.get("language")]
        elif rp and rp.languages:
            langs = rp.languages
        out.append({
            "user_id": g.id,
            "nickname": g.nickname,
            "flag": g.nation_flag,
            "nationality": g.nationality,
            "distance_meters": random.randint(200, 3000),
            "languages": langs or ["Chinese", "English"],
            "interests": (prof.interests if prof and prof.interests else []),
            "availability": availability,
        })
    out.sort(key=lambda x: x["distance_meters"])

    # If fewer than 5 real guides, pad with mock data so the UI has content
    if len(out) < 5:
        mock_guides = [
            {
                "user_id": 90001, "nickname": "Emily Chen", "flag": "🇬🇧",
                "nationality": "UK",
                "distance_meters": 320,
                "languages": ["English", "Chinese"],
                "interests": ["Sightseeing", "History & Culture", "City"],
                "availability": "available",
                "avatar_asset": "assets/videos/en_pic.jpg",
                "video_asset": "assets/videos/en_guide.mp4",
            },
            {
                "user_id": 90002, "nickname": "Sophie Laurent", "flag": "🇫🇷",
                "nationality": "France",
                "distance_meters": 780,
                "languages": ["French", "English", "Chinese"],
                "interests": ["Art", "Foodie", "Photo Tour"],
                "availability": "available",
                "avatar_asset": "assets/videos/fa_pic.jpg",
                "video_asset": "assets/videos/fra_guide.mp4",
            },
            {
                "user_id": 90003, "nickname": "Yuki Tanaka", "flag": "🇯🇵",
                "nationality": "Japan",
                "distance_meters": 1250,
                "languages": ["Japanese", "English", "Chinese"],
                "interests": ["Business", "Translation", "Technology"],
                "availability": "available",
                "avatar_asset": "assets/videos/ja_pic.jpg",
                "video_asset": "assets/videos/ja_guide.mp4",
            },
        ]
        # If date filter is set, vary availability for mock guides
        if date:
            for i, mg in enumerate(mock_guides):
                mg["availability"] = ["available", "available", "unavailable", "available", "unknown"][i % 5]
        # Only add mock guides that don't overlap with real ones
        real_ids = {g["user_id"] for g in out}
        for mg in mock_guides:
            if mg["user_id"] not in real_ids and len(out) < 8:
                out.append(mg)
        out.sort(key=lambda x: x["distance_meters"])

    logger.info(f"[NearbyGuides] Returning {len(out)} guides")
    return out
