import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/ai_service.dart';

/// Holds the AI chat conversation on the Chat/Home page.
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _thinking = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;

  /// Safely map Chinese weather conditions to English.
  static String _normalizeCondition(String? text) {
    if (text == null) return 'Cloudy';
    const map = <String, String>{
      '晴': 'Sunny',
      '少云': 'Mostly Clear',
      '晴间多云': 'Partly Cloudy',
      '多云': 'Cloudy',
      '阴': 'Overcast',
      '有风': 'Windy',
      '微风': 'Light Breeze',
      '和风': 'Gentle Breeze',
      '清风': 'Moderate Breeze',
      '强风/劲风': 'Strong Breeze',
      '疾风': 'Near Gale',
      '大风': 'Gale',
      '烈风': 'Strong Gale',
      '风暴': 'Storm',
      '狂爆风': 'Violent Storm',
      '飓风': 'Hurricane',
      '热带风暴': 'Tropical Storm',
      '霾': 'Haze',
      '中度霾': 'Moderate Haze',
      '重度霾': 'Heavy Haze',
      '严重霾': 'Severe Haze',
      '阵雨': 'Rain Showers',
      '雷阵雨': 'Thundershowers',
      '雷阵雨伴有冰雹': 'Thundershowers with Hail',
      '小雨': 'Light Rain',
      '中雨': 'Moderate Rain',
      '大雨': 'Heavy Rain',
      '暴雨': 'Rainstorm',
      '大暴雨': 'Heavy Rainstorm',
      '特大暴雨': 'Extreme Rainstorm',
      '强阵雨': 'Heavy Showers',
      '极端降雨': 'Extreme Rain',
      '毛毛雨': 'Drizzle',
      '细雨': 'Drizzle',
      '雨': 'Rain',
      '小雪': 'Light Snow',
      '中雪': 'Moderate Snow',
      '大雪': 'Heavy Snow',
      '暴雪': 'Snowstorm',
      '雨夹雪': 'Sleet',
      '阵雪': 'Snow Showers',
      '雾': 'Foggy',
      '薄雾': 'Mist',
      '浓雾': 'Dense Fog',
      '冻雨': 'Freezing Rain',
      '扬沙': 'Blowing Sand',
      '浮尘': 'Floating Dust',
      '沙尘暴': 'Sandstorm',
      '强沙尘暴': 'Severe Sandstorm',
      '龙卷风': 'Tornado',
      '冷': 'Cold',
      '热': 'Hot',
    };
    return map[text] ?? text;
  }

  /// Clean the location label before showing it in the greeting.
  ///
  /// This avoids hardcoding Shanghai/Beijing. If the app has a real GPS label,
  /// the greeting uses it. If location is unavailable, the greeting stays
  /// generic instead of guessing a city.
  static String? _cleanLocationName(String? locationName) {
    final value = locationName?.trim();
    if (value == null || value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower.contains('unavailable') ||
        lower.contains('permission not granted') ||
        lower.contains('permission denied')) {
      return null;
    }

    return value;
  }

  /// Seed the welcome greeting with username, real location, weather, and mood.
  void seedGreeting({
    String username = 'Traveller',
    WeatherSnapshot? weather,
    Mood? mood,
    bool firstTime = false,
    String? locationName,
  }) {
    if (_messages.isNotEmpty) return;

    final place = _cleanLocationName(locationName);
    final temp = weather?.tempC ?? 26;
    final condition = _normalizeCondition(weather?.condition);

    String weatherDesc;
    if (temp >= 30) {
      weatherDesc = '$temp°C, feels hot';
    } else if (temp >= 20) {
      weatherDesc = '$temp°C, comfortable';
    } else if (temp >= 10) {
      weatherDesc = '$temp°C, a bit cool';
    } else {
      weatherDesc = '$temp°C, quite cold';
    }

    String moodLine;
    if (mood != null) {
      switch (mood.label) {
        case 'Energetic':
          moodLine = 'So much energy today! Let\'s do something fun 🎉';
          break;
        case 'Chill':
          moodLine = 'We\'ll take it nice and slow ☕';
          break;
        case 'Tired':
          moodLine = 'Leave it to me, I\'ll keep it light today 🛋️';
          break;
        case 'Anxious':
          moodLine = 'Don\'t worry, one step at a time 💪';
          break;
        default:
          moodLine = 'Let\'s make today great!';
      }
    } else {
      moodLine = 'How are you feeling today? 😊';
    }

    final locationLine = place == null
        ? 'Today\'s weather: $condition, $weatherDesc\n'
        : 'Today near $place: $condition, $weatherDesc\n';

    final greeting = 'Hi $username! 👋\n'
        '$locationLine'
        '$moodLine\n'
        'Let\'s start today\'s plan! ✨';

    _messages.add(ChatMessage(fromUser: false, text: greeting));
    notifyListeners();
  }

  Future<void> send(
      String text, {
        String language = 'English',
        int? weatherTempC,
        String? weatherCondition,
        int? weatherAqi,
        int? weatherUv,
        String? mood,
        Set<String>? dietaryRestrictions,
        double? latitude,
        double? longitude,
        String? locationName,
      }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _thinking) return;

    _messages.add(ChatMessage(text: trimmed, fromUser: true));
    _thinking = true;
    notifyListeners();

    final reply = await AiService.instance.ask(
      trimmed,
      language: language,
      weatherTempC: weatherTempC,
      weatherCondition: _normalizeCondition(weatherCondition),
      weatherAqi: weatherAqi,
      weatherUv: weatherUv,
      mood: mood,
      dietaryRestrictions: dietaryRestrictions,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );

    final choices = ChatMessage.parseChoices(reply);
    _messages.add(ChatMessage(text: reply, fromUser: false, choices: choices));
    _thinking = false;
    notifyListeners();
  }

  Future<void> play(String text, {String language = 'English'}) async {
    await AiService.instance.speak(text, language: language);
  }

  /// Add a quick AI response (e.g. mood reply) without API call.
  void addAiMessage(String text) {
    _messages.add(ChatMessage(fromUser: false, text: text));
    notifyListeners();
  }
}
