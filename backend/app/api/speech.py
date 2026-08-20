"""Speech routes."""

from fastapi import APIRouter
from app.schemas.schemas import SttRequest, SttResponse, TtsRequest
from app.services import speech_service

router = APIRouter(prefix="/api/speech", tags=["Speech"])

@router.post("/stt", response_model=SttResponse)
async def speech_to_text(req: SttRequest):
    text = await speech_service.speech_to_text(req.language)
    return SttResponse(text=text)

@router.post("/tts")
async def text_to_speech(req: TtsRequest):
    audio = await speech_service.text_to_speech(req.text, req.language)
    return {"message": "TTS processed", "has_audio": audio is not None}
