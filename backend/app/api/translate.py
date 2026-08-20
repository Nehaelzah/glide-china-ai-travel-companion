"""Translation routes."""

from fastapi import APIRouter
from app.schemas.schemas import TranslateRequest, TranslateResponse
from app.services import translate_service

router = APIRouter(prefix="/api/translate", tags=["Translate"])

@router.post("/", response_model=TranslateResponse)
async def translate_text(req: TranslateRequest):
    result = await translate_service.translate(req.text, req.from_lang, req.to_lang, req.context)
    return TranslateResponse(translated_text=result)
