"""Authentication routes for the prototype backend."""

import logging

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.config import get_settings
from app.database import get_db
from app.schemas.schemas import (
    ChangePasswordRequest,
    LoginRequest,
    PasswordLoginRequest,
    RegisterRequest,
    VerifyOtpRequest,
)
from app.services import auth_service

logger = logging.getLogger("auth")
settings = get_settings()
router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)) -> dict[str, str]:
    """Issue a local-development OTP only when explicitly enabled in `.env`."""
    if not settings.demo_otp_enabled:
        raise HTTPException(
            status_code=503,
            detail="OTP delivery is not configured. Use a verified provider before deployment.",
        )
    otp = auth_service.generate_otp(req.phone)
    logger.warning("Demo OTP issued; do not enable this mode in a deployed service.")
    return {"phone": req.phone, "message": "Demo OTP issued locally.", "otp": otp}


@router.post("/verify-otp")
def verify_otp(req: VerifyOtpRequest, db: Session = Depends(get_db)) -> dict:
    if not settings.demo_otp_enabled or not auth_service.verify_otp(req.phone, req.otp):
        raise HTTPException(status_code=401, detail="Invalid or unavailable OTP")
    return auth_service.login_or_register(db, req.phone, req.nickname)


@router.post("/register")
def register(req: RegisterRequest, db: Session = Depends(get_db)) -> dict:
    if not settings.demo_otp_enabled or not auth_service.verify_otp(req.phone, req.otp):
        raise HTTPException(status_code=401, detail="Invalid or unavailable OTP")
    try:
        return auth_service.register_user(db, req.phone, req.nickname, req.password)
    except ValueError as error:
        raise HTTPException(status_code=409, detail=str(error)) from error


@router.post("/password-login")
def password_login(req: PasswordLoginRequest, db: Session = Depends(get_db)) -> dict:
    result = auth_service.password_login(db, req.phone, req.password)
    if not result:
        raise HTTPException(status_code=401, detail="Invalid phone or password")
    return result


@router.post("/change-password")
def change_password(
    req: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user=Depends(auth_service.get_current_user_dependency),
) -> dict[str, str]:
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    if not current_user.password_hash:
        raise HTTPException(status_code=400, detail="No password set — use register first")
    if not auth_service.verify_password(req.old_password, current_user.password_hash):
        raise HTTPException(status_code=401, detail="Old password is incorrect")
    current_user.password_hash = auth_service.hash_password(req.new_password)
    db.commit()
    return {"message": "Password changed successfully"}
