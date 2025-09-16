import '../../../core/app_export.dart';

class QuickActionCardWidget extends StatefulWidget {
  final String title;
  final String iconName;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isEmergency;
  final bool isEnabled;

  const QuickActionCardWidget({
    super.key,
    required this.title,
    required this.iconName,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
    this.isEmergency = false,
    this.isEnabled = true,
  });

  @override
  State<QuickActionCardWidget> createState() => _QuickActionCardWidgetState();
}

class _QuickActionCardWidgetState extends State<QuickActionCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isEmergency) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget cardContent = Container(
      width: 20.w,
      height: 20.w,
      margin: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: widget.isEnabled ? widget.backgroundColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isEnabled
            ? [
                BoxShadow(
                  color: widget.backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isEnabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: widget.iconName,
                color: widget.isEnabled ? widget.iconColor : Colors.grey.shade600,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                widget.title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.isEnabled ? widget.iconColor : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmergency && widget.isEnabled) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: cardContent,
          );
        },
      );
    }

    return cardContent;
  }
}
