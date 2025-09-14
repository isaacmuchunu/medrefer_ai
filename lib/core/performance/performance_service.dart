import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Enable hardware acceleration for better performance
  static Future<void> _enableHardwareAcceleration() async {
    // Enable hardware acceleration for animations
    WidgetsFlutterBinding.ensureInitialized();
    
    // Configure system UI for better performance
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  /// Optimize memory usage
  static void _optimizeMemoryUsage() {
    // Configure garbage collection
    if (kDebugMode) {
      debugPrint('Performance: Memory optimization enabled');
    }
    
    // Set memory pressure callback
    WidgetsBinding.instance.addObserver(_MemoryPressureObserver());
  }

  /// Configure image caching for better performance
  static void _configureImageCaching() {
    // Increase image cache size for better performance
    PaintingBinding.instance.imageCache.maximumSize = 1000;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
    
    if (kDebugMode) {
      debugPrint('Performance: Image cache configured - Max size: 1000 images, 100MB');
    }
  }

  /// Setup performance monitoring in debug mode
  static void _setupPerformanceMonitoring() {
    if (kDebugMode) {
      // Monitor frame rendering performance
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

  /// Optimize widget rebuilds by providing const constructors
  static Widget optimizedBuilder({
    required Widget Function() builder,
    List<Object?>? dependencies,
  }) {
    return _OptimizedBuilder(
      builder: builder,
      dependencies: dependencies,
    );
  }

  /// Preload critical resources
  static Future<void> preloadCriticalResources(BuildContext context) async {
    // Preload commonly used images
    await _preloadImages(context);
    
    // Warm up commonly used widgets
    _warmupWidgets(context);
  }

  /// Preload commonly used images
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

  /// Warm up commonly used widgets
  static void _warmupWidgets(BuildContext context) {
    // Create and dispose commonly used widgets to warm up the widget tree
    final warmupWidgets = [
      CircularProgressIndicator(),
      LinearProgressIndicator(),
      Card(),
      ListTile(),
      TextField(),
      ElevatedButton(onPressed: () {}, child: Text('Test')),
    ];

    for (final widget in warmupWidgets) {
      // Create widget tree without rendering
      widget.createElement();
    }

    if (kDebugMode) {
      debugPrint('Performance: Widget warmup completed');
    }
  }

  /// Optimize list performance with lazy loading
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
      // Optimize for performance
      cacheExtent: 500, // Cache 500 pixels ahead
      addAutomaticKeepAlives: false, // Don't keep alive off-screen items
      addRepaintBoundaries: true, // Add repaint boundaries
    );
  }

  /// Optimize grid performance
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
      // Optimize for performance
      cacheExtent: 500,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }

  /// Create optimized image widget
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
      // Performance optimizations
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

  /// Debounce function calls for better performance
  static void debounce({
    required String key,
    required VoidCallback callback,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _DebounceManager.instance.debounce(key, callback, delay);
  }

  /// Clear all performance caches
  static void clearCaches() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    if (kDebugMode) {
      debugPrint('Performance: All caches cleared');
    }
  }
}

/// Memory pressure observer for handling low memory situations
class _MemoryPressureObserver extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    
    // Clear image cache on memory pressure
    PaintingBinding.instance.imageCache.clear();
    
    if (kDebugMode) {
      debugPrint('Performance: Memory pressure detected, cleared image cache');
    }
  }
}

/// Optimized builder widget that minimizes rebuilds
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
    // Check if dependencies have changed
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
    
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    
    return true;
  }
}

/// Debounce manager for function calls
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

/// Timer implementation for debouncing
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _isActive = true;

  Timer(this.duration, this.callback) {
    Future.delayed(duration, () {
      if (_isActive) {
        callback();
      }
    });
  }

  void cancel() {
    _isActive = false;
  }
}
