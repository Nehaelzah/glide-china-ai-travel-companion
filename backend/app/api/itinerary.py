"""Itinerary routes — save & load user travel plans."""

from datetime import date, datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import Itinerary, User
from app.schemas.schemas import (
    SaveItineraryRequest,
    ItineraryResponse,
    ItineraryItemSchema,
)
from app.services.auth_service import get_current_user_dependency as get_current_user

router = APIRouter(prefix="/api/itineraries", tags=["Itinerary"])


def _to_response(it: Itinerary) -> ItineraryResponse:
    return ItineraryResponse(
        id=it.id,
        date=it.date.isoformat(),
        title=it.title,
        items=[ItineraryItemSchema(**i) for i in (it.items or [])],
        total_hours=it.total_hours,
    )


@router.get("")
async def list_itineraries(
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    target_date: Optional[str] = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """
    Get itineraries.
    - Use from_date & to_date for a date range (weekly calendar).
    - Use target_date for a single date lookup.
    """
    q = db.query(Itinerary).filter(Itinerary.user_id == user.id)
    if target_date:
        q = q.filter(Itinerary.date == date.fromisoformat(target_date))
    if from_date:
        q = q.filter(Itinerary.date >= date.fromisoformat(from_date))
    if to_date:
        q = q.filter(Itinerary.date <= date.fromisoformat(to_date))
    return [
        _to_response(it).model_dump()
        for it in q.order_by(Itinerary.date).all()
    ]


@router.post("/save")
async def save_itinerary(
    req: SaveItineraryRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Create or update itinerary for a date."""
    dt = date.fromisoformat(req.date)
    existing = db.query(Itinerary).filter(
        Itinerary.user_id == user.id,
        Itinerary.date == dt,
    ).first()

    total_hours = 0
    for item in req.items:
        dur = item.duration.replace("h", "").strip()
        try:
            total_hours += int(float(dur))
        except ValueError:
            total_hours += 1

    items_data = [i.model_dump() for i in req.items]

    if existing:
        existing.title = req.title
        existing.items = items_data
        existing.total_hours = total_hours
        existing.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return _to_response(existing).model_dump()
    else:
        it = Itinerary(
            user_id=user.id,
            date=dt,
            title=req.title,
            items=items_data,
            total_hours=total_hours,
        )
        db.add(it)
        db.commit()
        db.refresh(it)
        return _to_response(it).model_dump()


@router.delete("/{itinerary_id}", status_code=204)
async def delete_itinerary(
    itinerary_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    it = db.query(Itinerary).filter(
        Itinerary.id == itinerary_id,
        Itinerary.user_id == user.id,
    ).first()
    if not it:
        raise HTTPException(status_code=404, detail="Itinerary not found")
    db.delete(it)
    db.commit()
