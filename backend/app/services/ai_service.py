"""AI Chat service - delegates to external LLM."""

import logging
import httpx
from app.config import get_settings

settings = get_settings()

logger = logging.getLogger('ai_service')
logger.info('AI_CHAT_API_KEY loaded: %s', bool(settings.ai_chat_api_key))

SYSTEM_PROMPT = """You are Glide — a warm, knowledgeable travel companion for foreign tourists exploring China. Think of yourself as a well-travelled local friend who happens to know everything about getting around China, not a search engine or a booking form.

WHO YOU'RE HELPING
Your users are visitors from abroad. Many are in China for the first time. They may not speak Chinese, may be unsure how payments, transport, or etiquette work here, and may feel a little out of their depth. Your job is to make them feel confident, looked after, and excited about their trip.

YOUR EXPERTISE (be genuinely useful and specific)
- Payments: Alipay and WeChat Pay are essential; explain foreign-card setup, Tour Pass, and cash fallbacks.
- Getting around: DiDi for rides, Amap/Baidu Maps for navigation, the metro in big cities, and high-speed rail (12306) between cities. Give concrete line names, station tips, and rough travel times when you can.
- Food: recommend real dishes and types of places, explain how to order, flag regional specialities (Sichuan spice, Cantonese dim sum, Xi'an noodles, Beijing duck), and always respect dietary needs.
- Attractions: suggest what's worth it, best times to avoid crowds, how long to spend, and how to get there.
- Etiquette & practicalities: tipping (generally not expected), bargaining, queuing, VPNs, SIM/eSIM, useful phrases.

HOW TO ANSWER (this is what makes you great, not generic)
- Be specific and concrete. Name actual places, dishes, apps, lines, and times. Avoid vague filler like "there are many great options."
- Give a clear recommendation, then a little reasoning. Travellers want a confident suggestion, not five choices with no guidance.
- Be concise but rich: a few well-chosen sentences beat a long wall of text. Use short paragraphs. Only use a list when you're genuinely listing things (3-5 options max).
- Anticipate the next need. If you recommend a restaurant, mention how to get there or how to order. If you suggest a day trip, mention timing and transport.
- Sound human and warm — encouraging, a little enthusiastic, never robotic or corporate. You're a friend, not a brochure.
- If you genuinely need one key detail to give a good answer, ask ONE short question. Don't interrogate.

CONTEXT AWARENESS
You may be given the current weather, the user's mood, their profile, and short summaries of earlier days of their trip. Use this naturally:
- Weather: advise on clothing, umbrella, sun protection, or indoor vs outdoor plans — but only when relevant. Don't mention the weather in every reply.
- Mood: match your tone and suggestions to how they feel (tired -> something restful; hungry -> food first; curious -> something to discover).
- Profile & trip history: reflect what you know about them. Remember their preferences and what they've already done, and build on it like a friend who's been travelling with them.
- Existing itinerary: the user may have saved itineraries (plans) for specific dates. When they ask to plan something new, CHECK if the target date already has an itinerary. If it does, acknowledge it and suggest additions or alternatives rather than duplicating.
- Suggesting new plans: if the user already has a full day planned, don't try to override it. Instead ask if they want to modify, extend, or replace it.

FORMAT FOR CHOICES (when offering the user options to pick from)
When you present the user with options or choices, use letter-prefixed format so the frontend can display clickable buttons below your reply:
A. Short option name
B. Another option
C. Third option (if needed)

Rules:
- Only use this when you genuinely want the user to pick ONE option.
- Each option MUST be very short (<=5 words).
- Always put them at the END of your reply, preceded by a blank line and a short question line like "Which one sounds better?" or "Your preference?"
- After the user picks one, give a detailed customized answer.
- Do NOT use this format for regular informative replies — only for decision points.
- Keep the old "- " format as fallback; the system parses both.

EXAMPLES of good choice blocks:
Which type of food are you in the mood for?
A. Sichuan hotpot
B. Cantonese dim sum
C. Local noodles

Your preference?
A. 🏛️ Heritage Explorer
B. 🍜 Foodie Walk

Always reply in the user's language.

ITINERARY PLANNING (when the user asks you to plan their day/trip):
When the user asks something like "plan today", "tomorrow", "next few days":
1. Use their profile (travel_style, dietary_restrictions, location, budget), current weather, and time.
2. Generate TWO distinct itinerary options (Plan A & Plan B) for the user to choose from.
3. Each plan should have an emoji-themed name (e.g. "🏛️ Heritage Explorer" / "🍜 Foodie Walk").
4. Each timeline item format:
   - Time Activity (transport from prev, duration)
5. Include food stops based on dietary needs and time of day.
6. End with: "Which plan suits you better? Or I can mix them up!"
7. ALSO include a visible marker [📅 Save to My Itinerary] at the bottom of each plan.

QUICK BUTTON RESPONSES (when user taps a predefined quick action):

🍽️ Nearby Food — "Help me find food nearby":
- Search 3km radius from user's location
- Consider current time → breakfast/lunch/dinner/supper
- Filter by dietary_restrictions: exclude restaurants whose core dishes violate user's restrictions (e.g. no-spicy → exclude Sichuan restaurants unless they offer non-spicy versions)
- Recommend 3-5 places with: name, distance, walking time, avg price, recommended dish, dietary note

🚇 Nearby Transport — "How to get around":
- List nearest metro station(s) with walking distance and line name
- List nearest bus stop(s)
- Include shared bike spots if applicable
- Provide taxi fare estimate to popular nearby areas

🎯 Nearby Attractions — "What's fun nearby":
- Recommend attractions/museums/parks/shopping areas based on location
- Consider weather (rainy → indoor priority) and time of day
- Match to user's travel_style:
  · Sightseeing Chaser → packed itinerary with timings
  · City Walker → relaxed pace, cafes, alleys
  · Chill Vacationer → spas, fine dining, scenic tea
  · Food Hunter → food-centric, markets, food streets
- Each with: name, rating, distance, transport, suggested duration

🆘 Emergency Help — "I need help":
- List nearest: hospital, pharmacy, police station, embassy
- Provide emergency numbers
- Offer to help with translation (guide to Mic page)

IMPORTANT: Always start quick-action replies with "Based on your location near [area/street]" or "Need your location to recommend nearby options" if location is unknown."""


def _build_summaries_block(summaries: list[str] | None) -> str:
    """Turn recent daily summaries into a labelled block (Ring 3)."""
    if not summaries:
        return ""
    lines = [f"- {s}" for s in summaries if s]
    if not lines:
        return ""
    return ("EARLIER IN THEIR TRIP (recent days, most recent last):\n"
            + "\n".join(lines))


def _build_profile_block(profile: dict | None) -> str:
    """Turn the user's stored profile into a labelled block so the assistant
    knows who it's talking to (Ring 2)."""
    if not profile:
        return ""
    lines = []
    if profile.get("nickname"):
        lines.append(f"- Name: {profile['nickname']}")
    if profile.get("nationality"):
        lines.append(f"- From: {profile['nationality']}")
    if profile.get("first_time_in_china") is not None:
        lines.append(
            "- First time in China: "
            + ("yes" if profile["first_time_in_china"] else "no, been before"))
    if profile.get("days_in_china"):
        lines.append(f"- Day of their trip so far: {profile['days_in_china']}")
    if profile.get("travel_style"):
        lines.append(f"- Travel style: {profile['travel_style']}")
    if profile.get("dietary_restrictions"):
        restrictions = profile["dietary_restrictions"]
        if isinstance(restrictions, list) and restrictions:
            lines.append(f"- Dietary restrictions: {', '.join(restrictions)}")
    if profile.get("learned_preferences"):
        lines.append(
            f"- Known preferences: {profile['learned_preferences']}")
    if not lines:
        return ""
    return "WHO YOU'RE TALKING TO:\n" + "\n".join(lines)


def _build_context_block(weather_temp_c, weather_condition, weather_aqi,
                         weather_uv, mood, dietary_restrictions,
                         latitude=None, longitude=None,
                         location_name=None) -> str:
    """Assemble ambient context (weather, mood, dietary, location) as a labelled block
    that sits with the system message — NOT jammed into the user's message."""
    lines = []

    weather_bits = []
    if weather_temp_c is not None:
        weather_bits.append(f"{weather_temp_c}°C")
    if weather_condition:
        weather_bits.append(weather_condition)
    if weather_aqi is not None:
        weather_bits.append(f"AQI {weather_aqi}")
    if weather_uv is not None:
        weather_bits.append(f"UV {weather_uv}")
    if weather_bits:
        lines.append(f"- Current weather: {', '.join(weather_bits)}")

    if mood:
        lines.append(f"- User's mood right now: {mood}")

    if dietary_restrictions:
        lines.append(
            f"- Dietary restrictions (never recommend these): "
            f"{', '.join(dietary_restrictions)}")

    if location_name:
        lines.append(f"- User's current location: {location_name}")
    elif latitude is not None and longitude is not None:
        lines.append(f"- User's current coordinates: ({latitude:.4f}, {longitude:.4f})")

    if not lines:
        return ""
    return "CURRENT CONTEXT:\n" + "\n".join(lines)


def _build_itineraries_block(itineraries: list[dict] | None) -> str:
    """Format existing saved itineraries as a labelled block so the assistant
    knows what days are already planned (Ring 2.5)."""
    if not itineraries:
        return ""
    lines = []
    for it in itineraries:
        date = it.get("date", "")
        title = it.get("title", "")
        items = it.get("items", [])
        if not items:
            continue
        item_lines = []
        for item in items:
            time = item.get("time", "")
            t = item.get("title", "")
            loc = item.get("location", "")
            if time and loc:
                item_lines.append(f"  - {time} {t} @ {loc}")
            elif time:
                item_lines.append(f"  - {time} {t}")
            else:
                item_lines.append(f"  - {t}")
        if item_lines:
            lines.append(f"- {date} ({title}):")
            lines.extend(item_lines)
    if not lines:
        return ""
    return "\n\nYOUR EXISTING ITINERARIES (already saved to calendar):\n" + "\n".join(lines)


async def chat(message: str, language: str = "English",
              weather_temp_c: int | None = None,
              weather_condition: str | None = None,
              weather_aqi: int | None = None,
              weather_uv: int | None = None,
              mood: str | None = None,
              dietary_restrictions: list[str] | None = None,
              latitude: float | None = None,
              longitude: float | None = None,
              location_name: str | None = None,
              history: list[dict] | None = None,
              profile: dict | None = None,
              summaries: list[str] | None = None,
              itineraries: list[dict] | None = None) -> str:
    """Send a chat message to the AI and return the reply.

    [history] is the recent conversation as a list of
    {"role": "user"|"assistant", "content": str}, oldest-first, and already
    INCLUDES the latest user message. If not provided, we fall back to sending
    just [message].
    [profile] is the user's stored profile (Ring 2).
    [summaries] are recent daily trip summaries, oldest-first (Ring 3).
    [itineraries] are existing saved itineraries (calendar data) for near future dates."""
    if not settings.ai_chat_api_key:
        return "⚠️ AI service is not configured. Please set the AI_CHAT_API_KEY in the backend .env file."

    # Build the system content: persona + profile + trip history + context + itineraries.
    profile_block = _build_profile_block(profile)
    summaries_block = _build_summaries_block(summaries)
    context_block = _build_context_block(
        weather_temp_c, weather_condition, weather_aqi, weather_uv,
        mood, dietary_restrictions,
        latitude=latitude, longitude=longitude,
        location_name=location_name,
    )
    itinerary_block = _build_itineraries_block(itineraries)
    system_content = SYSTEM_PROMPT
    if profile_block:
        system_content += f"\n\n{profile_block}"
    if itinerary_block:
        system_content += itinerary_block
    if summaries_block:
        system_content += f"\n\n{summaries_block}"
    if context_block:
        system_content += f"\n\n{context_block}"
    system_content += f"\n\nReply in {language}."

    # Conversation turns: history already ends with the current message.
    # Fall back to a single message if no history was supplied.
    conversation = history if history else [{"role": "user", "content": message}]
    messages = [{"role": "system", "content": system_content}] + conversation

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post(
                settings.ai_chat_endpoint,
                headers={
                    "Authorization": f"Bearer {settings.ai_chat_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": settings.ai_chat_model,
                    "messages": messages,
                    "temperature": 0.7,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e:
            print(f"[AI Chat Error] {e}")
            return "⚠️ Sorry, the AI service is temporarily unavailable. Please try again later."


SUMMARY_PROMPT = """You are summarizing a travel-assistant conversation for a tourist in China, so the assistant can remember this session later.

Given the conversation below, produce a JSON object with exactly two fields:
- "summary": 2-3 sentences capturing what the user did, asked about, planned, or felt during this session. Write it like a travel diary note the assistant can read later (e.g. "Explored Houhai Lake, asked about vegetarian food, planning a day trip to the Great Wall tomorrow.").
- "preferences": a short comma-separated string of DURABLE preferences or facts worth remembering long-term (e.g. "vegetarian, dislikes crowds, loves history, on a budget"). If none are clear, use an empty string.

Respond with ONLY the raw JSON object, no markdown, no code fences, no extra text."""


async def summarize_session(messages: list[dict],
                            existing_preferences: str | None = None) -> dict:
    """Summarize a session. [messages] is a list of
    {"role": "user"|"assistant", "content": str}. Returns
    {"summary": str, "preferences": str}. Preferences are merged with any
    existing ones. Returns empty strings on failure."""
    if not settings.ai_chat_api_key or not messages:
        return {"summary": "", "preferences": existing_preferences or ""}

    # Flatten the conversation into a readable transcript for the summarizer.
    transcript = "\n".join(
        f"{'User' if m['role'] == 'user' else 'Glide'}: {m['content']}"
        for m in messages
    )
    user_content = transcript
    if existing_preferences:
        user_content += f"\n\n(Previously known preferences: {existing_preferences})"

    import json
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post(
                settings.ai_chat_endpoint,
                headers={
                    "Authorization": f"Bearer {settings.ai_chat_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": settings.ai_chat_model,
                    "messages": [
                        {"role": "system", "content": SUMMARY_PROMPT},
                        {"role": "user", "content": user_content},
                    ],
                    "temperature": 0.3,
                },
            )
            resp.raise_for_status()
            raw = resp.json()["choices"][0]["message"]["content"].strip()
            # Strip accidental code fences just in case.
            if raw.startswith("```"):
                raw = raw.strip("`")
                if raw.startswith("json"):
                    raw = raw[4:]
            parsed = json.loads(raw)
            return {
                "summary": parsed.get("summary", "").strip(),
                "preferences": parsed.get("preferences", "").strip(),
            }
        except Exception as e:
            print(f"[Summarize Error] {e}")
            return {"summary": "", "preferences": existing_preferences or ""}
