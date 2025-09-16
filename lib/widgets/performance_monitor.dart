import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring widget for debug builds
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  _PerformanceMonitorState createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> with TickerProviderStateMixin {
  double _fps = 0.0;
  int _frameCount = 0;
  DateTime _lastUpdate = DateTime.now();
  final List<double> _frameTimes = [];
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || !widget.enabled) return;

    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMicroseconds / 1000.0; // Convert to milliseconds
      _frameTimes.add(frameTime);
      
      // Keep only last 60 frame times
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
    }

    _frameCount += timings.length;
    final now = DateTime.now();
    final elapsed = now.difference(_lastUpdate).inMilliseconds;

    if (elapsed >= 1000) { // Update every second
      setState(() {
        _fps = (_frameCount * 1000.0) / elapsed;
        _frameCount = 0;
        _lastUpdate = now;
      });
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_showOverlay) _buildPerformanceOverlay(),
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildToggleButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showOverlay = !_showOverlay;
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _showOverlay ? Icons.close : Icons.speed,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceOverlay() {
    final avgFrameTime = _frameTimes.isNotEmpty 
        ? _frameTimes.reduce((a, b) => a + b) / _frameTimes.length 
        : 0.0;
    
    final maxFrameTime = _frameTimes.isNotEmpty 
        ? _frameTimes.reduce((a, b) => a > b ? a : b) 
        : 0.0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      right: 10,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Performance Monitor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 8),
            _buildMetricRow('FPS', _fps.toStringAsFixed(1), _getFpsColor()),
            _buildMetricRow('Avg Frame', '${avgFrameTime.toStringAsFixed(1)}ms', _getFrameTimeColor(avgFrameTime)),
            _buildMetricRow('Max Frame', '${maxFrameTime.toStringAsFixed(1)}ms', _getFrameTimeColor(maxFrameTime)),
            _buildMetricRow('Memory', '${_getMemoryUsage()}MB', Colors.white),
            SizedBox(height: 8),
            _buildFrameTimeChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameTimeChart() {
    if (_frameTimes.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      width: 150,
      height: 40,
      child: CustomPaint(
        painter: FrameTimeChartPainter(_frameTimes),
      ),
    );
  }

  Color _getFpsColor() {
    if (_fps >= 55) return Colors.green;
    if (_fps >= 30) return Colors.yellow;
    return Colors.red;
  }

  Color _getFrameTimeColor(double frameTime) {
    if (frameTime <= 16.67) return Colors.green; // 60 FPS
    if (frameTime <= 33.33) return Colors.yellow; // 30 FPS
    return Colors.red;
  }

  String _getMemoryUsage() {
    // This is a simplified memory usage calculation
    // In a real implementation, you might use more sophisticated methods
    return (MediaQuery.of(context).size.width * MediaQuery.of(context).size.height * 4 / 1024 / 1024).toStringAsFixed(1);
  }
}

/// Custom painter for frame time chart
class FrameTimeChartPainter extends CustomPainter {
  final List<double> frameTimes;

  FrameTimeChartPainter(this.frameTimes);

  @override
  void paint(Canvas canvas, Size size) {
    if (frameTimes.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final maxFrameTime = frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = frameTimes.reduce((a, b) => a < b ? a : b);
    final range = maxFrameTime - minFrameTime;

    if (range == 0) return;

    final path = Path();
    
    for (int i = 0; i < frameTimes.length; i++) {
      final x = (i / (frameTimes.length - 1)) * size.width;
      final normalizedValue = (frameTimes[i] - minFrameTime) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Color based on performance
    if (maxFrameTime <= 16.67) {
      paint.color = Colors.green;
    } else if (maxFrameTime <= 33.33) {
      paint.color = Colors.yellow;
    } else {
      paint.color = Colors.red;
    }

    canvas.drawPath(path, paint);

    // Draw 60 FPS line (16.67ms)
    final targetFrameTime = 16.67;
    if (targetFrameTime >= minFrameTime && targetFrameTime <= maxFrameTime) {
      final targetY = size.height - ((targetFrameTime - minFrameTime) / range * size.height);
      final targetPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..strokeWidth = 1;
      
      canvas.drawLine(
        Offset(0, targetY),
        Offset(size.width, targetY),
        targetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Memory usage monitor widget
class MemoryMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const MemoryMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  _MemoryMonitorState createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  double _memoryUsage = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    // Update memory usage every 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        _updateMemoryUsage();
        _startMonitoring();
      }
    });
  }

  void _updateMemoryUsage() {
    // Simplified memory calculation
    // In production, you might use platform-specific methods
    setState(() {
      _memoryUsage = _calculateMemoryUsage();
    });
  }

  double _calculateMemoryUsage() {
    // This is a placeholder calculation
    // Real implementation would use platform channels or other methods
    return 50.0 + (DateTime.now().millisecondsSinceEpoch % 100);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 50,
          right: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Memory: ${_memoryUsage.toStringAsFixed(1)}MB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
