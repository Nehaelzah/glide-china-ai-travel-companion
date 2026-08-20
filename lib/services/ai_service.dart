import 'dart:async';
import 'api_client.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();
  final _client = ApiClient.instance;

  Future<String> ask(String prompt, {String language = 'English', int? weatherTempC, String? weatherCondition, int? weatherAqi, int? weatherUv, String? mood, Set<String>? dietaryRestrictions, double? latitude, double? longitude, String? locationName}) async {
    try {
      final data = <String, dynamic>{
        'message': prompt,
        'language': language,
        'weather_temp_c': weatherTempC,
        'weather_condition': weatherCondition,
        'weather_aqi': weatherAqi,
        'weather_uv': weatherUv,
        'mood': mood,
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
      };
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        data['dietary_restrictions'] = dietaryRestrictions.toList();
      } else {
        data['dietary_restrictions'] = [];
      }
      final res = await _client.post('/api/chat/ask', data: data);
      return res.data['reply'] ?? 'Sorry, I could not process that request.';
    } catch (_) { return 'Sorry, I am having trouble connecting right now. Please try again later.'; }
  }

  Future<String> translate(String text, {required String from, required String to, List<String> context = const []}) async {
    try {
      final res = await _client.post('/api/translate/', data: {'text': text, 'from_lang': from, 'to_lang': to, 'context': context});
      return res.data['translated_text'] ?? text;
    } catch (_) { return text; }
  }

  Future<String> speechToText({required String language}) async {
    try {
      final res = await _client.post('/api/speech/stt', data: {'language': language});
      return res.data['text'] ?? '';
    } catch (_) { return ''; }
  }

  Future<void> speak(String text, {String language = 'English'}) async {
    try { await _client.post('/api/speech/tts', data: {'text': text, 'language': language}); } catch (_) {}
  }
}