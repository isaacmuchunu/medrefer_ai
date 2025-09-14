import 'package:flutter/material.dart';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/services/advanced_notification_service.dart';
import 'package:medrefer_ai/database/models/notification_models.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({Key? key}) : super(key: key);

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen>
    with TickerProviderStateMixin {
  late AdvancedNotificationService _notificationService;
  late TabController _tabController;
  
  List<NotificationModel> _notifications = [];
  List<NotificationTemplate> _templates = [];
  NotificationPreferences? _userPreferences;
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _notificationService = AdvancedNotificationService();
    _tabController = TabController(length: 4, vsync: this);
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _notificationService.initialize();
      await _loadData();
      _notificationService.addListener(_onNotificationUpdate);
    } catch (e) {
      debugPrint('Error initializing notification screen: $e');
    }
  }

  void _onNotificationUpdate() {
    _loadNotifications();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadNotifications(),
        _loadTemplates(),
        _loadUserPreferences(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotifications() async {
    // In a real app, you would get the current user ID
    final userId = 'current_user_id';
    final notifications = _notificationService.getUserNotifications(
      userId,
      includeArchived: false,
    );
    setState(() => _notifications = notifications);
  }

  Future<void> _loadTemplates() async {
    // In a real app, you would load templates from database
    setState(() => _templates = _getSampleTemplates());
  }

  Future<void> _loadUserPreferences() async {
    // In a real app, you would get the current user ID
    final userId = 'current_user_id';
    final preferences = _notificationService.getUserPreferences(userId);
    setState(() => _userPreferences = preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstant.gray50,
      appBar: AppBar(
        title: Text(
          'Notification Management',
          style: AppStyle.txtInterBold24,
        ),
        backgroundColor: ColorConstant.whiteA700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'mark_all_read', child: Text('Mark All Read')),
              PopupMenuItem(value: 'clear_archived', child: Text('Clear Archived')),
              PopupMenuItem(value: 'statistics', child: Text('View Statistics')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Notifications',
              icon: Icon(Icons.notifications),
              child: _buildUnreadBadge(),
            ),
            Tab(text: 'Templates', icon: Icon(Icons.template)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsTab(),
                _buildTemplatesTab(),
                _buildSettingsTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNotificationDialog,
        child: Icon(Icons.add),
        backgroundColor: ColorConstant.blue600,
      ),
    );
  }

  Widget _buildUnreadBadge() {
    final unreadCount = _notificationService.getUnreadCount('current_user_id');
    return Stack(
      children: [
        Icon(Icons.notifications),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return Column(
      children: [
        _buildNotificationFilters(),
        Expanded(
          child: _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: ColorConstant.whiteA700,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Categories')),
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'referral', child: Text('Referral')),
                DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                DropdownMenuItem(value: 'payment', child: Text('Payment')),
                DropdownMenuItem(value: 'security', child: Text('Security')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value ?? 'all');
                _filterNotifications();
              },
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'error', child: Text('Error')),
                DropdownMenuItem(value: 'success', child: Text('Success')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value ?? 'all');
                _filterNotifications();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: ListTile(
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.title,
          style: AppStyle.txtInterMedium14.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.txtInterRegular12,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildPriorityChip(notification.priority),
                SizedBox(width: 8.w),
                _buildCategoryChip(notification.category),
                Spacer(),
                Text(
                  _formatDateTime(notification.createdAt),
                  style: AppStyle.txtInterRegular10.copyWith(
                    color: ColorConstant.gray500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onNotificationAction(value, notification.id),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read),
                  SizedBox(width: 8.w),
                  Text(notification.isRead ? 'Mark Unread' : 'Mark Read'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive),
                  SizedBox(width: 8.w),
                  Text('Archive'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'info':
        iconData = Icons.info;
        iconColor = Colors.blue;
        break;
      case 'warning':
        iconData = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'error':
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case 'success':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'urgent':
        iconData = Icons.priority_high;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'low':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.red;
        break;
      case 'critical':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppStyle.txtInterBold10.copyWith(color: color),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ColorConstant.blue600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ColorConstant.blue600.withOpacity(0.3)),
      ),
      child: Text(
        category.toUpperCase(),
        style: AppStyle.txtInterBold10.copyWith(color: ColorConstant.blue600),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16.h),
          child: ListTile(
            leading: Icon(Icons.template, color: ColorConstant.blue600),
            title: Text(template.name, style: AppStyle.txtInterMedium14),
            subtitle: Text(template.description, style: AppStyle.txtInterRegular12),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editTemplate(template),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendTemplateNotification(template),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    if (_userPreferences == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChannelSettings(),
          SizedBox(height: 24.h),
          _buildCategorySettings(),
          SizedBox(height: 24.h),
          _buildQuietHoursSettings(),
        ],
      ),
    );
  }

  Widget _buildChannelSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification Channels', style: AppStyle.txtInterBold18),
            SizedBox(height: 16.h),
            SwitchListTile(
              title: Text('Push Notifications'),
              subtitle: Text('Receive push notifications on your device'),
              value: _userPreferences!.enablePush,
              onChanged: (value) => _updateChannelSetting('push', value),
            ),
            SwitchListTile(
              title: Text('Email Notifications'),
              subtitle: Text('Receive notifications via email'),
              value: _userPreferences!.enableEmail,
              onChanged: (value) => _updateChannelSetting('email', value),
            ),
            SwitchListTile(
              title: Text('SMS Notifications'),
              subtitle: Text('Receive notifications via SMS'),
              value: _userPreferences!.enableSMS,
              onChanged: (value) => _updateChannelSetting('sms', value),
            ),
            SwitchListTile(
              title: Text('In-App Notifications'),
              subtitle: Text('Show notifications within the app'),
              value: _userPreferences!.enableInApp,
              onChanged: (value) => _updateChannelSetting('in_app', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category Preferences', style: AppStyle.txtInterBold18),
            SizedBox(height: 16.h),
            _buildCategoryToggle('System Notifications', 'system'),
            _buildCategoryToggle('Referral Updates', 'referral'),
            _buildCategoryToggle('Appointment Reminders', 'appointment'),
            _buildCategoryToggle('Payment Notifications', 'payment'),
            _buildCategoryToggle('Security Alerts', 'security'),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryToggle(String title, String category) {
    final isEnabled = _userPreferences!.categoryPreferences[category] ?? true;
    return SwitchListTile(
      title: Text(title),
      value: isEnabled,
      onChanged: (value) => _updateCategorySetting(category, value),
    );
  }

  Widget _buildQuietHoursSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quiet Hours', style: AppStyle.txtInterBold18),
            SizedBox(height: 16.h),
            SwitchListTile(
              title: Text('Enable Quiet Hours'),
              subtitle: Text('Suppress non-critical notifications during specified hours'),
              value: _userPreferences!.enableScheduledNotifications,
              onChanged: (value) => _updateQuietHoursEnabled(value),
            ),
            ListTile(
              title: Text('Start Time'),
              subtitle: Text(_userPreferences!.quietHoursStart),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(true),
            ),
            ListTile(
              title: Text('End Time'),
              subtitle: Text(_userPreferences!.quietHoursEnd),
              trailing: Icon(Icons.access_time),
              onTap: () => _selectTime(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final stats = _notificationService.getStatistics();
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCard('Total Notifications', stats['total_notifications'].toString(), Icons.notifications),
          _buildStatCard('Unread Notifications', stats['unread_notifications'].toString(), Icons.mark_email_unread),
          _buildStatCard('Delivery Rate', '${stats['delivery_rate'].toStringAsFixed(1)}%', Icons.check_circle),
          _buildStatCard('Failed Deliveries', stats['total_failed'].toString(), Icons.error),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(icon, size: 32, color: ColorConstant.blue600),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyle.txtInterMedium14),
                Text(value, style: AppStyle.txtInterBold24.copyWith(color: ColorConstant.blue600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: ColorConstant.gray400),
          SizedBox(height: 16.h),
          Text(
            'No notifications',
            style: AppStyle.txtInterBold18.copyWith(color: ColorConstant.gray400),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'re all caught up!',
            style: AppStyle.txtInterRegular14.copyWith(color: ColorConstant.gray500),
          ),
        ],
      ),
    );
  }

  void _filterNotifications() {
    // Implement filtering logic
    _loadNotifications();
  }

  void _onNotificationAction(String action, String notificationId) {
    switch (action) {
      case 'mark_read':
        _notificationService.markAsRead(notificationId);
        break;
      case 'archive':
        _notificationService.archiveNotification(notificationId);
        break;
      case 'delete':
        _deleteNotification(notificationId);
        break;
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }
    
    if (notification.actionUrl != null) {
      // Navigate to action URL
    }
  }

  void _deleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement delete logic
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Priority'),
              items: [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement create notification logic
              Navigator.pop(context);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editTemplate(NotificationTemplate template) {
    // Implement template editing
  }

  void _sendTemplateNotification(NotificationTemplate template) {
    // Implement template notification sending
  }

  void _updateChannelSetting(String channel, bool value) {
    // Implement channel setting update
  }

  void _updateCategorySetting(String category, bool value) {
    // Implement category setting update
  }

  void _updateQuietHoursEnabled(bool value) {
    // Implement quiet hours update
  }

  void _selectTime(bool isStartTime) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((time) {
      if (time != null) {
        // Implement time update
      }
    });
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'mark_all_read':
        // Implement mark all read
        break;
      case 'clear_archived':
        // Implement clear archived
        break;
      case 'statistics':
        _tabController.animateTo(3);
        break;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<NotificationTemplate> _getSampleTemplates() {
    return [
      NotificationTemplate(
        id: '1',
        name: 'Appointment Reminder',
        description: 'Remind patients about upcoming appointments',
        type: 'info',
        category: 'appointment',
        titleTemplate: 'Appointment Reminder - {{patientName}}',
        bodyTemplate: 'Your appointment with {{doctorName}} is scheduled for {{appointmentDate}} at {{appointmentTime}}.',
        defaultChannels: ['push', 'email'],
        defaultPriority: 'medium',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      NotificationTemplate(
        id: '2',
        name: 'Referral Update',
        description: 'Notify about referral status changes',
        type: 'info',
        category: 'referral',
        titleTemplate: 'Referral Update - {{referralId}}',
        bodyTemplate: 'Your referral to {{specialistName}} has been {{status}}.',
        defaultChannels: ['push', 'in_app'],
        defaultPriority: 'medium',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationUpdate);
    _tabController.dispose();
    super.dispose();
  }
}