"""Pydantic schemas for request/response validation."""

from datetime import datetime
from typing import List
from pydantic import BaseModel, Field


# =============================================================================
# Auth
# =============================================================================
class LoginRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=20, description="Phone number")


class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str = Field(..., min_length=4, max_length=6)
    nickname: str = Field(default="Traveller", max_length=50)


class RegisterRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=20)
    nickname: str = Field(default="Traveller", max_length=50)
    password: str = Field(..., min_length=4, max_length=20, description="Password (6 digits or more)")
    otp: str = Field(..., min_length=4, max_length=6)


class PasswordLoginRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=20)
    password: str = Field(..., min_length=1, max_length=20)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


# =============================================================================
# User
# =============================================================================
class UserProfile(BaseModel):
    id: int
    phone: str
    nickname: str
    nationality: str
    nation_flag: str
    language_code: str
    first_time_in_china: bool
    days_in_china: int
    onboarded: bool
    mood_label: str | None = None
    notifications_enabled: bool
    avatar_base64: str | None = None
    dietary_restrictions: list[str] = []
    travel_style: str | None = None

    class Config:
        from_attributes = True


class UpdateProfileRequest(BaseModel):
    nickname: str | None = None
    nationality: str | None = None
    nation_flag: str | None = None
    language_code: str | None = None
    first_time_in_china: bool | None = None
    days_in_china: int | None = None
    avatar_base64: str | None = None
    travel_style: str | None = None


class UpdatePreferencesRequest(BaseModel):
    mood_label: str | None = None
    notifications_enabled: bool | None = None
    dietary_restrictions: list[str] | None = None


# =============================================================================
# Radar
# =============================================================================
class RadarVisibilityRequest(BaseModel):
    show_on_radar: bool | None = None
    show_exact_location: bool | None = None
    allow_messages: bool | None = None
    hide_profile: bool | None = None
    latitude: float | None = None
    longitude: float | None = None


class NearbyTouristResponse(BaseModel):
    id: int
    nickname: str
    country: str
    flag: str
    distance_meters: int
    languages: list[str]
    interests: list[str]
    online: bool
    avatar_color: str
    dx: float
    dy: float


# =============================================================================
# Chat
# =============================================================================
class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    language: str = Field(default="English")
    weather_temp_c: int | None = None
    weather_condition: str | None = None
    weather_aqi: int | None = None
    weather_uv: int | None = None
    mood: str | None = None
    dietary_restrictions: list[str] = []
    latitude: float | None = None
    longitude: float | None = None
    location_name: str | None = None  # readable name like "Wangfujing, Beijing"


class ChatMessageResponse(BaseModel):
    id: int
    message: str
    from_user: bool
    created_at: datetime

    class Config:
        from_attributes = True


class ChatReplyResponse(BaseModel):
    reply: str
    user_message: str


# =============================================================================
# Itinerary
# =============================================================================
class ItineraryItemSchema(BaseModel):
    time: str = ""
    title: str = ""
    type: str = "attraction"  # transport/attraction/food/entertainment/rest
    duration: str = "1h"
    location: str = ""


class SaveItineraryRequest(BaseModel):
    date: str  # "2026-07-05"
    title: str = "My Day"
    items: List[ItineraryItemSchema] = []


class ItineraryResponse(BaseModel):
    id: int
    date: str
    title: str
    items: List[ItineraryItemSchema]
    total_hours: int

    class Config:
        from_attributes = True


# =============================================================================
# Translation
# =============================================================================
class TranslateRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    from_lang: str
    to_lang: str
    context: list[str] = []


class TranslateResponse(BaseModel):
    translated_text: str


# =============================================================================
# Speech
# =============================================================================
class SttRequest(BaseModel):
    language: str = Field(default="English")


class SttResponse(BaseModel):
    text: str


class TtsRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    language: str = Field(default="English")


# =============================================================================
# Pocket (China Apps)
# =============================================================================
class ChinaAppResponse(BaseModel):
    name: str
    tagline: str
    icon_name: str
    color_hex: str
    category: str
    setup_steps: list[str]
    image_asset_path: str | None = None
    app_store_url: str = ""


# =============================================================================
# Weather
# =============================================================================
class WeatherResponse(BaseModel):
    temp_c: int
    aqi: int
    uv: int
    condition: str


# =============================================================================
# Saved Places
# =============================================================================
class SavedPlaceRequest(BaseModel):
    place_name: str = Field(..., min_length=1, max_length=200)


class SavedPlaceResponse(BaseModel):
    id: int
    place_name: str
    created_at: datetime

    class Config:
        from_attributes = True


# =============================================================================
# Change Password
# =============================================================================
class ChangePasswordRequest(BaseModel):
    old_password: str = Field(..., min_length=1, max_length=20)
    new_password: str = Field(..., min_length=6, max_length=20)
