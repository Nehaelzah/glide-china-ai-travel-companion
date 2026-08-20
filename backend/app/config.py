"""Application configuration loaded from local environment variables."""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    host: str = "127.0.0.1"
    port: int = 8000
    debug: bool = False
    database_url: str = "sqlite:///./glide_china.db"
    secret_key: str = ""
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    cors_origins: str = ""
    demo_otp_enabled: bool = False

    ai_chat_endpoint: str = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    ai_chat_api_key: str = ""
    ai_chat_model: str = "qwen-plus"
    translate_endpoint: str = ""
    translate_api_key: str = ""
    translate_provider: str = "mock"
    stt_endpoint: str = ""
    stt_api_key: str = ""
    stt_provider: str = "mock"
    tts_endpoint: str = ""
    tts_api_key: str = ""
    tts_provider: str = "mock"
    weather_api_key: str = ""
    weather_provider: str = "mock"
    tenmap_key: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    @property
    def allowed_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    def validate_runtime_secrets(self) -> None:
        if not self.secret_key or self.secret_key == "dev-secret-change-in-production":
            raise RuntimeError("Set a strong SECRET_KEY in backend/.env before starting the API.")
        if not self.allowed_origins:
            raise RuntimeError("Set one or more CORS_ORIGINS in backend/.env before starting the API.")


@lru_cache()
def get_settings() -> Settings:
    return Settings()
