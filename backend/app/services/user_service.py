"""User profile and preferences service."""

from sqlalchemy.orm import Session

from app.models.models import User, SavedPlace
from app.schemas.schemas import UpdateProfileRequest, UpdatePreferencesRequest


def update_profile(db: Session, user: User, data: UpdateProfileRequest) -> User:
    """Update user profile fields."""
    updates = data.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


def update_preferences(db: Session, user: User, data: UpdatePreferencesRequest) -> User:
    """Update user preferences (mood, notifications)."""
    updates = data.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(user, key, value)
    db.commit()
    db.refresh(user)
    return user


def get_saved_places(db: Session, user: User) -> list[SavedPlace]:
    return db.query(SavedPlace).filter(SavedPlace.user_id == user.id).all()


def add_saved_place(db: Session, user: User, place_name: str) -> SavedPlace:
    place = SavedPlace(user_id=user.id, place_name=place_name)
    db.add(place)
    db.commit()
    db.refresh(place)
    return place


def remove_saved_place(db: Session, user: User, place_id: int) -> bool:
    place = db.query(SavedPlace).filter(
        SavedPlace.id == place_id, SavedPlace.user_id == user.id
    ).first()
    if place:
        db.delete(place)
        db.commit()
        return True
    return False
