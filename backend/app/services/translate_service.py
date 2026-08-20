"""Translation service - uses Qwen chat API for translation."""

import httpx
from app.config import get_settings

settings = get_settings()

_FB_EN_ZH = {
    "hello": "你好",
    "thank you": "谢谢",
    "how much is this": "这个多少钱？",
    "where is the bathroom": "洗手间在哪里？",
    "can you help me": "你能帮我吗？",
    "take me to the hotel": "请带我去酒店。",
}
_FB_ZH_EN = {
    "你好": "Hello",
    "谢谢": "Thank you",
    "这个多少钱？": "How much is this?",
    "好的": "Okay",
    "欢迎": "Welcome",
}


async def translate(text: str, from_lang: str, to_lang: str, context=None) -> str:
    """Translate text using Qwen (DashScope) or fallback."""
    if settings.translate_provider == "mock" or not settings.translate_api_key:
        return _fallback(text, to_lang)

    system_prompt = (
        f"You are a translator. Translate the following text from {from_lang} "
        f"to {to_lang}. ONLY output the translated text, nothing else."
    )

    async with httpx.AsyncClient(timeout=15.0) as client:
        try:
            resp = await client.post(
                settings.translate_endpoint,
                headers={
                    "Authorization": f"Bearer {settings.translate_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": "qwen-plus",
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": text},
                    ],
                    "temperature": 0.3,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"].strip()
        except Exception as e:
            print(f"[Translate Error] {e}")
            return _fallback(text, to_lang)


def _fallback(text: str, to_lang: str) -> str:
    lower = text.lower().strip()
    if "chinese" in to_lang.lower() or "中文" in to_lang:
        return _FB_EN_ZH.get(lower, f"[译] {text}")
    else:
        return _FB_ZH_EN.get(text.strip(), f"[EN] {text}")
