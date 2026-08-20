"""SQLAlchemy ORM models for Glide China."""

from datetime import datetime, date

from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Text, ForeignKey, JSON, Date
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    phone = Column(String(20), unique=True, index=True, nullable=False)
    nickname = Column(String(50), default="Traveller")
    nationality = Column(String(50), default="United States")
    nation_flag = Column(String(10), default="🇺🇸")
    language_code = Column(String(10), default="en")
    first_time_in_china = Column(Boolean, default=True)
    days_in_china = Column(Integer, default=1)
    onboarded = Column(Boolean, default=False)
    mood_label = Column(String(30), nullable=True)
    notifications_enabled = Column(Boolean, default=True)
    password_hash = Column(String(128), nullable=True)
    avatar_base64 = Column(Text, nullable=True)
    dietary_restrictions = Column(JSON, default=list)
    learned_preferences = Column(Text, nullable=True)  # Ring 2: soft prefs learned from chat
    travel_style = Column(String(30), nullable=True)  # sightseeing_chaser/city_walker/chill_vacationer/food_hunter
    is_local_guide = Column(Boolean, default=False)  # verified Chinese-ID local guide
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    radar_profile = relationship("RadarProfile", back_populates="user", uselist=True)
    saved_places = relationship("SavedPlace", back_populates="user", uselist=True)
    chat_history = relationship("ChatHistory", back_populates="user", uselist=True)
    itineraries = relationship("Itinerary", back_populates="user", uselist=True)


class RadarProfile(Base):
    __tablename__ = "radar_profiles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    show_on_radar = Column(Boolean, default=True)
    show_exact_location = Column(Boolean, default=False)
    allow_messages = Column(Boolean, default=True)
    hide_profile = Column(Boolean, default=False)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    interests = Column(JSON, default=list)
    languages = Column(JSON, default=list)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="radar_profile")


class SavedPlace(Base):
    __tablename__ = "saved_places"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    place_name = Column(String(200), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="saved_places")


class ChatHistory(Base):
    __tablename__ = "chat_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    from_user = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="chat_history")


class Itinerary(Base):
    __tablename__ = "itineraries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(Date, nullable=False)
    title = Column(String(100), default="My Day")
    items = Column(JSON, default=list)
    total_hours = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="itineraries")


class TripSummary(Base):
    """Ring 3: an LLM-generated summary of one session/day of the user's trip."""
    __tablename__ = "trip_summaries"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    summary = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")


class CommunityPost(Base):
    __tablename__ = "community_posts"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(Text, nullable=True)  # base64 image data
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User")


class PostLike(Base):
    __tablename__ = "post_likes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    post_id = Column(Integer, ForeignKey("community_posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class PostComment(Base):
    __tablename__ = "post_comments"

    id = Column(Integer, primary_key=True, autoincrement=True)
    post_id = Column(Integer, ForeignKey("community_posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")


class FriendRequest(Base):
    __tablename__ = "friend_requests"

    id = Column(Integer, primary_key=True, autoincrement=True)
    from_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    to_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    status = Column(String(20), default="pending")  # pending/accepted/rejected
    created_at = Column(DateTime, default=datetime.utcnow)


class FriendRelationship(Base):
    __tablename__ = "friend_relationships"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    friend_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class DirectMessage(Base):
    __tablename__ = "direct_messages"

    id = Column(Integer, primary_key=True, autoincrement=True)
    from_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    to_user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class GuideProfile(Base):
    """Detailed local-guide registration data (one per verified guide)."""
    __tablename__ = "guide_profiles"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)
    # Step 1 — Identity
    china_id = Column(String(32), nullable=True)
    id_front = Column(Text, nullable=True)   # base64
    id_back = Column(Text, nullable=True)    # base64
    # Step 2 — Skills
    languages = Column(JSON, default=list)   # [{"language": "English", "level": "Native"}]
    cert_uploaded = Column(Text, nullable=True)  # base64 of English cert (optional)
    interests = Column(JSON, default=list)   # ["Foodie", "Nightlife", ...] max 5
    # Step 3 — Terms
    accepted_terms = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User")


class GuideAvailability(Base):
    """A guide's availability for a specific date."""
    __tablename__ = "guide_availability"

    id = Column(Integer, primary_key=True, autoincrement=True)
    guide_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(String(10), nullable=False)   # 'YYYY-MM-DD'
    available = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class GuideJob(Base):
    """A booking/job between a tourist and a guide on a date."""
    __tablename__ = "guide_jobs"

    id = Column(Integer, primary_key=True, autoincrement=True)
    guide_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    tourist_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date = Column(String(10), nullable=False)
    note = Column(Text, nullable=True)
    status = Column(String(20), default="upcoming")  # upcoming/done/cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
