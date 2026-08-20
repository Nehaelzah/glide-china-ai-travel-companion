"""User routes."""

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.schemas import (
    UpdateProfileRequest, UpdatePreferencesRequest,
    SavedPlaceRequest, SavedPlaceResponse, UserProfile,
)
from app.services.auth_service import get_current_user_dependency as get_current_user
from app.models.models import (
    User, SavedPlace, ChatHistory, Itinerary, CommunityPost,
    PostLike, PostComment, FriendRequest, FriendRelationship,
    DirectMessage, RadarProfile, GuideProfile, GuideAvailability, GuideJob,
    TripSummary,
)
from app.services import user_service
import base64

router = APIRouter(prefix="/api/user", tags=["User"])


@router.get("/profile", response_model=UserProfile)
def get_profile(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return current_user


@router.put("/profile", response_model=UserProfile)
def update_profile(req: UpdateProfileRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    updates = req.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.post("/avatar")
def upload_avatar(file: UploadFile = File(...), db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Upload avatar image, store as base64 in DB."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="Only image uploads are allowed")
    contents = file.file.read(2 * 1024 * 1024 + 1)
    if len(contents) > 2 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Avatar must be 2 MB or smaller")
    b64 = base64.b64encode(contents).decode("utf-8")
    current_user.avatar_base64 = b64
    db.commit()
    return {"message": "Avatar uploaded", "avatar_base64": b64}


@router.delete("/avatar")
def remove_avatar(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    current_user.avatar_base64 = None
    db.commit()
    return {"message": "Avatar removed"}


@router.put("/preferences", response_model=UserProfile)
def update_preferences(req: UpdatePreferencesRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return user_service.update_preferences(db, current_user, req)


# ---------- Saved Places ----------

@router.get("/saved-places")
def list_saved_places(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    places = user_service.get_saved_places(db, current_user)
    return [{"id": p.id, "place_name": p.place_name, "created_at": str(p.created_at)} for p in places]


@router.post("/saved-places")
def add_saved_place(req: SavedPlaceRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    place = user_service.add_saved_place(db, current_user, req.place_name)
    return {"id": place.id, "place_name": place.place_name}


@router.delete("/saved-places/{place_id}", status_code=204)
def delete_saved_place(place_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    ok = user_service.remove_saved_place(db, current_user, place_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Saved place not found")


# ---------- Delete Account ----------

@router.delete("/account", status_code=200)
def delete_account(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Permanently delete the current user and all associated data."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    uid = current_user.id
    # Delete all related records
    db.query(ChatHistory).filter(ChatHistory.user_id == uid).delete()
    db.query(SavedPlace).filter(SavedPlace.user_id == uid).delete()
    db.query(Itinerary).filter(Itinerary.user_id == uid).delete()
    db.query(TripSummary).filter(TripSummary.user_id == uid).delete()
    db.query(RadarProfile).filter(RadarProfile.user_id == uid).delete()
    db.query(GuideProfile).filter(GuideProfile.user_id == uid).delete()
    db.query(GuideAvailability).filter(GuideAvailability.guide_id == uid).delete()
    db.query(GuideJob).filter((GuideJob.guide_id == uid) | (GuideJob.tourist_id == uid)).delete()
    # Posts & related
    post_ids = [p.id for p in db.query(CommunityPost).filter(CommunityPost.user_id == uid).all()]
    if post_ids:
        db.query(PostLike).filter(PostLike.post_id.in_(post_ids)).delete(synchronize_session=False)
        db.query(PostComment).filter(PostComment.post_id.in_(post_ids)).delete(synchronize_session=False)
    db.query(CommunityPost).filter(CommunityPost.user_id == uid).delete(synchronize_session=False)
    # Social
    db.query(FriendRequest).filter((FriendRequest.from_user_id == uid) | (FriendRequest.to_user_id == uid)).delete(synchronize_session=False)
    db.query(FriendRelationship).filter((FriendRelationship.user_id == uid) | (FriendRelationship.friend_id == uid)).delete(synchronize_session=False)
    db.query(DirectMessage).filter((DirectMessage.from_user_id == uid) | (DirectMessage.to_user_id == uid)).delete(synchronize_session=False)
    # Post likes from this user (on other people's posts)
    db.query(PostLike).filter(PostLike.user_id == uid).delete()
    db.query(PostComment).filter(PostComment.user_id == uid).delete()
    # Finally delete the user
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted successfully"}
