// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.g.dart';

typedef LanguageChangeCallback = void Function(AppLocale locale);

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  AppLocale? _locale;
  final Map<String, AppLocale> _languageMap = {
    'zh_CN': AppLocale.zh,
    'zh_TW': AppLocale.zhTw,
    'en': AppLocale.en,
    'ru': AppLocale.ru,
  };

  final List<LanguageChangeCallback> _onLanguageChanged = [];

  AppLocale? get locale => _locale;
  bool get isSystemLanguage => _locale == null;

  static Future<LanguageProvider> create() async {
    final provider = LanguageProvider();
    await provider._init();
    return provider;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_languageKey);

    if (savedLang != null && _languageMap.containsKey(savedLang)) {
      _locale = _languageMap[savedLang];
    } else {
      _locale = _detectSystemLocale();
    }

    if (_locale != null) {
      LocaleSettings.setLocale(_locale!);
    }
  }

  AppLocale? _detectSystemLocale() {
    try {
      final localeName = Platform.localeName;
      final normalized = localeName
          .replaceAll('-', '_')
          .replaceAll(';', '_')
          .split('_')
          .join('_');

      if (normalized.startsWith('zh') &&
          (normalized.contains('TW') ||
              normalized.contains('HK') ||
              normalized.contains('Hant'))) {
        return AppLocale.zhTw;
      } else if (normalized.startsWith('zh')) {
        return AppLocale.zh;
      } else if (normalized.startsWith('ru')) {
        return AppLocale.ru;
      } else if (normalized.startsWith('en')) {
        return AppLocale.en;
      }
    } catch (_) {}
    return AppLocale.zh;
  }

  /// Register a callback to be notified when language changes
  void onLanguageChanged(LanguageChangeCallback callback) {
    _onLanguageChanged.add(callback);
  }

  Future<void> setLanguage(String? langCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (langCode == null) {
      _locale = _detectSystemLocale();
      await prefs.remove(_languageKey);
    } else {
      _locale = _languageMap[langCode];
      if (_locale != null) {
        await prefs.setString(_languageKey, langCode);
      }
    }

    if (_locale != null) {
      LocaleSettings.setLocale(_locale!);
      // Notify all registered callbacks
      for (final cb in _onLanguageChanged) {
        cb(_locale!);
      }
    }
    notifyListeners();
  }

  String getLanguageLabel(AppLocale locale) {
    switch (locale) {
      case AppLocale.zh:
        return '简体中文';
      case AppLocale.zhTw:
        return '繁體中文';
      case AppLocale.en:
        return 'English';
      case AppLocale.ru:
        return 'Русский';
    }
  }

  String? getLanguageCode(AppLocale locale) {
    switch (locale) {
      case AppLocale.zh:
        return 'zh_CN';
      case AppLocale.zhTw:
        return 'zh_TW';
      case AppLocale.en:
        return 'en';
      case AppLocale.ru:
        return 'ru';
    }
  }

  List<MapEntry<String, AppLocale>> get availableLanguages {
    return _languageMap.entries.toList();
  }
}
