// language_service.dart
// Singleton ChangeNotifier for i18n — same pattern as UnitsService.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/translations.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  static LanguageService get instance => _instance;

  LanguageService._internal();

  String _lang = 'es';
  String get lang => _lang;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('pep_language') ?? 'es';
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_lang == lang) return;
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pep_language', lang);
    notifyListeners();
  }

  /// Translate a key, optionally replacing `{param}` placeholders.
  String tr(String key, {Map<String, String>? params}) {
    final map = appTranslations[_lang] ?? appTranslations['es']!;
    String value = map[key] ?? appTranslations['es']?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v));
    }
    return value;
  }

  /// Locale string for DateFormat (intl).
  String get dateLocale {
    switch (_lang) {
      case 'en':
        return 'en';
      case 'pt':
        return 'pt_BR';
      default:
        return 'es';
    }
  }

  /// Locale string for TableCalendar.
  String get calendarLocale {
    switch (_lang) {
      case 'en':
        return 'en_US';
      case 'pt':
        return 'pt_BR';
      default:
        return 'es_ES';
    }
  }
}
