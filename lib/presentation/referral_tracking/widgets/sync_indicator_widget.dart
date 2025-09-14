
import '../../../core/app_export.dart';

class SyncIndicatorWidget extends StatefulWidget {
  final DateTime? lastSyncTime;
  final bool isOnline;
  final int pendingChanges;
  final VoidCallback? onRefresh;

  const SyncIndicatorWidget({
    super.key,
    this.lastSyncTime,
    required this.isOnline,
    this.pendingChanges = 0,
    this.onRefresh,
  });

  @override
  State<SyncIndicatorWidget> createState() => _SyncIndicatorWidgetState();
}

class _SyncIndicatorWidgetState extends State<SyncIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startSyncAnimation() {
    _animationController.repeat();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: widget.isOnline
            ? AppTheme.successLight.withValues(alpha: 0.1)
            : AppTheme.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isOnline
              ? AppTheme.successLight.withValues(alpha: 0.3)
              : AppTheme.warningLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Connection status indicator
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isOnline
                  ? AppTheme.successLight
                  : AppTheme.warningLight,
            ),
          ),
          SizedBox(width: 2.w),

          // Status text and last sync time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: widget.isOnline
                            ? AppTheme.successLight
                            : AppTheme.warningLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.pendingChanges > 0) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.pendingChanges} pending',
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.lastSyncTime != null) ...[
                  SizedBox(height: 0.2.h),
                  Text(
                    'Last sync: ${_formatSyncTime(widget.lastSyncTime!)}',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Refresh button
          if (widget.onRefresh != null)
            GestureDetector(
              onTap: () {
                _startSyncAnimation();
                widget.onRefresh?.call();
              },
              child: Container(
                padding: EdgeInsets.all(1.w),
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: CustomIconWidget(
                        iconName: 'refresh',
                        color: widget.isOnline
                            ? AppTheme.successLight
                            : AppTheme.warningLight,
                        size: 16,
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
