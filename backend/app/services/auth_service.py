"""Authentication service: OTP login, password login, and JWT token management."""

import secrets
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from app.models.models import User
from app.core.security import create_access_token, hash_password, verify_password, decode_access_token
from app.database import get_db

_bearer = HTTPBearer(auto_error=False)

_otp_store: dict[str, str] = {}


def generate_otp(phone: str) -> str:
    """Generate a six-digit OTP for the demo-only in-memory store."""
    otp = f"{secrets.randbelow(1_000_000):06d}"
    _otp_store[phone] = otp
    return otp


def verify_otp(phone: str, otp: str) -> bool:
    """Verify the OTP for a phone number."""
    stored = _otp_store.get(phone)
    if stored and stored == otp:
        del _otp_store[phone]
        return True
    return False


def login_or_register(db: Session, phone: str, nickname: str = "Traveller") -> dict:
    """Login or register a user by phone, return JWT token + user info."""
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        user = User(phone=phone, nickname=nickname, password_hash=None)
        db.add(user)
        db.commit()
        db.refresh(user)

    token = create_access_token(data={"sub": str(user.id), "phone": phone})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _user_to_dict(user),
    }


def _country_from_phone(phone: str) -> tuple[str, str]:
    """Derive (nationality, flag) from a phone's dial code prefix.
    Phone looks like '+61 412345678'. Falls back to a neutral default."""
    # Longest prefixes first so +1 doesn't swallow +1-longer codes.
    codes = [
        ("+61", "Australia", "🇦🇺"),
        ("+86", "China", "🇨🇳"),
        ("+44", "United Kingdom", "🇬🇧"),
        ("+91", "India", "🇮🇳"),
        ("+81", "Japan", "🇯🇵"),
        ("+82", "South Korea", "🇰🇷"),
        ("+49", "Germany", "🇩🇪"),
        ("+33", "France", "🇫🇷"),
        ("+34", "Spain", "🇪🇸"),
        ("+39", "Italy", "🇮🇹"),
        ("+7", "Russia", "🇷🇺"),
        ("+65", "Singapore", "🇸🇬"),
        ("+60", "Malaysia", "🇲🇾"),
        ("+66", "Thailand", "🇹🇭"),
        ("+84", "Vietnam", "🇻🇳"),
        ("+62", "Indonesia", "🇮🇩"),
        ("+63", "Philippines", "🇵🇭"),
        ("+64", "New Zealand", "🇳🇿"),
        ("+1", "United States", "🇺🇸"),
    ]
    cleaned = phone.strip()
    for code, name, flag in codes:
        if cleaned.startswith(code):
            return name, flag
    return "United States", "🇺🇸"


def register_user(db: Session, phone: str, nickname: str, password: str) -> dict:
    """Register a new user with phone, nickname, and hashed password. Returns JWT + user info."""
    existing = db.query(User).filter(User.phone == phone).first()
    if existing:
        raise ValueError("Phone already registered")

    nationality, flag = _country_from_phone(phone)
    user = User(
        phone=phone,
        nickname=nickname,
        password_hash=hash_password(password),
        nationality=nationality,
        nation_flag=flag,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(data={"sub": str(user.id), "phone": phone})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _user_to_dict(user),
    }


def password_login(db: Session, phone: str, password: str) -> dict | None:
    """Login with phone + password. Returns JWT + user info, or None if invalid."""
    user = db.query(User).filter(User.phone == phone).first()
    if not user or not user.password_hash:
        return None
    if not verify_password(password, user.password_hash):
        return None

    token = create_access_token(data={"sub": str(user.id), "phone": phone})
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": _user_to_dict(user),
    }


def get_current_user(db: Session, user_id: int) -> User | None:
    """Fetch user by ID."""
    return db.query(User).filter(User.id == user_id).first()


def _days_in_china(user: User) -> int:
    """Day of the trip, counted from the registration date. Day 1 = signup day."""
    from datetime import datetime
    if not user.created_at:
        return 1
    delta = datetime.utcnow().date() - user.created_at.date()
    return max(1, delta.days + 1)


def _user_to_dict(user: User) -> dict:
    return {
        "id": user.id,
        "phone": user.phone,
        "nickname": user.nickname,
        "nationality": user.nationality,
        "nation_flag": user.nation_flag,
        "language_code": user.language_code,
        "first_time_in_china": user.first_time_in_china,
        "days_in_china": _days_in_china(user),
        "onboarded": user.onboarded,
        "mood_label": user.mood_label,
        "notifications_enabled": user.notifications_enabled,
        "avatar_base64": user.avatar_base64,
        "dietary_restrictions": user.dietary_restrictions or [],
    }


def get_current_user_dependency(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User | None:
    """FastAPI dependency: get current user from JWT Bearer token."""
    if credentials is None:
        return None
    payload = decode_access_token(credentials.credentials)
    if payload is None:
        return None
    user_id = payload.get("sub")
    if user_id is None:
        return None
    return db.query(User).filter(User.id == int(user_id)).first()
