import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/ai_service.dart';

/// Live translation state for the Mic page.
///
/// Key behaviour from the spec: the conversation context is kept *while the
/// user is on the Mic page* (so "there" resolves against earlier turns), then
/// **reset when they leave**. Call [resetContext] from the page's dispose.
class MicProvider extends ChangeNotifier {
  final List<TranslationTurn> _turns = [];
  bool _busy = false;

  // Two-language pair for the session.
  AppLanguage _sideA = AppLanguage.all.first; // tourist side (e.g. English)
  AppLanguage _sideB =
      AppLanguage.all.firstWhere((l) => l.code == 'zh'); // local side (Chinese)

  List<TranslationTurn> get turns => List.unmodifiable(_turns);
  bool get busy => _busy;
  AppLanguage get sideA => _sideA;
  AppLanguage get sideB => _sideB;

  void setSideA(AppLanguage l) { _sideA = l; notifyListeners(); }
  void setSideB(AppLanguage l) { _sideB = l; notifyListeners(); }
  void swapSides() {
    final t = _sideA; _sideA = _sideB; _sideB = t; notifyListeners();
  }

  /// The rolling context handed to the translator so pronouns resolve.
  List<String> get _context =>
      _turns.map((t) => '${t.sourceText} → ${t.translatedText}').toList();

  /// Translate a spoken/typed phrase. [fromUserSide] true = tourist speaking.
  Future<void> addTurn(String text, {required bool fromUserSide}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;

    final from = fromUserSide ? _sideA : _sideB;
    final to = fromUserSide ? _sideB : _sideA;

    _busy = true;
    notifyListeners();

    final translated = await AiService.instance.translate(
      trimmed,
      from: from.name,
      to: to.name,
      context: _context,
    );

    _turns.add(TranslationTurn(
      sourceText: trimmed,
      translatedText: translated,
      sourceLang: from.name,
      targetLang: to.name,
      fromUserSide: fromUserSide,
    ));
    _busy = false;
    notifyListeners();
  }

  /// Simulate speaking into the mic (prototype returns a canned phrase).
  Future<void> listen({required bool fromUserSide}) async {
    final lang = fromUserSide ? _sideA : _sideB;
    _busy = true;
    notifyListeners();
    final heard = await AiService.instance.speechToText(language: lang.name);
    _busy = false;
    notifyListeners();
    await addTurn(heard, fromUserSide: fromUserSide);
  }

  Future<void> play(String text, {required String language}) =>
      AiService.instance.speak(text, language: language);

  /// Clears temporary conversation memory — call when leaving the Mic page.
  void resetContext() {
    _turns.clear();
    _busy = false;
    // notifyListeners intentionally omitted: page is being disposed.
  }
}
