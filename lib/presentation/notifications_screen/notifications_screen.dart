import '../../core/app_export.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> _unreadNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; });
    final service = Provider.of<NotificationService>(context, listen: false);
    await service.initialize();
    final items = service.notifications
        .map((n) => NotificationItem(
              id: n.id,
              title: n.title,
              message: n.message,
              type: _mapType(n.type),
              timestamp: n.timestamp,
              isRead: n.isRead,
              priority: _mapPriority(n.type),
            ))
        .toList();
    setState(() {
      _allNotifications = items;
      _unreadNotifications = items.where((n) => !n.isRead).toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.mark_email_read_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settingsScreen);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(
              text: 'All (${_allNotifications.length})',
            ),
            Tab(
              text: 'Unread (${_unreadNotifications.length})',
            ),
            Tab(
              text: 'Settings',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_allNotifications),
                _buildNotificationsList(_unreadNotifications),
                _buildNotificationSettings(),
              ],
            ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? theme.colorScheme.surface
            : theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                if (notification.priority == NotificationPriority.critical)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'URGENT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Preferences',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          _buildNotificationToggle(
            'Referral Updates',
            'Get notified when referral status changes',
            Icons.assignment_outlined,
            true,
          ),
          _buildNotificationToggle(
            'New Messages',
            'Receive alerts for new secure messages',
            Icons.message_outlined,
            true,
          ),
          _buildNotificationToggle(
            'Emergency Alerts',
            'Critical notifications for urgent cases',
            Icons.emergency_outlined,
            true,
          ),
          _buildNotificationToggle(
            'Appointment Reminders',
            'Reminders for upcoming appointments',
            Icons.event_outlined,
            true,
          ),
          _buildNotificationToggle(
            'System Updates',
            'App updates and maintenance notifications',
            Icons.system_update_outlined,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    bool initialValue,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        value: initialValue,
        onChanged: (value) {
          // Handle notification preference change
        },
        activeThumbColor: theme.colorScheme.primary,
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.referralUpdate:
        return Icons.assignment_turned_in;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.appointment:
        return Icons.event;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.referralUpdate:
        return theme.colorScheme.primary;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.emergency:
        return theme.colorScheme.error;
      case NotificationType.appointment:
        return Colors.orange;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _markAsRead(NotificationItem notification) {
    final service = Provider.of<NotificationService>(context, listen: false);
    service.markAsRead(notification.id);
    setState(() {
      notification.isRead = true;
      _unreadNotifications.removeWhere((n) => n.id == notification.id);
    });
  }

  void _markAllAsRead() {
    final service = Provider.of<NotificationService>(context, listen: false);
    service.markAllAsRead();
    setState(() {
      for (var notification in _allNotifications) {
        notification.isRead = true;
      }
      _unreadNotifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('All notifications marked as read'),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ));
  }

  NotificationType _mapType(NotificationType type) {
    switch (type) {
      case NotificationType.referral:
        return NotificationType.referralUpdate;
      case NotificationType.message:
        return NotificationType.message;
      case NotificationType.appointment:
        return NotificationType.appointment;
      case NotificationType.urgent:
        return NotificationType.emergency;
      case NotificationType.info:
      case NotificationType.success:
      case NotificationType.warning:
      case NotificationType.error:
        return NotificationType.system;
    }
  }

  NotificationPriority _mapPriority(NotificationType type) {
    switch (type) {
      case NotificationType.urgent:
        return NotificationPriority.critical;
      case NotificationType.error:
        return NotificationPriority.high;
      case NotificationType.warning:
        return NotificationPriority.medium;
      default:
        return NotificationPriority.low;
    }
  }
}

// Notification data models
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;
  final NotificationPriority priority;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
  });
}

enum NotificationType {
  referralUpdate,
  message,
  emergency,
  appointment,
  system,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}
