"""Radar routes — nearby travellers (real registered users)."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User, RadarProfile
from app.services import radar_service
from app.services.auth_service import get_current_user_dependency

router = APIRouter(prefix="/api/radar", tags=["Radar"])


class RadarVisibilityBody(BaseModel):
    show_on_radar: bool | None = None
    show_exact_location: bool | None = None
    allow_messages: bool | None = None
    hide_profile: bool | None = None


@router.get("/nearby")
def get_nearby(db: Session = Depends(get_db),
               user: User | None = Depends(get_current_user_dependency)):
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    # Ensure this user has a radar profile so others can see them too.
    radar_service.get_or_create_radar_profile(db, user)
    return radar_service.get_nearby_tourists(db, user)


@router.get("/visibility")
def get_visibility(db: Session = Depends(get_db),
                   user: User | None = Depends(get_current_user_dependency)):
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    rp = db.query(RadarProfile).filter(RadarProfile.user_id == user.id).first()
    if not rp:
        rp = radar_service.get_or_create_radar_profile(db, user)
    return {
        "show_on_radar": rp.show_on_radar,
        "show_exact_location": rp.show_exact_location,
        "allow_messages": rp.allow_messages,
        "hide_profile": rp.hide_profile,
    }


@router.put("/visibility")
def set_visibility(
    req: RadarVisibilityBody,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_current_user_dependency),
):
    if user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    rp = db.query(RadarProfile).filter(RadarProfile.user_id == user.id).first()
    if not rp:
        rp = RadarProfile(user_id=user.id)
        db.add(rp)
        db.flush()
    updates = req.model_dump(exclude_unset=True)
    for k, v in updates.items():
        setattr(rp, k, v)
    db.commit()
    db.refresh(rp)
    return {
        "show_on_radar": rp.show_on_radar,
        "show_exact_location": rp.show_exact_location,
        "allow_messages": rp.allow_messages,
        "hide_profile": rp.hide_profile,
    }
