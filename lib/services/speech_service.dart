import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Wraps the browser/device speech engines for the Mic page.
///
/// - Text-to-speech (speaker) via flutter_tts.
/// - Speech-to-text (microphone) via speech_to_text.
///
/// Both run locally in the browser/device — they do NOT go through the backend.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;

  /// Map our short language codes (en, zh…) to full BCP-47 locale tags that
  /// the speech engines expect (en-US, zh-CN…).
  static const Map<String, String> _locale = {
    'en': 'en-US',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'hi': 'hi-IN',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'ar': 'ar-SA',
    'de': 'de-DE',
    'zh': 'zh-CN',
  };

  String _toLocale(String codeOrName) {
    // Accept either a short code ('zh') or a display name ('Chinese').
    final lower = codeOrName.toLowerCase();
    if (_locale.containsKey(lower)) return _locale[lower]!;
    // Try to match a display name to a code.
    const names = {
      'english': 'en', 'spanish': 'es', 'french': 'fr', 'hindi': 'hi',
      'japanese': 'ja', 'korean': 'ko', 'arabic': 'ar', 'german': 'de',
      'chinese': 'zh',
    };
    final code = names[lower];
    return _locale[code] ?? 'en-US';
  }

  // ---- Speaker (TTS) ----

  /// Speak [text] aloud in the given language (short code or display name).
  /// Returns true if a matching voice was found and speech started; false if
  /// no voice is available for that language on this device.
  Future<bool> speak(String text, {required String language}) async {
    if (text.trim().isEmpty) return true;
    final locale = _toLocale(language);

    // Check the device actually has a voice for this language.
    final available = await _hasVoiceFor(locale);
    if (!available) return false;

    await _tts.stop();
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5); // a touch slower, clearer for travellers
    await _tts.setPitch(1.0);
    await _tts.speak(text);
    return true;
  }

  /// Whether a voice exists for [locale] (matches by language prefix, e.g. zh).
  Future<bool> _hasVoiceFor(String locale) async {
    try {
      final langs = await _tts.getLanguages;
      if (langs is List) {
        final prefix = locale.split('-').first.toLowerCase();
        return langs.any((l) =>
            l.toString().toLowerCase().startsWith(prefix));
      }
    } catch (_) {}
    return true; // if we can't tell, optimistically try to speak
  }

  Future<void> stopSpeaking() => _tts.stop();

  // ---- Microphone (STT) ----

  /// Initialise the speech recogniser once. Returns true if available.
  Future<bool> initStt() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(
      onError: (e) => print('[STT error] $e'),
      onStatus: (s) => print('[STT status] $s'),
    );
    return _sttReady;
  }

  bool get isListening => _stt.isListening;

  /// Start listening. [onResult] is called with the recognised text (updated
  /// live as the user speaks). Call [stopListening] to finish.
  Future<bool> startListening({
    required String language,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    final ok = await initStt();
    if (!ok) return false;
    final locale = _toLocale(language);
    await _stt.listen(
      localeId: locale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      onResult: (SpeechRecognitionResult r) {
        onResult(r.recognizedWords, r.finalResult);
      },
    );
    return true;
  }

  Future<void> stopListening() => _stt.stop();
}
