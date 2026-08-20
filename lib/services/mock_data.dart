import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Data service that fetches from the backend API.
/// Falls back to minimal local data when the server is unreachable.
class MockData {
  MockData._();
  static final _client = ApiClient.instance;

  static WeatherSnapshot weather = const WeatherSnapshot(tempC: 28, aqi: 42, uv: 6, condition: 'Partly cloudy');

  static Future<WeatherSnapshot> fetchWeather() async {
    try {
      final res = await _client.get('/api/weather/');
      return WeatherSnapshot(
        tempC: res.data['temp_c'] ?? 28,
        aqi: res.data['aqi'] ?? 42,
        uv: res.data['uv'] ?? 6,
        condition: res.data['condition'] ?? 'Partly cloudy',
      );
    } catch (_) { return weather; }
  }

  static Future<List<ChinaApp>> fetchPocketApps({String? category}) async {
    try {
      final path = category != null ? '/api/pocket/apps?category=' : '/api/pocket/apps';
      final res = await _client.get(path);
      final list = res.data as List;
      return list.map((a) => ChinaApp(
        name: a['name'] ?? '',
        tagline: a['tagline'] ?? '',
        icon: _iconFor(a['icon_name'] ?? ''),
        color: _colorFor(a['color_hex'] ?? '#000000'),
        category: a['category'] ?? '',
        setupSteps: ((a['setup_steps'] as List<dynamic>?) ?? [])
            .map((s) => SetupStep(instruction: s.toString()))
            .toList(),
        imageAssetPath: a['image_asset_path'] as String?,
        appStoreUrl: a['app_store_url'] as String? ?? '',
      )).toList();
    } catch (_) { return _localApps; }
  }

  static Future<List<String>> fetchPocketCategories() async {
    try {
      final res = await _client.get('/api/pocket/categories');
      return List<String>.from(res.data);
    } catch (_) { return _localCategories; }
  }

  static Future<List<NearbyTourist>> fetchNearbyTourists() async {
    try {
      final res = await _client.get('/api/radar/nearby');
      final list = res.data as List;
      return list.map((t) => NearbyTourist(
        nickname: t['nickname'] ?? '',
        country: t['country'] ?? '',
        flag: t['flag'] ?? '',
        distanceMeters: t['distance_meters'] ?? 0,
        languages: List<String>.from(t['languages'] ?? []),
        interests: List<String>.from(t['interests'] ?? []),
        online: t['online'] ?? false,
        avatarColor: _colorFor(t['avatar_color'] ?? '#06B6D4'),
        dx: (t['dx'] ?? 0.0).toDouble(),
        dy: (t['dy'] ?? 0.0).toDouble(),
      )).toList();
    } catch (_) { return []; }
  }

  static IconData _iconFor(String name) {
    const map = {
      'account_balance_wallet': Icons.account_balance_wallet, 'chat_bubble': Icons.chat_bubble,
      'map': Icons.map, 'local_taxi': Icons.local_taxi, 'delivery_dining': Icons.delivery_dining,
      'train': Icons.train, 'reviews': Icons.reviews, 'pin_drop': Icons.pin_drop,
      'backpack': Icons.backpack,
    };
    return map[name] ?? Icons.apps;
  }

  static Color _colorFor(String hex) {
    try { return Color(int.parse('0xFF' + hex.replaceAll('#', ''))); } catch (_) { return Colors.blue; }
  }

  static const List<ChinaApp> _localApps = [
    ChinaApp(
      name: 'Alipay',
      tagline: 'Pay for almost anything — scan QR codes at shops, restaurants, and markets',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF1677FF),
      category: 'Payments',
      imageAssetPath: 'assets/images/apps/alipay.png',
      appStoreUrl: 'https://apps.apple.com/app/alipay/id333206289',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Download & Install\nOpen the App Store and search for "Alipay" by Ant Group. Tap "Get" and wait for installation.'),
        SetupStep(instruction: '👤 Step 2: Register Account\nOn the welcome screen, tap "Register". Enter your phone number and the SMS code sent to you.'),
        SetupStep(instruction: '💳 Step 3: Add International Card\nGo to "Me" > "Bank Cards" > "+". Enter your Visa/Mastercard details.'),
        SetupStep(instruction: '🪪 Step 4: Verify with Passport\nGo to "Me" > "Settings" > "Account" > "Real-name Verification". Take a photo of your passport.'),
        SetupStep(instruction: '✅ Step 5: Top Up & Start Paying\nGo to "Me" > "Balance" > "Top Up" and choose your international card.'),
      ],
    ),
    ChinaApp(
      name: 'WeChat',
      tagline: 'Messaging, payments, mini-programs',
      icon: Icons.chat_bubble,
      color: Color(0xFF07C160),
      category: 'Payments',
      imageAssetPath: 'assets/images/apps/wechat.png',
      appStoreUrl: 'https://apps.apple.com/app/wechat/id414478124',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Install WeChat\nDownload from App Store, open and tap "Sign Up".'),
        SetupStep(instruction: '📝 Step 2: Create Account\nEnter name, phone number, and SMS code.'),
        SetupStep(instruction: '🔐 Step 3: Friend Verification\nAsk someone in China to scan your QR code to verify you.'),
        SetupStep(instruction: '💳 Step 4: Add Payment Method\nGo to Me > Services > Wallet > Cards.'),
        SetupStep(instruction: '🛡️ Step 5: Security\nSet a pay password and enable face/fingerprint ID.'),
      ],
    ),
    ChinaApp(
      name: 'Amap (Gaode)',
      tagline: 'Detailed maps and navigation optimized for China',
      icon: Icons.map,
      color: Color(0xFF00A3FF),
      category: 'Maps',
      imageAssetPath: 'assets/images/apps/amap.png',
      appStoreUrl: 'https://apps.apple.com/app/amap/id461703208',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Install Amap\nSearch for "高德地图" in the App Store.'),
        SetupStep(instruction: '📍 Step 2: Grant Location Permission\nTap "Allow While Using App".'),
        SetupStep(instruction: '🔍 Step 3: Search Destinations\nType a place name to see it on the map.'),
        SetupStep(instruction: '🚇 Step 4: Choose Transport Mode\nPick Driving, Transit, Walking, or Taxi.'),
        SetupStep(instruction: '📶 Step 5: Download Offline Maps\nGo to Me > Offline Maps and select cities.'),
      ],
    ),
    ChinaApp(
      name: 'DiDi',
      tagline: 'Ride-hailing across China',
      icon: Icons.local_taxi,
      color: Color(0xFFFF7A00),
      category: 'Transport',
      imageAssetPath: 'assets/images/apps/didi.png',
      appStoreUrl: 'https://apps.apple.com/app/didi/id1163783616',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Install DiDi\nDownload from App Store and open.'),
        SetupStep(instruction: '🌐 Step 2: Switch to English\nGo to Me > Settings > Language > English.'),
        SetupStep(instruction: '💳 Step 3: Link Payment\nGo to Me > Wallet > Add Payment Method.'),
        SetupStep(instruction: '🚗 Step 4: Request a Ride\nTap "Where to?", enter destination, confirm.'),
      ],
    ),
    ChinaApp(
      name: 'Meituan',
      tagline: 'Food delivery and local deals',
      icon: Icons.delivery_dining,
      color: Color(0xFFFFC300),
      category: 'Food',
      imageAssetPath: 'assets/images/apps/meituan.png',
      appStoreUrl: 'https://apps.apple.com/app/meituan/id423084790',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Install Meituan\nDownload from App Store.'),
        SetupStep(instruction: '📍 Step 2: Set Delivery Address\nTap the address bar and enter your location.'),
        SetupStep(instruction: '🍜 Step 3: Order Food\nBrowse restaurants, add items, submit order.'),
        SetupStep(instruction: '💳 Step 4: Pay & Track\nChoose Alipay/WeChat Pay and track delivery.'),
      ],
    ),
    ChinaApp(
      name: '12306',
      tagline: 'Official train ticket booking',
      icon: Icons.train,
      color: Color(0xFF2B6CB0),
      category: 'Transport',
      imageAssetPath: 'assets/images/apps/12306.png',
      appStoreUrl: 'https://apps.apple.com/app/12306/id564381888',
      setupSteps: [
        SetupStep(instruction: '📲 Step 1: Install 12306\nSearch for "铁路12306" in App Store.'),
        SetupStep(instruction: '🛂 Step 2: Add Passport\nGo to My > Passengers > Add. Enter passport details.'),
        SetupStep(instruction: '🔍 Step 3: Search Trains\nEnter departure & arrival cities, select date.'),
        SetupStep(instruction: '✅ Step 4: Book & Pay\nChoose seat type, pay with Alipay/WeChat.'),
      ],
    ),
  ];

  static List<String> get _localCategories => ['Payments', 'Maps', 'Transport', 'Food'];
}
