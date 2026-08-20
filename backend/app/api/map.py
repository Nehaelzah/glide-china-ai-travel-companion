"""Map routes — IP location, reverse geocoding and map config."""

from fastapi import APIRouter, HTTPException, Query
from app.services import map_service

router = APIRouter(prefix="/api/map", tags=["Map"])


@router.get("/locate")
async def locate():
    """Return approximate user location based on IP.

    This is a fallback only. For accurate phone location, the frontend should
    use device GPS and call /api/map/reverse.
    """
    return await map_service.locate_by_ip()


@router.get("/reverse")
async def reverse_location(
    lat: float = Query(..., description="GPS latitude from the phone"),
    lng: float | None = Query(None, description="GPS longitude from the phone"),
    lon: float | None = Query(None, description="Alternative longitude name"),
):
    """Return a readable place name for phone GPS coordinates."""
    longitude = lng if lng is not None else lon
    if longitude is None:
        raise HTTPException(
            status_code=400,
            detail="Longitude is required. Use either lng or lon.",
        )

    return await map_service.reverse_geocode(lat=lat, lng=longitude)
