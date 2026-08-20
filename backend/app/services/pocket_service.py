"""Pocket (China Apps toolkit) service."""

CHINA_APPS = [
    {
        "name": "Alipay",
        "tagline": "Pay for almost anything — scan QR codes at shops, restaurants, and markets",
        "icon_name": "account_balance_wallet",
        "color_hex": "#1677FF",
        "category": "Payments",
        "image_asset_path": "assets/images/apps/alipay.png",
        "app_store_url": "https://apps.apple.com/app/alipay/id333206289",
        "setup_steps": [
            "📲 Step 1: Download & Install\nOpen the App Store and search for \"Alipay\" by Ant Group. Tap \"Get\" and wait for installation. Once installed, tap the blue Alipay icon to open it.",
            "👤 Step 2: Register Account\nOn the welcome screen, tap \"Register\". Select your country code (+1, +44, etc.), enter your phone number, and tap \"Next\". Enter the 6-digit SMS code sent to your phone.",
            "💳 Step 3: Add International Card\nGo to \"Me\" > \"Bank Cards\" > \"+\". Tap \"Add Card\" and enter your Visa/Mastercard details (card number, expiry, CVV). Alipay supports most international cards for payments.",
            "🪪 Step 4: Verify with Passport (if needed)\nFor higher transfer limits, go to \"Me\" > \"Settings\" > \"Account\" > \"Real-name Verification\". Take a photo of your passport and follow the on-screen instructions.",
            "✅ Step 5: Top Up & Start Paying\nGo to \"Me\" > \"Balance\" > \"Top Up\". Enter an amount (min ¥10) and choose your international card. Once topped up, scan any Alipay QR code to pay.",
        ],
    },
    {
        "name": "WeChat",
        "tagline": "Messaging, payments, mini-programs — one app for everything",
        "icon_name": "chat_bubble",
        "color_hex": "#07C160",
        "category": "Payments",
        "image_asset_path": "assets/images/apps/wechat.png",
        "app_store_url": "https://apps.apple.com/app/wechat/id414478124",
        "setup_steps": [
            "📲 Step 1: Install WeChat\nDownload \"WeChat\" by Tencent from the App Store. Open the app and tap \"Sign Up\".",
            "📝 Step 2: Create Account\nEnter your name and phone number. Slide the puzzle piece to complete the CAPTCHA. Enter the SMS verification code.",
            "🔐 Step 3: Friend Verification (Important!)\nWeChat requires a trusted contact in China to verify you. Ask someone you know to open WeChat, scan your QR code (found in Me > QR Code), and confirm your registration.",
            "💳 Step 4: Add Payment Method\nGo to \"Me\" > \"Services\" > \"Wallet\" > \"Cards\". Tap \"Add a Card\" and enter your international credit card. WeChat accepts Visa, Mastercard, and JCB.",
            "🛡️ Step 5: Enable WeChat Pay Security\nGo to Me > Services > Wallet > three-dot menu (top-right) > \"Security\". Set a 6-digit pay password and optionally enable fingerprint/face ID.",
        ],
    },
    {
        "name": "Amap",
        "tagline": "Detailed maps and navigation optimized for China",
        "icon_name": "map",
        "color_hex": "#00A3FF",
        "category": "Maps",
        "image_asset_path": "assets/images/apps/amap.png",
        "app_store_url": "https://apps.apple.com/app/amap/id461703208",
        "setup_steps": [
            "📲 Step 1: Install Amap\nSearch for \"高德地图\" or \"Amap\" by AutoNavi in the App Store. Install and open the app.",
            "📍 Step 2: Grant Location Permission\nWhen prompted, tap \"Allow While Using App\" for location access. This is essential for navigation and nearby search.",
            "🔍 Step 3: Search for a Destination\nTap the search bar at the top of the screen. Type a place name (e.g. \"故宫\" or \"The Palace Museum\") or an address. Tap the result to see it on the map.",
            "🚇 Step 4: Choose Transport Mode\nBelow the destination name, choose between: Driving (🚗), Transit (🚇), Walking (🚶), or Taxi (🚕). The app shows estimated time and fare.",
            "📶 Step 5: Download Offline Maps (Recommended)\nGo to \"Me\" > \"Offline Maps\" (离线地图). Search for cities you plan to visit and tap the download button. Each city is ~150-300 MB.",
        ],
    },
    {
        "name": "DiDi",
        "tagline": "Ride-hailing across China — cars, taxis, and more",
        "icon_name": "local_taxi",
        "color_hex": "#FF7A00",
        "category": "Transport",
        "image_asset_path": "assets/images/apps/didi.png",
        "app_store_url": "https://apps.apple.com/app/didi/id1163783616",
        "setup_steps": [
            "📲 Step 1: Install DiDi\nDownload \"DiDi\" or \"滴滴出行\" by Xiaoju Kuaizhi from the App Store.",
            "📞 Step 2: Register with Phone\nOpen the app and tap \"Register\". Enter your phone number, tap \"Get Code\", and enter the SMS verification.",
            "🌐 Step 3: Switch to English\nGo to \"Me\" (我的) > Settings (⚙) > Language. Select \"English\". The whole interface will switch immediately.",
            "💳 Step 4: Link a Payment Method\nGo to \"Me\" > \"Wallet\" > \"Add Payment Method\". You can add Alipay, WeChat Pay, or an international credit card.",
            "🚗 Step 5: Request Your First Ride\nTap \"Where to?\" on the home screen. Enter your destination, choose a ride type (Express ¥ / Premier / Taxi), and tap \"Confirm\". Wait for your driver to arrive.",
        ],
    },
    {
        "name": "Meituan",
        "tagline": "Food delivery, restaurant bookings, and local deals",
        "icon_name": "delivery_dining",
        "color_hex": "#FFC300",
        "category": "Food",
        "image_asset_path": "assets/images/apps/meituan.png",
        "app_store_url": "https://apps.apple.com/app/meituan/id423084790",
        "setup_steps": [
            "📲 Step 1: Install Meituan\nSearch for \"美团\" or \"Meituan\" by Beijing Sankuai in the App Store. Install and open.",
            "📞 Step 2: Register\nTap \"Register\" on the welcome screen. Enter your phone number and the SMS code. Create a nickname.",
            "📍 Step 3: Set Delivery Address\nTap the address bar at the top of the home screen. Type your hotel or current address and tap \"Save\". This will be used for food delivery.",
            "🍜 Step 4: Order Food\nTap the \"Food\" (美食) tab. Browse recommended restaurants nearby. Tap a restaurant to view their menu, add items to your cart, and tap \"Submit Order\" (提交订单).",
            "💳 Step 5: Pay & Track Delivery\nChoose Alipay or WeChat Pay at checkout. After payment, you can track your delivery in real-time on the order page. Average delivery time: 30-45 minutes.",
        ],
    },
    {
        "name": "12306",
        "tagline": "Official train ticket booking for high-speed and regular trains",
        "icon_name": "train",
        "color_hex": "#2B6CB0",
        "category": "Transport",
        "image_asset_path": "assets/images/apps/12306.png",
        "app_store_url": "https://apps.apple.com/app/12306/id564381888",
        "setup_steps": [
            "📲 Step 1: Install 12306\nSearch for \"铁路12306\" by China Railway in the App Store. Install and open.",
            "📝 Step 2: Register Account\nTap \"Register\" (注册). Enter your phone number, create a password (8-16 characters with letters + numbers), and complete the puzzle CAPTCHA.",
            "🛂 Step 3: Add Passport Information\nGo to \"My\" (我的) > \"Passengers\" (乘车人) > \"Add\" (添加). Enter your full name (as on passport), passport number, nationality, and date of birth. Foreigners MUST use their passport number.",
            "🔍 Step 4: Search & Book a Train\nEnter your departure city (出发) and arrival city (到达). Select your travel date and tap \"Search\" (查询). Browse the list — note the train number, departure time, duration, and price.",
            "✅ Step 5: Pay & Board\nSelect a train and seat type (二等座=Second Class, 一等座=First Class, 商务座=Business). Add passengers, confirm, and pay with Alipay or WeChat Pay. At the station, scan your passport at the gate or collect a paper ticket at the machine.",
        ],
    },
]


def get_apps(category: str | None = None) -> list[dict]:
    if category:
        return [a for a in CHINA_APPS if a["category"] == category]
    return CHINA_APPS


def get_categories() -> list[str]:
    seen = []
    for a in CHINA_APPS:
        if a["category"] not in seen:
            seen.append(a["category"])
    return seen
