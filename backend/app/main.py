"""Glide China Backend - FastAPI application."""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import routers
from app.config import get_settings
from app.database import init_db

settings = get_settings()
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(name)s] %(levelname)s %(message)s")

app = FastAPI(
    title="Glide China API",
    description="Prototype backend for the Glide China travel companion app",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

for router in routers:
    app.include_router(router)


@app.on_event("startup")
def on_startup() -> None:
    settings.validate_runtime_secrets()
    init_db()


@app.get("/")
def root() -> dict[str, str]:
    return {"app": "Glide China API", "version": "1.0.0", "docs": "/docs"}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
