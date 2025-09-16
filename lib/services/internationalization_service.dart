import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

/// Internationalization service for MedRefer AI
class InternationalizationService {
  static final InternationalizationService _instance = InternationalizationService._internal();
  factory InternationalizationService() => _instance;
  InternationalizationService._internal();

  final LoggingService _loggingService = LoggingService();
  bool _isInitialized = false;
  String _currentLanguage = 'en';
  String _currentCountry = 'US';
  Locale _currentLocale = Locale('en', 'US');

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  // Getters
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  String get currentCountry => _currentCountry;
  Locale get currentLocale => _currentLocale;

  /// Initialize the internationalization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadUserPreferences();
      _isInitialized = true;
      
      _loggingService.info('Internationalization service initialized', context: 'I18n', metadata: {
        'language': _currentLanguage,
        'country': _currentCountry,
      });
    } catch (e) {
      _loggingService.error('Failed to initialize internationalization service', context: 'I18n', error: e);
      rethrow;
    }
  }

  /// Load user preferences
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('i18n_language') ?? 'en';
      _currentCountry = prefs.getString('i18n_country') ?? 'US';
      _currentLocale = Locale(_currentLanguage, _currentCountry);
    } catch (e) {
      _loggingService.error('Failed to load user i18n preferences', context: 'I18n', error: e);
    }
  }

  /// Set current language
  Future<void> setLanguage(String language) async {
    if (!supportedLanguages.containsKey(language)) {
      throw ArgumentError('Unsupported language: $language');
    }

    try {
      _currentLanguage = language;
      _currentLocale = Locale(_currentLanguage, _currentCountry);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('i18n_language', language);
      
      _loggingService.info('Language changed to $language', context: 'I18n');
    } catch (e) {
      _loggingService.error('Failed to set language', context: 'I18n', error: e);
      rethrow;
    }
  }

  /// Set current country
  Future<void> setCountry(String country) async {
    try {
      _currentCountry = country;
      _currentLocale = Locale(_currentLanguage, _currentCountry);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('i18n_country', country);
      
      _loggingService.info('Country changed to $country', context: 'I18n');
    } catch (e) {
      _loggingService.error('Failed to set country', context: 'I18n', error: e);
      rethrow;
    }
  }

  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguages.containsKey(locale.languageCode)) {
      throw ArgumentError('Unsupported language: ${locale.languageCode}');
    }

    try {
      _currentLanguage = locale.languageCode;
      _currentCountry = locale.countryCode ?? 'US';
      _currentLocale = locale;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('i18n_language', _currentLanguage);
      await prefs.setString('i18n_country', _currentCountry);
      
      _loggingService.info('Locale changed to ${locale.languageCode}_${locale.countryCode}', context: 'I18n');
    } catch (e) {
      _loggingService.error('Failed to set locale', context: 'I18n', error: e);
      rethrow;
    }
  }

  /// Get localized text
  String getText(String key, {Map<String, dynamic>? params}) {
    // This would typically use a localization package like flutter_localizations
    // For now, we'll return the key as a placeholder
    return _getLocalizedText(key, params);
  }

  /// Get localized text implementation
  String _getLocalizedText(String key, Map<String, dynamic>? params) {
    // Placeholder implementation - in a real app, this would use proper localization
    String text = key;
    
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value.toString());
      });
    }
    
    return text;
  }

  /// Get supported locales
  List<Locale> getSupportedLocales() {
    return supportedLanguages.keys.map((language) => Locale(language)).toList();
  }

  /// Check if language is supported
  bool isLanguageSupported(String language) {
    return supportedLanguages.containsKey(language);
  }

  /// Get language name
  String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  /// Get current language name
  String get currentLanguageName => getLanguageName(_currentLanguage);

  /// Get locale settings
  Map<String, dynamic> getLocaleSettings() {
    return {
      'language': _currentLanguage,
      'country': _currentCountry,
      'locale': '${_currentLanguage}_$_currentCountry',
      'languageName': currentLanguageName,
    };
  }
}
