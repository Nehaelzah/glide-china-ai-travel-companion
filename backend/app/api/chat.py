"""Chat routes."""

import logging
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.models import User, ChatHistory, TripSummary, Itinerary
from app.schemas.schemas import ChatRequest, ChatReplyResponse
from app.services import ai_service
from app.services.auth_service import get_current_user_dependency

logger = logging.getLogger("chat")

router = APIRouter(prefix="/api/chat", tags=["Chat"])

# How many recent messages to send to the LLM as conversation memory (Ring 1).
HISTORY_LIMIT = 16


@router.post("/ask", response_model=ChatReplyResponse)
async def ask(
    req: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")

    # 1. Save the user's message.
    db.add(ChatHistory(
        user_id=current_user.id, message=req.message, from_user=True))
    db.commit()

    # 2. Read back the recent conversation (Ring 1), oldest-first.
    recent = (
        db.query(ChatHistory)
        .filter(ChatHistory.user_id == current_user.id)
        .order_by(ChatHistory.created_at.desc())
        .limit(HISTORY_LIMIT)
        .all()
    )
    recent.reverse()  # chronological order for the LLM
    history = [
        {"role": "user" if m.from_user else "assistant", "content": m.message}
        for m in recent
    ]

    # 3. Assemble the user's profile (Ring 2).
    profile = {
        "nickname": current_user.nickname,
        "nationality": current_user.nationality,
        "first_time_in_china": current_user.first_time_in_china,
        "days_in_china": current_user.days_in_china,
        "travel_style": getattr(current_user, "travel_style", None),
        "dietary_restrictions": getattr(current_user, "dietary_restrictions", None),
        "learned_preferences": getattr(current_user, "learned_preferences", None),
    }

    # 3b. Load the last 5 trip summaries (Ring 3), oldest-first.
    summary_rows = (
        db.query(TripSummary)
        .filter(TripSummary.user_id == current_user.id)
        .order_by(TripSummary.created_at.desc())
        .limit(5)
        .all()
    )
    summary_rows.reverse()
    summaries = [s.summary for s in summary_rows]

    # 3c. Load existing itineraries for the next 7 days (Ring 2.5).
    today = date.today()
    end_date = today + timedelta(days=7)
    itinerary_rows = (
        db.query(Itinerary)
        .filter(
            Itinerary.user_id == current_user.id,
            Itinerary.date >= today,
            Itinerary.date <= end_date,
        )
        .order_by(Itinerary.date)
        .all()
    )
    itineraries = [
        {
            "date": it.date.isoformat(),
            "title": it.title,
            "items": [dict(i) for i in (it.items or [])],
        }
        for it in itinerary_rows
    ]

    # 4. Ask the AI, passing conversation history + profile + summaries + itineraries.
    reply = await ai_service.chat(
        req.message, req.language,
        weather_temp_c=req.weather_temp_c,
        weather_condition=req.weather_condition,
        weather_aqi=req.weather_aqi,
        weather_uv=req.weather_uv,
        mood=req.mood,
        dietary_restrictions=req.dietary_restrictions,
        latitude=req.latitude,
        longitude=req.longitude,
        location_name=req.location_name,
        history=history,
        profile=profile,
        summaries=summaries,
        itineraries=itineraries,
    )

    # 5. Save the AI's reply.
    db.add(ChatHistory(
        user_id=current_user.id, message=reply, from_user=False))
    db.commit()

    return ChatReplyResponse(reply=reply, user_message=req.message)


# How many recent messages to KEEP after summarizing (for next-session continuity).
KEEP_AFTER_SUMMARY = 10


@router.post("/end-session")
async def end_session(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_dependency),
):
    """Called on logout / app-close. Summarizes the session into a Ring 3
    entry, extracts durable preferences into the profile, then trims old
    chat history keeping only the most recent messages for continuity."""
    if current_user is None:
        raise HTTPException(status_code=401, detail="Not authenticated")

    # Gather this user's messages, oldest-first.
    all_msgs = (
        db.query(ChatHistory)
        .filter(ChatHistory.user_id == current_user.id)
        .order_by(ChatHistory.created_at.asc())
        .all()
    )
    if not all_msgs:
        return {"summarized": False, "reason": "no messages"}

    conversation = [
        {"role": "user" if m.from_user else "assistant", "content": m.message}
        for m in all_msgs
    ]

    # Summarize + extract preferences in one LLM call.
    result = await ai_service.summarize_session(
        conversation,
        existing_preferences=getattr(current_user, "learned_preferences", None),
    )
    summary_text = result.get("summary", "").strip()
    prefs = result.get("preferences", "").strip()

    if summary_text:
        db.add(TripSummary(user_id=current_user.id, summary=summary_text))
    if prefs:
        current_user.learned_preferences = prefs

    # Trim: keep only the most recent messages for next-session continuity.
    if len(all_msgs) > KEEP_AFTER_SUMMARY:
        to_delete = all_msgs[:-KEEP_AFTER_SUMMARY]
        for m in to_delete:
            db.delete(m)

    db.commit()
    return {
        "summarized": bool(summary_text),
        "summary": summary_text,
        "preferences": prefs,
    }
