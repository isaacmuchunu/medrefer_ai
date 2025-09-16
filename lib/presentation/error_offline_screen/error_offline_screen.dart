import '../../core/app_export.dart';

class ErrorOfflineScreen extends StatefulWidget {
  final String? errorMessage;
  final String? errorType;
  final bool isOffline;
  final VoidCallback? onRetry;

  const ErrorOfflineScreen({
    super.key,
    this.errorMessage,
    this.errorType,
    this.isOffline = false,
    this.onRetry,
  });

  @override
  _ErrorOfflineScreenState createState() => _ErrorOfflineScreenState();
}

class _ErrorOfflineScreenState extends State<ErrorOfflineScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isRetrying = false;
  int _queuedActions = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQueuedActions();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  void _loadQueuedActions() {
    // Simulate loading queued actions count
    setState(() {
      _queuedActions = 3; // Mock data
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error/Offline Icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: widget.isOffline
                              ? Colors.orange.withOpacity(0.1)
                              : theme.colorScheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isOffline
                                ? Colors.orange
                                : theme.colorScheme.error,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          widget.isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.error_outline_rounded,
                          size: 60,
                          color: widget.isOffline
                              ? Colors.orange
                              : theme.colorScheme.error,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  widget.isOffline ? 'You\'re Offline' : 'Something Went Wrong',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.isOffline
                        ? Colors.orange
                        : theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  widget.isOffline
                      ? 'Check your internet connection and try again. Your data will sync when you\'re back online.'
                      : widget.errorMessage ?? 'An unexpected error occurred. Please try again.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Queued Actions (for offline mode)
                if (widget.isOffline && _queuedActions > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.queue_rounded,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Queued Actions',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                '$_queuedActions actions waiting to sync',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showQueuedActions,
                          child: Text('View'),
                        ),
                      ],
                    ),
                  ),

                if (widget.isOffline && _queuedActions > 0)
                  const SizedBox(height: 24),

                // Action Buttons
                Column(
                  children: [
                    // Retry Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRetrying ? null : _handleRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isOffline
                              ? Colors.orange
                              : theme.colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isRetrying
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.refresh_rounded),
                        label: Text(
                          _isRetrying
                              ? 'Retrying...'
                              : widget.isOffline
                                  ? 'Check Connection'
                                  : 'Try Again',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goToSettings,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            icon: Icon(Icons.settings_rounded),
                            label: Text('Settings'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _goHome,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: theme.colorScheme.outline.withOpacity(0.5),
                              ),
                            ),
                            icon: Icon(Icons.home_rounded),
                            label: Text('Home'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Help Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Need Help?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isOffline
                            ? 'You can still view cached data and create referrals offline. They\'ll sync when you\'re back online.'
                            : 'If this problem persists, please contact support or check our help center.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _contactSupport,
                              icon: Icon(Icons.support_agent_rounded, size: 18),
                              label: Text('Contact Support'),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _viewHelpCenter,
                              icon: Icon(Icons.help_center_rounded, size: 18),
                              label: Text('Help Center'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      // Simulate retry delay
      await Future.delayed(Duration(seconds: 2));

      if (widget.onRetry != null) {
        widget.onRetry!();
      } else {
        // Default retry behavior
        if (widget.isOffline) {
          // Check connectivity
          await _checkConnectivity();
        } else {
          // Retry the failed operation
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retry failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    // Simulate connectivity check
    await Future.delayed(Duration(seconds: 1));

    // Mock connectivity result
    final isConnected = DateTime.now().millisecond % 2 == 0;

    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection restored!'),
          backgroundColor: Colors.green,
        ),
      );

      // Sync queued actions
      if (_queuedActions > 0) {
        await _syncQueuedActions();
      }

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Still offline. Please check your connection.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _syncQueuedActions() async {
    // Simulate syncing queued actions
    for (var i = _queuedActions; i > 0; i--) {
      await Future.delayed(Duration(milliseconds: 500));
      setState(() {
        _queuedActions = i - 1;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All actions synced successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showQueuedActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queued Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Mock queued actions
            _buildQueuedActionItem(
              'Create Referral',
              'Patient: John Doe → Dr. Smith',
              Icons.assignment_add,
            ),
            _buildQueuedActionItem(
              'Update Status',
              'Referral #REF001 → Approved',
              Icons.update,
            ),
            _buildQueuedActionItem(
              'Send Message',
              'Message to Dr. Johnson',
              Icons.message,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueuedActionItem(String title, String subtitle, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.schedule,
            color: Colors.orange,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _goToSettings() {
    Navigator.pushNamed(context, AppRoutes.settingsScreen);
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  void _contactSupport() {
    // Implement support contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening support chat...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _viewHelpCenter() {
    // Implement help center navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening help center...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}