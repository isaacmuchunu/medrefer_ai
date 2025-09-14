import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

/// Accessibility service for MedRefer AI
class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final LoggingService _loggingService = LoggingService();
  bool _isInitialized = false;
  bool _isScreenReaderEnabled = false;
  String _preferredLanguage = 'en';

  bool get isInitialized => _isInitialized;
  bool get isScreenReaderEnabled => _isScreenReaderEnabled;
  String get preferredLanguage => _preferredLanguage;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferredLanguage = prefs.getString('accessibility_language') ?? 'en';
      _isInitialized = true;
      
      _loggingService.info('Accessibility service initialized', context: 'Accessibility');
    } catch (e) {
      _loggingService.error('Failed to initialize accessibility service', context: 'Accessibility', error: e);
    }
  }

  Future<void> setPreferredLanguage(String language) async {
    try {
      _preferredLanguage = language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessibility_language', language);
      
      _loggingService.info('Preferred language set to $language', context: 'Accessibility');
    } catch (e) {
      _loggingService.error('Failed to set preferred language', context: 'Accessibility', error: e);
    }
  }

  String getAccessibleText(String text, {String? context}) {
    if (!_isScreenReaderEnabled) return text;
    return context != null ? '$context: $text' : text;
  }

  String getAccessibleButtonText(String text, {String? action}) {
    if (!_isScreenReaderEnabled) return text;
    return action != null ? '$text button. $action' : '$text button';
  }
}
