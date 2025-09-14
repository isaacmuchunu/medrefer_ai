import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../database/database_helper.dart';
import '../database/database.dart';

/// Comprehensive Accessibility Service with voice, screen reader, and navigation support
class AccessibilityService extends ChangeNotifier {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  // Voice components
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Configuration
  static const Duration _commandTimeout = Duration(seconds: 10);
  static const double _defaultSpeechRate = 0.5;
  static const double _defaultPitch = 1.0;
  static const double _defaultVolume = 1.0;
  
  // State management
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _speechEnabled = false;
  bool _ttsEnabled = false;
  
  // Accessibility settings
  AccessibilitySettings _settings = AccessibilitySettings();
  
  // Voice commands
  final Map<String, VoiceCommand> _voiceCommands = {};
  final List<String> _commandHistory = [];
  String _currentTranscript = '';
  String _lastCommand = '';
  
  // Screen reader
  final List<String> _screenReaderQueue = [];
  Timer? _screenReaderTimer;
  
  // Keyboard navigation
  final Map<ShortcutActivator, VoidCallback> _keyboardShortcuts = {};
  FocusNode? _currentFocus;
  final List<FocusNode> _focusHistory = [];
  
  // High contrast themes
  final Map<String, HighContrastTheme> _highContrastThemes = {};
  String _currentTheme = 'default';
  
  // Database
  Database? _database;
  
  // Analytics
  int _voiceCommandsExecuted = 0;
  int _ttsUtterances = 0;
  final Map<String, int> _featureUsage = {};

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;
  bool get ttsEnabled => _ttsEnabled;
  AccessibilitySettings get settings => _settings;
  String get currentTranscript => _currentTranscript;
  String get currentTheme => _currentTheme;

  /// Initialize accessibility service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _database = await DatabaseHelper().database;
      await _createAccessibilityTables();
      await _loadSettings();
      
      await _initializeSpeechRecognition();
      await _initializeTextToSpeech();
      _initializeVoiceCommands();
      _initializeKeyboardShortcuts();
      _initializeHighContrastThemes();
      
      _isInitialized = true;
      debugPrint('Accessibility Service initialized');
    } catch (e) {
      debugPrint('Error initializing Accessibility Service: $e');
      throw AccessibilityException('Failed to initialize accessibility service');
    }
  }

  /// Create database tables
  Future<void> _createAccessibilityTables() async {
    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS accessibility_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        voice_enabled INTEGER DEFAULT 1,
        tts_enabled INTEGER DEFAULT 1,
        screen_reader_enabled INTEGER DEFAULT 1,
        high_contrast_enabled INTEGER DEFAULT 0,
        keyboard_nav_enabled INTEGER DEFAULT 1,
        speech_rate REAL DEFAULT 0.5,
        pitch REAL DEFAULT 1.0,
        volume REAL DEFAULT 1.0,
        language TEXT DEFAULT 'en-US',
        theme TEXT DEFAULT 'default',
        font_size_multiplier REAL DEFAULT 1.0,
        reduce_animations INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS voice_command_history (
        id TEXT PRIMARY KEY,
        command TEXT NOT NULL,
        transcript TEXT NOT NULL,
        success INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        user_id TEXT
      )
    ''');

    await _database!.execute('''
      CREATE TABLE IF NOT EXISTS accessibility_analytics (
        id TEXT PRIMARY KEY,
        feature TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        last_used INTEGER,
        user_id TEXT
      )
    ''');
  }

  /// Initialize speech recognition
  Future<void> _initializeSpeechRecognition() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: kDebugMode,
      );
      
      if (_speechEnabled) {
        final locales = await _speechToText.locales();
        debugPrint('Available locales: ${locales.map((l) => l.localeId).join(', ')}');
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _speechEnabled = false;
    }
  }

  /// Initialize text-to-speech
  Future<void> _initializeTextToSpeech() async {
    try {
      _ttsEnabled = true;
      
      await _flutterTts.setLanguage(_settings.language);
      await _flutterTts.setSpeechRate(_settings.speechRate);
      await _flutterTts.setPitch(_settings.pitch);
      await _flutterTts.setVolume(_settings.volume);
      
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _processScreenReaderQueue();
        notifyListeners();
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
        notifyListeners();
      });
      
      // Get available voices
      final voices = await _flutterTts.getVoices;
      debugPrint('Available voices: ${voices.length}');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _ttsEnabled = false;
    }
  }

  /// Start voice recognition
  Future<void> startListening({
    Function(String)? onResult,
    VoidCallback? onComplete,
  }) async {
    if (!_speechEnabled || _isListening) return;
    
    try {
      _currentTranscript = '';
      _isListening = true;
      notifyListeners();
      
      await _speechToText.listen(
        onResult: (result) {
          _currentTranscript = result.recognizedWords;
          
          if (result.finalResult) {
            _processVoiceCommand(_currentTranscript);
            onResult?.call(_currentTranscript);
          }
          
          notifyListeners();
        },
        listenFor: _commandTimeout,
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: _settings.language,
      );
      
      // Auto-stop after timeout
      Future.delayed(_commandTimeout, () {
        if (_isListening) {
          stopListening();
          onComplete?.call();
        }
      });
    } catch (e) {
      debugPrint('Error starting voice recognition: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Stop voice recognition
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Speak text
  Future<void> speak(String text, {
    bool interrupt = true,
    SpeechPriority priority = SpeechPriority.normal,
  }) async {
    if (!_ttsEnabled || text.isEmpty) return;
    
    try {
      if (interrupt && _isSpeaking) {
        await _flutterTts.stop();
      }
      
      if (priority == SpeechPriority.high || !_isSpeaking) {
        _ttsUtterances++;
        await _flutterTts.speak(text);
      } else if (priority == SpeechPriority.queued) {
        _screenReaderQueue.add(text);
      }
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    
    await _flutterTts.stop();
    _screenReaderQueue.clear();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Register voice command
  void registerVoiceCommand({
    required String phrase,
    required VoidCallback action,
    List<String>? alternatives,
    String? description,
  }) {
    final command = VoiceCommand(
      phrase: phrase.toLowerCase(),
      action: action,
      alternatives: alternatives?.map((a) => a.toLowerCase()).toList() ?? [],
      description: description,
    );
    
    _voiceCommands[phrase.toLowerCase()] = command;
    
    // Register alternatives
    for (final alt in command.alternatives) {
      _voiceCommands[alt] = command;
    }
  }

  /// Process voice command
  Future<void> _processVoiceCommand(String transcript) async {
    final normalizedTranscript = transcript.toLowerCase().trim();
    _commandHistory.add(normalizedTranscript);
    
    // Direct command match
    if (_voiceCommands.containsKey(normalizedTranscript)) {
      await _executeVoiceCommand(_voiceCommands[normalizedTranscript]!);
      return;
    }
    
    // Fuzzy matching for commands
    for (final entry in _voiceCommands.entries) {
      if (_isFuzzyMatch(normalizedTranscript, entry.key)) {
        await _executeVoiceCommand(entry.value);
        return;
      }
    }
    
    // AI-powered command interpretation
    final aiCommand = await _interpretCommand(normalizedTranscript);
    if (aiCommand != null) {
      await _executeVoiceCommand(aiCommand);
      return;
    }
    
    // Command not recognized
    await speak('Command not recognized. Please try again.');
    await _saveCommandHistory(normalizedTranscript, false);
  }

  /// Execute voice command
  Future<void> _executeVoiceCommand(VoiceCommand command) async {
    try {
      command.action();
      _voiceCommandsExecuted++;
      _lastCommand = command.phrase;
      
      await speak('Command executed');
      await _saveCommandHistory(command.phrase, true);
      
      _trackFeatureUsage('voice_command');
    } catch (e) {
      debugPrint('Error executing voice command: $e');
      await speak('Error executing command');
      await _saveCommandHistory(command.phrase, false);
    }
  }

  /// Update accessibility settings
  Future<void> updateSettings({
    bool? voiceEnabled,
    bool? ttsEnabled,
    bool? screenReaderEnabled,
    bool? highContrastEnabled,
    bool? keyboardNavEnabled,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
    String? theme,
    double? fontSizeMultiplier,
    bool? reduceAnimations,
  }) async {
    _settings = _settings.copyWith(
      voiceEnabled: voiceEnabled,
      ttsEnabled: ttsEnabled,
      screenReaderEnabled: screenReaderEnabled,
      highContrastEnabled: highContrastEnabled,
      keyboardNavEnabled: keyboardNavEnabled,
      speechRate: speechRate,
      pitch: pitch,
      volume: volume,
      language: language,
      theme: theme,
      fontSizeMultiplier: fontSizeMultiplier,
      reduceAnimations: reduceAnimations,
    );
    
    // Apply TTS settings
    if (speechRate != null) {
      await _flutterTts.setSpeechRate(speechRate);
    }
    if (pitch != null) {
      await _flutterTts.setPitch(pitch);
    }
    if (volume != null) {
      await _flutterTts.setVolume(volume);
    }
    if (language != null) {
      await _flutterTts.setLanguage(language);
    }
    
    // Apply theme
    if (theme != null) {
      _currentTheme = theme;
    }
    
    await _saveSettings();
    notifyListeners();
  }

  /// Announce for screen reader
  void announce(String message, {
    bool important = false,
  }) {
    if (!_settings.screenReaderEnabled) return;
    
    if (important) {
      speak(message, priority: SpeechPriority.high);
    } else {
      _screenReaderQueue.add(message);
      _processScreenReaderQueue();
    }
  }

  /// Register keyboard shortcut
  void registerKeyboardShortcut({
    required ShortcutActivator activator,
    required VoidCallback action,
    String? description,
  }) {
    _keyboardShortcuts[activator] = action;
    
    if (description != null && _settings.screenReaderEnabled) {
      announce('Keyboard shortcut registered: $description');
    }
  }

  /// Handle keyboard event
  bool handleKeyEvent(KeyEvent event) {
    if (!_settings.keyboardNavEnabled) return false;
    
    for (final entry in _keyboardShortcuts.entries) {
      if (entry.key.accepts(event, HardwareKeyboard.instance)) {
        entry.value();
        _trackFeatureUsage('keyboard_shortcut');
        return true;
      }
    }
    
    return false;
  }

  /// Navigate by keyboard
  void navigateByKeyboard(NavigationDirection direction) {
    if (!_settings.keyboardNavEnabled) return;
    
    switch (direction) {
      case NavigationDirection.next:
        FocusScope.of(_getBuildContext()!).nextFocus();
        _announceFocusedElement();
        break;
      case NavigationDirection.previous:
        FocusScope.of(_getBuildContext()!).previousFocus();
        _announceFocusedElement();
        break;
      case NavigationDirection.up:
        FocusScope.of(_getBuildContext()!).focusInDirection(TraversalDirection.up);
        _announceFocusedElement();
        break;
      case NavigationDirection.down:
        FocusScope.of(_getBuildContext()!).focusInDirection(TraversalDirection.down);
        _announceFocusedElement();
        break;
    }
    
    _trackFeatureUsage('keyboard_navigation');
  }

  /// Apply high contrast theme
  ThemeData applyHighContrastTheme(ThemeData baseTheme) {
    if (!_settings.highContrastEnabled) return baseTheme;
    
    final highContrastTheme = _highContrastThemes[_currentTheme];
    if (highContrastTheme == null) return baseTheme;
    
    return baseTheme.copyWith(
      brightness: highContrastTheme.brightness,
      primaryColor: highContrastTheme.primaryColor,
      scaffoldBackgroundColor: highContrastTheme.backgroundColor,
      cardColor: highContrastTheme.surfaceColor,
      dividerColor: highContrastTheme.borderColor,
      textTheme: baseTheme.textTheme.apply(
        bodyColor: highContrastTheme.textColor,
        displayColor: highContrastTheme.textColor,
        decorationColor: highContrastTheme.textColor,
      ),
      iconTheme: IconThemeData(
        color: highContrastTheme.iconColor,
        size: 24 * _settings.fontSizeMultiplier,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: highContrastTheme.buttonTextColor,
          backgroundColor: highContrastTheme.buttonColor,
        ),
      ),
    );
  }

  /// Get accessibility hints for widget
  Map<String, dynamic> getAccessibilityHints({
    required String widgetType,
    String? label,
    String? hint,
    bool? isButton,
    bool? isTextField,
  }) {
    final hints = <String, dynamic>{};
    
    // Semantic label
    if (label != null) {
      hints['semanticLabel'] = label;
    }
    
    // Screen reader hint
    if (hint != null && _settings.screenReaderEnabled) {
      hints['hint'] = hint;
    }
    
    // Keyboard focus
    if (_settings.keyboardNavEnabled) {
      hints['canRequestFocus'] = true;
      hints['skipTraversal'] = false;
    }
    
    // Button hints
    if (isButton ?? false) {
      hints['button'] = true;
      hints['onTapHint'] = 'Double tap to activate';
    }
    
    // Text field hints
    if (isTextField ?? false) {
      hints['textField'] = true;
      hints['multiline'] = false;
      hints['maxValueLength'] = 500;
    }
    
    return hints;
  }

  /// Perform accessibility audit
  Future<AccessibilityAudit> performAudit() async {
    final issues = <AccessibilityIssue>[];
    final recommendations = <String>[];
    
    // Check color contrast
    if (!_settings.highContrastEnabled) {
      issues.add(AccessibilityIssue(
        type: IssueType.contrast,
        severity: IssueSeverity.medium,
        description: 'High contrast mode is disabled',
        recommendation: 'Enable high contrast for better visibility',
      ));
    }
    
    // Check font size
    if (_settings.fontSizeMultiplier < 1.2) {
      recommendations.add('Consider increasing font size for better readability');
    }
    
    // Check voice features
    if (!_speechEnabled) {
      issues.add(AccessibilityIssue(
        type: IssueType.voice,
        severity: IssueSeverity.low,
        description: 'Voice commands not available',
        recommendation: 'Check microphone permissions',
      ));
    }
    
    // Check screen reader
    if (!_settings.screenReaderEnabled && _ttsEnabled) {
      recommendations.add('Screen reader is available but not enabled');
    }
    
    // Check keyboard navigation
    if (!_settings.keyboardNavEnabled) {
      issues.add(AccessibilityIssue(
        type: IssueType.keyboard,
        severity: IssueSeverity.medium,
        description: 'Keyboard navigation is disabled',
        recommendation: 'Enable keyboard navigation for accessibility',
      ));
    }
    
    // Calculate score
    final score = _calculateAccessibilityScore(issues);
    
    return AccessibilityAudit(
      score: score,
      issues: issues,
      recommendations: recommendations,
      timestamp: DateTime.now(),
    );
  }

  // Private helper methods

  void _initializeVoiceCommands() {
    // Navigation commands
    registerVoiceCommand(
      phrase: 'go home',
      action: () => _navigateTo('/home'),
      alternatives: ['home', 'go to home', 'navigate home'],
      description: 'Navigate to home screen',
    );
    
    registerVoiceCommand(
      phrase: 'go back',
      action: () => _navigateBack(),
      alternatives: ['back', 'previous', 'go to previous'],
      description: 'Go back to previous screen',
    );
    
    // Search commands
    registerVoiceCommand(
      phrase: 'search',
      action: () => _openSearch(),
      alternatives: ['open search', 'find', 'search for'],
      description: 'Open search',
    );
    
    // Help commands
    registerVoiceCommand(
      phrase: 'help',
      action: () => _showHelp(),
      alternatives: ['show help', 'help me', 'what can you do'],
      description: 'Show help',
    );
    
    // Settings commands
    registerVoiceCommand(
      phrase: 'open settings',
      action: () => _navigateTo('/settings'),
      alternatives: ['settings', 'preferences', 'go to settings'],
      description: 'Open settings',
    );
  }

  void _initializeKeyboardShortcuts() {
    // Navigation shortcuts
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.escape),
      action: () => _navigateBack(),
      description: 'Go back',
    );
    
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.keyH, control: true),
      action: () => _navigateTo('/home'),
      description: 'Go to home',
    );
    
    // Search shortcut
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.keyF, control: true),
      action: () => _openSearch(),
      description: 'Open search',
    );
    
    // Accessibility shortcuts
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.keyA, alt: true),
      action: () => _toggleAccessibilityMenu(),
      description: 'Toggle accessibility menu',
    );
    
    // Tab navigation
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.tab),
      action: () => navigateByKeyboard(NavigationDirection.next),
      description: 'Next element',
    );
    
    registerKeyboardShortcut(
      activator: const SingleActivator(LogicalKeyboardKey.tab, shift: true),
      action: () => navigateByKeyboard(NavigationDirection.previous),
      description: 'Previous element',
    );
  }

  void _initializeHighContrastThemes() {
    // Dark high contrast
    _highContrastThemes['dark'] = HighContrastTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      backgroundColor: Colors.black,
      surfaceColor: Color(0xFF1A1A1A),
      textColor: Colors.white,
      iconColor: Colors.white,
      borderColor: Colors.white,
      buttonColor: Colors.white,
      buttonTextColor: Colors.black,
    );
    
    // Light high contrast
    _highContrastThemes['light'] = HighContrastTheme(
      brightness: Brightness.light,
      primaryColor: Colors.black,
      backgroundColor: Colors.white,
      surfaceColor: Color(0xFFF5F5F5),
      textColor: Colors.black,
      iconColor: Colors.black,
      borderColor: Colors.black,
      buttonColor: Colors.black,
      buttonTextColor: Colors.white,
    );
    
    // Blue high contrast
    _highContrastThemes['blue'] = HighContrastTheme(
      brightness: Brightness.dark,
      primaryColor: Colors.yellow,
      backgroundColor: Color(0xFF000080),
      surfaceColor: Color(0xFF000050),
      textColor: Colors.yellow,
      iconColor: Colors.yellow,
      borderColor: Colors.yellow,
      buttonColor: Colors.yellow,
      buttonTextColor: Color(0xFF000080),
    );
  }

  bool _isFuzzyMatch(String input, String command) {
    // Simple fuzzy matching
    if (input.contains(command) || command.contains(input)) {
      return true;
    }
    
    // Calculate similarity score
    final similarity = _calculateSimilarity(input, command);
    return similarity > 0.7;
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    int matches = 0;
    int transpositions = 0;
    
    final shorter = s1.length <= s2.length ? s1 : s2;
    final longer = s1.length > s2.length ? s1 : s2;
    
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }
    
    return matches / longer.length;
  }

  Future<VoiceCommand?> _interpretCommand(String transcript) async {
    // AI-powered command interpretation
    // This would connect to an NLP service in production
    
    // Simple keyword-based interpretation
    if (transcript.contains('navigate') || transcript.contains('go to')) {
      return VoiceCommand(
        phrase: transcript,
        action: () => _handleNavigationCommand(transcript),
        alternatives: [],
      );
    }
    
    if (transcript.contains('create') || transcript.contains('add')) {
      return VoiceCommand(
        phrase: transcript,
        action: () => _handleCreateCommand(transcript),
        alternatives: [],
      );
    }
    
    if (transcript.contains('show') || transcript.contains('display')) {
      return VoiceCommand(
        phrase: transcript,
        action: () => _handleShowCommand(transcript),
        alternatives: [],
      );
    }
    
    return null;
  }

  void _handleSpeechStatus(String status) {
    debugPrint('Speech status: $status');
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _handleSpeechError(dynamic error) {
    debugPrint('Speech error: $error');
    _isListening = false;
    notifyListeners();
  }

  void _processScreenReaderQueue() {
    if (_screenReaderQueue.isEmpty || _isSpeaking) return;
    
    final message = _screenReaderQueue.removeAt(0);
    speak(message, interrupt: false);
  }

  void _announceFocusedElement() {
    if (!_settings.screenReaderEnabled) return;
    
    // Get focused element details and announce
    final focusedWidget = FocusManager.instance.primaryFocus;
    if (focusedWidget != null) {
      announce('Focused on ${focusedWidget.debugLabel ?? 'element'}');
    }
  }

  BuildContext? _getBuildContext() {
    // This would be properly implemented with a NavigatorKey
    return null;
  }

  void _navigateTo(String route) {
    // Navigation implementation
    debugPrint('Navigate to: $route');
  }

  void _navigateBack() {
    // Navigation back implementation
    debugPrint('Navigate back');
  }

  void _openSearch() {
    // Open search implementation
    debugPrint('Open search');
  }

  void _showHelp() {
    // Show help implementation
    speak('Available voice commands: go home, go back, search, open settings, help');
  }

  void _toggleAccessibilityMenu() {
    // Toggle accessibility menu
    debugPrint('Toggle accessibility menu');
  }

  void _handleNavigationCommand(String transcript) {
    // Handle navigation commands
    debugPrint('Navigation command: $transcript');
  }

  void _handleCreateCommand(String transcript) {
    // Handle create commands
    debugPrint('Create command: $transcript');
  }

  void _handleShowCommand(String transcript) {
    // Handle show commands
    debugPrint('Show command: $transcript');
  }

  double _calculateAccessibilityScore(List<AccessibilityIssue> issues) {
    if (issues.isEmpty) return 100.0;
    
    double score = 100.0;
    
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          score -= 20;
          break;
        case IssueSeverity.high:
          score -= 15;
          break;
        case IssueSeverity.medium:
          score -= 10;
          break;
        case IssueSeverity.low:
          score -= 5;
          break;
      }
    }
    
    return score.clamp(0, 100);
  }

  void _trackFeatureUsage(String feature) {
    _featureUsage[feature] = (_featureUsage[feature] ?? 0) + 1;
    
    // Save to database
    _database?.execute('''
      INSERT OR REPLACE INTO accessibility_analytics (id, feature, usage_count, last_used)
      VALUES (?, ?, ?, ?)
    ''', [
      feature,
      feature,
      _featureUsage[feature],
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  Future<void> _saveCommandHistory(String command, bool success) async {
    await _database?.insert('voice_command_history', {
      'id': 'cmd_${DateTime.now().millisecondsSinceEpoch}',
      'command': command,
      'transcript': _currentTranscript,
      'success': success ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _loadSettings() async {
    final results = await _database!.query(
      'accessibility_settings',
      limit: 1,
      orderBy: 'updated_at DESC',
    );
    
    if (results.isNotEmpty) {
      _settings = AccessibilitySettings.fromMap(results.first);
    }
  }

  Future<void> _saveSettings() async {
    await _database!.insert(
      'accessibility_settings',
      _settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _screenReaderTimer?.cancel();
    super.dispose();
  }
}

// Data Models

class AccessibilitySettings {
  final bool voiceEnabled;
  final bool ttsEnabled;
  final bool screenReaderEnabled;
  final bool highContrastEnabled;
  final bool keyboardNavEnabled;
  final double speechRate;
  final double pitch;
  final double volume;
  final String language;
  final String theme;
  final double fontSizeMultiplier;
  final bool reduceAnimations;
  final DateTime updatedAt;

  AccessibilitySettings({
    this.voiceEnabled = true,
    this.ttsEnabled = true,
    this.screenReaderEnabled = true,
    this.highContrastEnabled = false,
    this.keyboardNavEnabled = true,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'en-US',
    this.theme = 'default',
    this.fontSizeMultiplier = 1.0,
    this.reduceAnimations = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  AccessibilitySettings copyWith({
    bool? voiceEnabled,
    bool? ttsEnabled,
    bool? screenReaderEnabled,
    bool? highContrastEnabled,
    bool? keyboardNavEnabled,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
    String? theme,
    double? fontSizeMultiplier,
    bool? reduceAnimations,
  }) {
    return AccessibilitySettings(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      keyboardNavEnabled: keyboardNavEnabled ?? this.keyboardNavEnabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': 'default',
    'voice_enabled': voiceEnabled ? 1 : 0,
    'tts_enabled': ttsEnabled ? 1 : 0,
    'screen_reader_enabled': screenReaderEnabled ? 1 : 0,
    'high_contrast_enabled': highContrastEnabled ? 1 : 0,
    'keyboard_nav_enabled': keyboardNavEnabled ? 1 : 0,
    'speech_rate': speechRate,
    'pitch': pitch,
    'volume': volume,
    'language': language,
    'theme': theme,
    'font_size_multiplier': fontSizeMultiplier,
    'reduce_animations': reduceAnimations ? 1 : 0,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      voiceEnabled: map['voice_enabled'] == 1,
      ttsEnabled: map['tts_enabled'] == 1,
      screenReaderEnabled: map['screen_reader_enabled'] == 1,
      highContrastEnabled: map['high_contrast_enabled'] == 1,
      keyboardNavEnabled: map['keyboard_nav_enabled'] == 1,
      speechRate: map['speech_rate'] ?? 0.5,
      pitch: map['pitch'] ?? 1.0,
      volume: map['volume'] ?? 1.0,
      language: map['language'] ?? 'en-US',
      theme: map['theme'] ?? 'default',
      fontSizeMultiplier: map['font_size_multiplier'] ?? 1.0,
      reduceAnimations: map['reduce_animations'] == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}

class VoiceCommand {
  final String phrase;
  final VoidCallback action;
  final List<String> alternatives;
  final String? description;

  VoiceCommand({
    required this.phrase,
    required this.action,
    required this.alternatives,
    this.description,
  });
}

enum SpeechPriority {
  normal,
  high,
  queued,
}

enum NavigationDirection {
  next,
  previous,
  up,
  down,
}

class HighContrastTheme {
  final Brightness brightness;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color iconColor;
  final Color borderColor;
  final Color buttonColor;
  final Color buttonTextColor;

  HighContrastTheme({
    required this.brightness,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.iconColor,
    required this.borderColor,
    required this.buttonColor,
    required this.buttonTextColor,
  });
}

class AccessibilityAudit {
  final double score;
  final List<AccessibilityIssue> issues;
  final List<String> recommendations;
  final DateTime timestamp;

  AccessibilityAudit({
    required this.score,
    required this.issues,
    required this.recommendations,
    required this.timestamp,
  });
}

class AccessibilityIssue {
  final IssueType type;
  final IssueSeverity severity;
  final String description;
  final String recommendation;

  AccessibilityIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

enum IssueType {
  contrast,
  keyboard,
  voice,
  screenReader,
  navigation,
}

enum IssueSeverity {
  low,
  medium,
  high,
  critical,
}

class AccessibilityException implements Exception {
  final String message;
  AccessibilityException(this.message);
  
  @override
  String toString() => 'AccessibilityException: $message';
}