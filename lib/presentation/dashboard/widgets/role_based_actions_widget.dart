import '../../../core/app_export.dart';

class RoleBasedActionsWidget extends StatelessWidget {
  final String userRole;
  final List<String> permissions;
  final Function(String)? onActionTap;

  const RoleBasedActionsWidget({
    super.key,
    required this.userRole,
    required this.permissions,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _getActionsForRole(userRole, permissions);
    
    if (actions.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(action, theme);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            action['color'].withOpacity(0.1),
            action['color'].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: action['color'].withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: action['color'].withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onActionTap?.call(action['route']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: action['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action['icon'],
                    color: action['color'],
                    size: 28,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  action['title'],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: action['color'],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  action['subtitle'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getActionsForRole(String role, List<String> permissions) {
    final allActions = <Map<String, dynamic>>[
      // Admin Actions
      {
        'title': 'System Analytics',
        'subtitle': 'View system performance',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'route': '/analytics',
        'permission': 'view_analytics',
        'roles': ['admin'],
      },
      {
        'title': 'User Management',
        'subtitle': 'Manage system users',
        'icon': Icons.people_alt,
        'color': Colors.indigo,
        'route': '/user-management',
        'permission': 'manage_users',
        'roles': ['admin'],
      },
      
      // Doctor Actions
      {
        'title': 'Create Referral',
        'subtitle': 'Start new patient referral',
        'icon': Icons.assignment_add,
        'color': Colors.blue,
        'route': '/create-referral',
        'permission': 'create_referral',
        'roles': ['doctor', 'nurse', 'admin'],
      },
      {
        'title': 'My Patients',
        'subtitle': 'View patient records',
        'icon': Icons.people,
        'color': Colors.green,
        'route': '/patients',
        'permission': 'view_patients',
        'roles': ['doctor', 'nurse', 'admin'],
      },
      {
        'title': 'Schedule Appointment',
        'subtitle': 'Book patient appointments',
        'icon': Icons.calendar_today,
        'color': Colors.orange,
        'route': '/appointment-scheduling',
        'permission': 'schedule_appointments',
        'roles': ['doctor', 'nurse', 'admin'],
      },
      {
        'title': 'Secure Messages',
        'subtitle': 'HIPAA-compliant messaging',
        'icon': Icons.message,
        'color': Colors.teal,
        'route': '/messages',
        'permission': 'send_messages',
        'roles': ['doctor', 'nurse', 'specialist', 'admin'],
      },
      
      // Specialist Actions
      {
        'title': 'Incoming Referrals',
        'subtitle': 'Review new referrals',
        'icon': Icons.inbox,
        'color': Colors.cyan,
        'route': '/incoming-referrals',
        'permission': 'view_referrals',
        'roles': ['specialist', 'admin'],
      },
      {
        'title': 'Consultation Schedule',
        'subtitle': 'Manage your schedule',
        'icon': Icons.schedule,
        'color': Colors.amber,
        'route': '/consultation-schedule',
        'permission': 'manage_schedule',
        'roles': ['specialist', 'doctor', 'admin'],
      },
      
      // Universal Actions
      {
        'title': 'Teleconference',
        'subtitle': 'Start video consultation',
        'icon': Icons.video_call,
        'color': Colors.red,
        'route': '/teleconference',
        'permission': 'video_calls',
        'roles': ['doctor', 'specialist', 'admin'],
      },
      {
        'title': 'Document Viewer',
        'subtitle': 'View medical documents',
        'icon': Icons.description,
        'color': Colors.brown,
        'route': '/documents',
        'permission': 'view_documents',
        'roles': ['doctor', 'nurse', 'specialist', 'admin'],
      },
    ];

    // Filter actions based on role and permissions
    return allActions.where((action) {
      final actionRoles = action['roles'] as List<String>;
      final actionPermission = action['permission'] as String;
      
      return actionRoles.contains(role.toLowerCase()) && 
             permissions.contains(actionPermission);
    }).toList();
  }
}
