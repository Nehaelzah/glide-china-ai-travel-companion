"""Database engine and session factory."""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase

from app.config import get_settings

settings = get_settings()

# SQLite with check_same_thread=False for async usage
connect_args = {"check_same_thread": False} if "sqlite" in settings.database_url else {}
engine = create_engine(settings.database_url, connect_args=connect_args, echo=settings.debug)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    """FastAPI dependency: yields a DB session and closes it after the request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Create all tables."""
    Base.metadata.create_all(bind=engine)
