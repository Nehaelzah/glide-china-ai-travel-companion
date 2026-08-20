"""Weather routes."""

from fastapi import APIRouter, Query
from app.services import weather_service

router = APIRouter(prefix="/api/weather", tags=["Weather"])


@router.get("/")
async def get_weather(
    lat: float | None = Query(None),
    lon: float | None = Query(None),
):
    return await weather_service.get_weather(lat=lat, lon=lon)
