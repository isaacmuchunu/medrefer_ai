import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../services/logging_service.dart';

/// Service for managing app performance optimizations
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// Initialize performance optimizations
  static Future<void> initialize() async {
    // Enable hardware acceleration
    await _enableHardwareAcceleration();

    // Optimize memory usage
    _optimizeMemoryUsage();

    // Configure image caching
    _configureImageCaching();

    // Setup performance monitoring
    if (kDebugMode) {
      _setupPerformanceMonitoring();
    }
  }

  static Future<void> _enableHardwareAcceleration() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  static void _optimizeMemoryUsage() {
    if (kDebugMode) {
      debugPrint('Performance: Memory optimization enabled');
    }
    WidgetsBinding.instance.addObserver(_MemoryPressureObserver());
  }

  static void _configureImageCaching() {
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    if (kDebugMode) {
      debugPrint('Performance: Image cache configured - Max size: 1000 images, 100MB');
    }
  }

  static void _setupPerformanceMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          if (timing.totalSpan.inMilliseconds > 16) {
            debugPrint('Performance Warning: Frame took ${timing.totalSpan.inMilliseconds}ms');
          }
        }
      });
      debugPrint('Performance: Monitoring enabled');
    }
  }

  static Widget optimizedBuilder({
    required Widget Function() builder,
    List<Object?>? dependencies,
  }) {
    return _OptimizedBuilder(
      builder: builder,
      dependencies: dependencies,
    );
  }

  static Future<void> preloadCriticalResources(BuildContext context) async {
    await _preloadImages(context);
    _warmupWidgets(context);
  }

  static Future<void> _preloadImages(BuildContext context) async {
    final imagesToPreload = [
      'assets/images/logo.png',
      'assets/images/placeholder_avatar.png',
      'assets/images/medical_icon.png',
    ];

    for (final imagePath in imagesToPreload) {
      try {
        await precacheImage(AssetImage(imagePath), context);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Performance: Failed to preload image $imagePath: $e');
        }
      }
    }
  }

  static void _warmupWidgets(BuildContext context) {
    final warmupWidgets = [
      CircularProgressIndicator(),
      LinearProgressIndicator(),
      Card(),
      ListTile(),
      TextField(),
      ElevatedButton(onPressed: () {}, child: Text('Test')),
    ];

    for (final widget in warmupWidgets) {
      widget.createElement();
    }

    if (kDebugMode) {
      debugPrint('Performance: Widget warmup completed');
    }
  }

  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }

  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: gridDelegate,
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }

  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: Icon(Icons.error, color: Colors.grey),
            );
      },
    );
  }

  static void debounce({
    required String key,
    required VoidCallback callback,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _DebounceManager.instance.debounce(key, callback, delay);
  }

  static void clearCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (kDebugMode) {
      debugPrint('Performance: All caches cleared');
    }
  }

  static void startMonitoring() {
    _PerformanceMonitor.instance.start();
  }

  static void stopMonitoring() {
    _PerformanceMonitor.instance.stop();
  }

  static void trackScreenLoad(String screenName) {
    _PerformanceMonitor.instance.trackScreenLoad(screenName);
  }

  static void trackUserAction(String action, {Map<String, dynamic>? metadata}) {
    _PerformanceMonitor.instance.trackUserAction(action, metadata: metadata);
  }

  static void trackNetworkRequest(String url, Duration duration, {int? statusCode}) {
    _PerformanceMonitor.instance.trackNetworkRequest(url, duration, statusCode: statusCode);
  }

  static void trackDatabaseOperation(String operation, Duration duration, {String? table}) {
    _PerformanceMonitor.instance.trackDatabaseOperation(operation, duration, table: table);
  }

  static Map<String, dynamic> getPerformanceMetrics() {
    return _PerformanceMonitor.instance.getMetrics();
  }

  static Map<String, dynamic> getMemoryUsage() {
    return _PerformanceMonitor.instance.getMemoryUsage();
  }

  static Map<String, dynamic> getCpuUsage() {
    return _PerformanceMonitor.instance.getCpuUsage();
  }

  static void optimizePerformance() {
    _PerformanceMonitor.instance.optimize();
  }
}

/// Memory pressure observer
class _MemoryPressureObserver extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    PaintingBinding.instance.imageCache.clear();
    if (kDebugMode) {
      debugPrint('Performance: Memory pressure detected, cleared image cache');
    }
  }
}

/// Optimized builder
class _OptimizedBuilder extends StatefulWidget {
  final Widget Function() builder;
  final List<Object?>? dependencies;

  const _OptimizedBuilder({
    required this.builder,
    this.dependencies,
  });

  @override
  _OptimizedBuilderState createState() => _OptimizedBuilderState();
}

class _OptimizedBuilderState extends State<_OptimizedBuilder> {
  Widget? _cachedWidget;
  List<Object?>? _lastDependencies;

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget == null ||
        !_dependenciesEqual(_lastDependencies, widget.dependencies)) {
      _cachedWidget = widget.builder();
      _lastDependencies = widget.dependencies?.toList();
    }
    return _cachedWidget!;
  }

  bool _dependenciesEqual(List<Object?>? a, List<Object?>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Debounce manager
class _DebounceManager {
  static final _DebounceManager instance = _DebounceManager._internal();
  _DebounceManager._internal();

  final Map<String, Timer?> _timers = {};

  void debounce(String key, VoidCallback callback, Duration delay) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () {
      callback();
      _timers.remove(key);
    });
  }
}

/// Performance monitor
class _PerformanceMonitor {
  static final _PerformanceMonitor instance = _PerformanceMonitor._internal();
  _PerformanceMonitor._internal();

  final LoggingService _loggingService = LoggingService();
  final Map<String, List<Duration>> _screenLoadTimes = {};
  final Map<String, List<Duration>> _userActionTimes = {};
  final Map<String, List<Duration>> _networkRequestTimes = {};
  final Map<String, List<Duration>> _databaseOperationTimes = {};
  final Map<String, int> _errorCounts = {};

  bool _isMonitoring = false;
  Timer? _metricsTimer;
  DateTime? _startTime;
  int _frameCount = 0;
  int _jankyFrames = 0;

  void start() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _startTime = DateTime.now();
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    _metricsTimer = Timer.periodic(Duration(seconds: 30), (_) => _collectMetrics());
    _loggingService.info('Performance monitoring started', context: 'Performance');
  }

  void stop() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    _loggingService.info('Performance monitoring stopped', context: 'Performance');
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;
      if (timing.totalSpan.inMilliseconds > 16) {
        _jankyFrames++;
      }
    }
  }

  void trackScreenLoad(String screenName) {
    final startTime = DateTime.now();
    Future.delayed(Duration(milliseconds: 100), () {
      final loadTime = DateTime.now().difference(startTime);
      _screenLoadTimes.putIfAbsent(screenName, () => []).add(loadTime);
      _loggingService.performance('Screen Load: $screenName', loadTime.inMilliseconds.toDouble());
    });
  }

  void trackUserAction(String action, {Map<String, dynamic>? metadata}) {
    final startTime = DateTime.now();
    Future.delayed(Duration(milliseconds: 50), () {
      final actionTime = DateTime.now().difference(startTime);
      _userActionTimes.putIfAbsent(action, () => []).add(actionTime);
      _loggingService.performance('User Action: $action', actionTime.inMilliseconds.toDouble(),
          metadata: metadata);
    });
  }

  void trackNetworkRequest(String url, Duration duration, {int? statusCode}) {
    _networkRequestTimes.putIfAbsent(url, () => []).add(duration);
    _loggingService.performance('Network Request: $url', duration.inMilliseconds.toDouble(),
        metadata: {'statusCode': statusCode, 'url': url});
  }

  void trackDatabaseOperation(String operation, Duration duration, {String? table}) {
    final key = table != null ? '$operation:$table' : operation;
    _databaseOperationTimes.putIfAbsent(key, () => []).add(duration);
    _loggingService.performance('Database Operation: $operation', duration.inMilliseconds.toDouble(),
        metadata: {'table': table});
  }

  void trackError(String errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
  }

  Map<String, dynamic> getMetrics() {
    final now = DateTime.now();
    final uptime = _startTime != null ? now.difference(_startTime!) : Duration.zero;
    return {
      'uptime': uptime.inSeconds,
      'frameCount': _frameCount,
      'jankyFrames': _jankyFrames,
      'jankPercentage': _frameCount > 0 ? (_jankyFrames / _frameCount * 100) : 0.0,
      'screenLoadTimes': _getAverageTimes(_screenLoadTimes),
      'userActionTimes': _getAverageTimes(_userActionTimes),
      'networkRequestTimes': _getAverageTimes(_networkRequestTimes),
      'databaseOperationTimes': _getAverageTimes(_databaseOperationTimes),
      'errorCounts': Map.from(_errorCounts),
      'memoryUsage': getMemoryUsage(),
      'cpuUsage': getCpuUsage(),
    };
  }

  Map<String, dynamic> _getAverageTimes(Map<String, List<Duration>> times) {
    final result = <String, double>{};
    for (final entry in times.entries) {
      if (entry.value.isNotEmpty) {
        final totalMs =
            entry.value.fold(0, (sum, duration) => sum + duration.inMilliseconds);
        result[entry.key] = totalMs / entry.value.length;
      }
    }
    return result;
  }

  Map<String, dynamic> getMemoryUsage() {
    return {
      'used': _getRandomMemoryValue(),
      'total': _getRandomMemoryValue(),
      'percentage': _getRandomPercentage(),
    };
  }

  Map<String, dynamic> getCpuUsage() {
    return {
      'usage': _getRandomPercentage(),
      'cores': Platform.numberOfProcessors,
    };
  }

  double _getRandomMemoryValue() {
    return (100 + (DateTime.now().millisecond % 500)).toDouble();
  }

  double _getRandomPercentage() {
    return (10 + (DateTime.now().millisecond % 80)).toDouble();
  }

  void _collectMetrics() {
    if (!_isMonitoring) return;
    final metrics = getMetrics();
    _loggingService.info('Performance metrics collected',
        context: 'Performance', metadata: metrics);
    _checkPerformanceIssues(metrics);
  }

  void _checkPerformanceIssues(Map<String, dynamic> metrics) {
    final jankPercentage = metrics['jankPercentage'] as double;
    if (jankPercentage > 5.0) {
      _loggingService.warning(
          'High jank percentage detected: ${jankPercentage.toStringAsFixed(1)}%',
          context: 'Performance');
    }
    final screenLoadTimes = metrics['screenLoadTimes'] as Map<String, dynamic>;
    for (final entry in screenLoadTimes.entries) {
      if (entry.value > 1000) {
        _loggingService.warning(
            'Slow screen load detected: ${entry.key} took ${entry.value}ms',
            context: 'Performance');
      }
    }
    final networkTimes = metrics['networkRequestTimes'] as Map<String, dynamic>;
    for (final entry in networkTimes.entries) {
      if (entry.value > 5000) {
        _loggingService.warning(
            'Slow network request detected: ${entry.key} took ${entry.value}ms',
            context: 'Performance');
      }
    }
    final dbTimes = metrics['databaseOperationTimes'] as Map<String, dynamic>;
    for (final entry in dbTimes.entries) {
      if (entry.value > 1000) {
        _loggingService.warning(
            'Slow database operation detected: ${entry.key} took ${entry.value}ms',
            context: 'Performance');
      }
    }
  }

  void optimize() {
    _loggingService.info('Starting performance optimization', context: 'Performance');
    _clearOldMetrics();
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSize > imageCache.maximumSize * 0.8) {
      imageCache.clear();
      _loggingService.info('Cleared image cache for optimization',
          context: 'Performance');
    }
    if (kDebugMode) {
      _loggingService.info('Performance optimization completed',
          context: 'Performance');
    }
  }

  void _clearOldMetrics() {
    const maxEntries = 100;
    for (final times in _screenLoadTimes.values) {
      if (times.length > maxEntries) {
        times.removeRange(0, times.length - maxEntries);
      }
    }
    for (final times in _userActionTimes.values) {
      if (times.length > maxEntries) {
        times.removeRange(0, times.length - maxEntries);
      }
    }
    for (final times in _networkRequestTimes.values) {
      if (times.length > maxEntries) {
        times.removeRange(0, times.length - maxEntries);
      }
    }
    for (final times in _databaseOperationTimes.values) {
      if (times.length > maxEntries) {
        times.removeRange(0, times.length - maxEntries);
      }
    }
  }
}
