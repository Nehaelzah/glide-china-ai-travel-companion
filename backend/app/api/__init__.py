"""API route registration."""

from app.api.auth import router as auth_router
from app.api.user import router as user_router
from app.api.chat import router as chat_router
from app.api.translate import router as translate_router
from app.api.speech import router as speech_router
from app.api.pocket import router as pocket_router
from app.api.radar import router as radar_router
from app.api.weather import router as weather_router
from app.api.map import router as map_router

from app.api.itinerary import router as itinerary_router
from app.api.posts import router as posts_router
from app.api.social import router as social_router
from app.api.guides import router as guides_router

routers = [auth_router, user_router, chat_router, translate_router, speech_router, pocket_router, radar_router, weather_router, map_router, itinerary_router, posts_router, social_router, guides_router]
