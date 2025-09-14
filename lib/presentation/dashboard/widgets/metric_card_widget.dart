import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/app_export.dart';

class MetricCardWidget extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? accentColor;
  final bool isUrgent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? trend; // e.g., 0.15 for +15%
  final List<double>? sparklineData;
  final bool isLoading;
  final double? progress; // 0.0 to 1.0
  final String? alert;

  const MetricCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.accentColor,
    this.isUrgent = false,
    this.onTap,
    this.onLongPress,
    this.trend,
    this.sparklineData,
    this.isLoading = false,
    this.progress,
    this.alert,
  });

  @override
  State<MetricCardWidget> createState() => _MetricCardWidgetState();
}

class _MetricCardWidgetState extends State<MetricCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final endValue = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    _numberAnimation = Tween<double>(begin: 0, end: endValue).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (!widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MetricCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !widget.isLoading) {
      final endValue = double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      _numberAnimation = Tween<double>(begin: 0, end: endValue).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    final trendColor = (widget.trend ?? 0) >= 0 ? Colors.green : Colors.red;
    final trendIcon = (widget.trend ?? 0) >= 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Tooltip(
        message: '${widget.title}: ${widget.value}. ${widget.subtitle}',
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: widget.isUrgent
                ? Border.all(
                    color: AppTheme.lightTheme.colorScheme.error,
                    width: 2,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.alert != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.alert!,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (widget.isUrgent)
                    Container(
                      width: 3.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedBuilder(
                    animation: _numberAnimation,
                    builder: (context, child) {
                      return Text(
                        widget.value.contains('\$')
                            ? '\$${_numberAnimation.value.toStringAsFixed(0)}'
                            : _numberAnimation.value.toStringAsFixed(0),
                        style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                          color: widget.accentColor ?? AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  if (widget.trend != null) ...[
                    SizedBox(width: 2.w),
                    Icon(trendIcon, color: trendColor, size: 16),
                    Text(
                      '${(widget.trend! * 100).toStringAsFixed(1)}%',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                widget.subtitle,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.sparklineData != null && widget.sparklineData!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                _buildSparkline(),
              ],
              if (widget.progress != null) ...[
                SizedBox(height: 2.h),
                LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: AppTheme.lightTheme.colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      widget.accentColor ?? AppTheme.lightTheme.colorScheme.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 16, color: Colors.white),
            SizedBox(height: 1.h),
            Container(width: 150, height: 32, color: Colors.white),
            SizedBox(height: 0.5.h),
            Container(width: 200, height: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline() {
    return SizedBox(
      height: 5.h,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                widget.sparklineData!.length,
                (index) => FlSpot(index.toDouble(), widget.sparklineData![index]),
              ),
              isCurved: true,
              color: widget.accentColor ?? AppTheme.lightTheme.colorScheme.primary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: (widget.accentColor ?? AppTheme.lightTheme.colorScheme.primary)
                    .withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
