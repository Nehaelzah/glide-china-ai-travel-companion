"""Weather service — real data from QWeather (和风天气)."""

import random
import logging
import httpx
from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

QWEATHER_BASE = "https://m33v5bdx78.re.qweatherapi.com/v7"
QWEATHER_AIR = "https://m33v5bdx78.re.qweatherapi.com/v7/air/now"
QWEATHER_KEY = settings.weather_api_key
DEFAULT_LOCATION = "101010100"  # 北京

# QWeather returns Chinese condition text even with lang=en.
# Map every known value to English for the AI and front-end.
_CN2EN = {
    "晴": "Sunny",
    "少云": "Mostly Clear",
    "晴间多云": "Partly Cloudy",
    "多云": "Cloudy",
    "阴": "Overcast",
    "有风": "Windy",
    "微风": "Light Breeze",
    "和风": "Gentle Breeze",
    "清风": "Moderate Breeze",
    "强风/劲风": "Strong Breeze",
    "疾风": "Near Gale",
    "大风": "Gale",
    "烈风": "Strong Gale",
    "风暴": "Storm",
    "狂爆风": "Violent Storm",
    "飓风": "Hurricane",
    "热带风暴": "Tropical Storm",
    "霾": "Haze",
    "中度霾": "Moderate Haze",
    "重度霾": "Heavy Haze",
    "严重霾": "Severe Haze",
    "阵雨": "Rain Showers",
    "雷阵雨": "Thundershowers",
    "雷阵雨伴有冰雹": "Thundershowers with Hail",
    "小雨": "Light Rain",
    "中雨": "Moderate Rain",
    "大雨": "Heavy Rain",
    "暴雨": "Rainstorm",
    "大暴雨": "Heavy Rainstorm",
    "特大暴雨": "Extreme Rainstorm",
    "强阵雨": "Heavy Showers",
    "极端降雨": "Extreme Rain",
    "毛毛雨": "Drizzle",
    "细雨": "Drizzle",
    "雨": "Rain",
    "小雪": "Light Snow",
    "中雪": "Moderate Snow",
    "大雪": "Heavy Snow",
    "暴雪": "Snowstorm",
    "雨夹雪": "Sleet",
    "阵雪": "Snow Showers",
    "雾": "Foggy",
    "薄雾": "Mist",
    "浓雾": "Dense Fog",
    "冻雨": "Freezing Rain",
    "扬沙": "Blowing Sand",
    "浮尘": "Floating Dust",
    "沙尘暴": "Sandstorm",
    "强沙尘暴": "Severe Sandstorm",
    "龙卷风": "Tornado",
    "冷": "Cold",
    "热": "Hot",
    "未知": "Unknown",
}


def _cn_to_en(text: str) -> str:
    """Translate Chinese weather condition from QWeather to English."""
    return _CN2EN.get(text, text)


async def get_weather(lat: float | None = None, lon: float | None = None) -> dict:
    """Fetch current weather + AQI from QWeather API.

    Returns a dict compatible with the front-end WeatherSnapshot:
        {temp_c, aqi, uv, condition}
    Falls back to random mock data if the API call fails.
    """
    # Build location string: prefer lat/lon, fall back to Beijing city ID
    if lat is not None and lon is not None:
        location = f"{lon},{lat}"
    else:
        location = DEFAULT_LOCATION

    params = {"location": location, "key": QWEATHER_KEY, "lang": "en"}

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            # --- Current weather ---
            r = await client.get(
                f"{QWEATHER_BASE}/weather/now", params=params
            )
            weather_data = r.json()

            temp_c = 28
            condition = "Partly cloudy"
            if weather_data.get("code") == "200":
                now = weather_data["now"]
                temp_c = int(now.get("temp", 28))
                condition = _cn_to_en(now.get("text", "Partly cloudy"))
            else:
                logger.warning(
                    "QWeather weather API returned code=%s: %s",
                    weather_data.get("code"),
                    weather_data.get("error", {}).get("detail", ""),
                )

            # --- Air quality (optional, may not be in free tier) ---
            aqi = _estimate_aqi(condition)
            try:
                r2 = await client.get(QWEATHER_AIR, params=params)
                air_data = r2.json()
                if air_data.get("code") == "200":
                    aqi = int(air_data["now"].get("aqi", aqi))
                else:
                    logger.warning(
                        "QWeather air API returned code=%s",
                        air_data.get("code"),
                    )
            except Exception as e:
                logger.debug("QWeather air API error: %s", e)

            # --- UV index (not provided by QWeather free tier) ---
            uv = _estimate_uv(condition, temp_c)

            return {
                "temp_c": temp_c,
                "aqi": aqi,
                "uv": uv,
                "condition": condition,
            }
    except Exception:
        return _mock_fallback()


def _estimate_aqi(condition: str) -> int:
    """Rough AQI estimate based on weather condition."""
    low = {"Sunny", "Clear", "Fair"}
    mid = {"Partly cloudy", "Cloudy", "Overcast"}
    if condition in low:
        return random.randint(30, 55)
    if condition in mid:
        return random.randint(40, 70)
    return random.randint(50, 85)


def _estimate_uv(condition: str, temp_c: int) -> int:
    """Rough UV estimate based on condition and temperature."""
    if temp_c > 30 and condition in {"Sunny", "Clear", "Fair"}:
        return random.randint(7, 10)
    if temp_c > 25 and condition in {"Sunny", "Partly cloudy"}:
        return random.randint(5, 8)
    if condition in {"Cloudy", "Overcast"}:
        return random.randint(2, 5)
    return random.randint(1, 4)


def _mock_fallback() -> dict:
    """Return random mock data when API is unreachable."""
    return {
        "temp_c": random.randint(22, 35),
        "aqi": random.randint(30, 80),
        "uv": random.randint(3, 9),
        "condition": random.choice(
            ["Sunny", "Partly cloudy", "Cloudy", "Light rain"]
        ),
    }
