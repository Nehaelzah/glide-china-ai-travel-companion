"""Map service — Tencent Maps IP location + reverse geocoding."""

import httpx
from app.config import get_settings

settings = get_settings()

TENCENT_MAP_KEY = settings.tenmap_key

IP_LOCATION_URL = "https://apis.map.qq.com/ws/location/v1/ip"
REVERSE_GEOCODE_URL = "https://apis.map.qq.com/ws/geocoder/v1/"


def _is_near(
    lat: float,
    lng: float,
    min_lat: float,
    max_lat: float,
    min_lng: float,
    max_lng: float,
) -> bool:
    return min_lat <= lat <= max_lat and min_lng <= lng <= max_lng


def _demo_campus_label(lat: float, lng: float) -> str | None:
    """High-confidence demo labels for places used in the presentation.

    The phone GPS may return an accurate coordinate, while the map API may
    return only a nearby district/landmark. For the demo campus area, this
    gives the user-facing label we actually want to show.
    """
    # DNUI / Dalian software-park campus area.
    if _is_near(lat, lng, 38.8700, 38.9050, 121.5000, 121.5550):
        return "DNUI Campus, Dalian"

    return None


def _clean_address_component(value: str | None) -> str:
    return (value or "").strip()


async def reverse_geocode(lat: float, lng: float) -> dict:
    """Convert GPS coordinates into a readable place name.

    Returns:
        {
            "lat": float,
            "lng": float,
            "name": str,
            "address": str,
            "city": str,
            "district": str,
            "nation": str
        }
    """
    demo_label = _demo_campus_label(lat, lng)

    if not TENCENT_MAP_KEY:
        name = demo_label or "your current area"
        return {
            "lat": lat,
            "lng": lng,
            "name": name,
            "address": name,
            "city": "",
            "district": "",
            "nation": "",
        }

    try:
        async with httpx.AsyncClient(timeout=6) as client:
            r = await client.get(
                REVERSE_GEOCODE_URL,
                params={
                    "location": f"{lat},{lng}",
                    "key": TENCENT_MAP_KEY,
                    "get_poi": 1,
                },
            )
            data = r.json()

            if data.get("status") == 0:
                result = data.get("result", {})
                ad = result.get("ad_info", {}) or {}
                address = _clean_address_component(result.get("address"))
                formatted = _clean_address_component(
                    result.get("formatted_addresses", {}).get("recommend")
                )

                pois = result.get("pois") or []
                poi_title = ""
                if pois and isinstance(pois, list):
                    first_poi = pois[0] or {}
                    poi_title = _clean_address_component(first_poi.get("title"))

                # For the known campus demo area, prefer the campus label.
                # Otherwise prefer POI > formatted address > address > city/district.
                city = _clean_address_component(ad.get("city"))
                district = _clean_address_component(ad.get("district"))
                nation = _clean_address_component(ad.get("nation"))

                name = (
                    demo_label
                    or poi_title
                    or formatted
                    or address
                    or ", ".join(part for part in [district, city] if part)
                    or "your current area"
                )

                return {
                    "lat": lat,
                    "lng": lng,
                    "name": name,
                    "address": address or name,
                    "city": city,
                    "district": district,
                    "nation": nation,
                }
    except Exception:
        pass

    name = demo_label or "your current area"
    return {
        "lat": lat,
        "lng": lng,
        "name": name,
        "address": name,
        "city": "",
        "district": "",
        "nation": "",
    }


async def locate_by_ip() -> dict:
    """Get approximate user location from IP via Tencent Maps.

    This is only a fallback. For accurate phone location, use device GPS on the
    frontend, then call reverse_geocode(lat, lng).
    """
    if not TENCENT_MAP_KEY:
        return {
            "lat": 39.9042,
            "lng": 116.4074,
            "city": "北京市",
            "nation": "中国",
            "name": "Beijing",
        }

    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(
                IP_LOCATION_URL,
                params={"key": TENCENT_MAP_KEY},
            )
            data = r.json()
            if data.get("status") == 0:
                loc = data["result"]["location"]
                ad = data["result"].get("ad_info", {})
                city = ad.get("city", "北京市")
                district = ad.get("district", "")
                return {
                    "lat": loc["lat"],
                    "lng": loc["lng"],
                    "city": city,
                    "district": district,
                    "nation": ad.get("nation", "中国"),
                    "name": district or city or "Beijing",
                }
    except Exception:
        pass

    return {
        "lat": 39.9042,
        "lng": 116.4074,
        "city": "北京市",
        "nation": "中国",
        "name": "Beijing",
    }
