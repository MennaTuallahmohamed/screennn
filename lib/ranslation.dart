import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class TranslationService {
  static late Locale _locale;
  static late Map<String, String> _localizedStrings;

  static Future<void> load(Locale locale) async {
    _locale = locale;
    String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static String tr(String key) {
    return _localizedStrings[key] ?? key;
  }

  static Locale get locale => _locale;
}
