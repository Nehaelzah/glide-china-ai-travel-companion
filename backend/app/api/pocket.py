"""Pocket routes."""

from fastapi import APIRouter, Query
from app.services import pocket_service

router = APIRouter(prefix="/api/pocket", tags=["Pocket"])

@router.get("/apps")
def get_apps(category: str | None = Query(None)):
    return pocket_service.get_apps(category)

@router.get("/categories")
def get_categories():
    return pocket_service.get_categories()
