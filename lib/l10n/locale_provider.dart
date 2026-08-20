import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_translations.dart';

/// Provides access to translated strings based on the current language code.
///
/// Usage in any widget:
///   context.t('key')
class LocaleProvider extends ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  void setLanguage(String code) {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
  }

  /// Shorthand to get a translated string.
  String t(String key) => AppTranslations.get(key, _languageCode);
}

/// Extension on BuildContext for convenient access.
extension LocaleX on BuildContext {
  /// Returns the translated string for [key] in the current locale.
  /// Must be used in a widget tree that has a LocaleProvider ancestor.
  String t(String key) => read<LocaleProvider>().t(key);
}
