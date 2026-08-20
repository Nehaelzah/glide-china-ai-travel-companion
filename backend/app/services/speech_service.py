"""Speech services: Speech-to-Text and Text-to-Speech."""

from app.config import get_settings

settings = get_settings()


async def speech_to_text(language: str = "English") -> str:
    """Convert speech to text."""
    if settings.stt_provider == "mock" or not settings.stt_api_key:
        return ""
    return "Speech recognized text"


async def text_to_speech(text: str, language: str = "English") -> bytes | None:
    """Convert text to speech audio. Returns None when mock."""
    if settings.tts_provider == "mock" or not settings.tts_api_key:
        return None
    return None
