import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';

class ReferralCardWidget extends StatelessWidget {
  final Map<String, dynamic> referralData;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onViewDetails;
  final VoidCallback? onArchive;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExportPdf;
  final VoidCallback? onShare;

  const ReferralCardWidget({
    super.key,
    required this.referralData,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onUpdateStatus,
    this.onViewDetails,
    this.onArchive,
    this.onDuplicate,
    this.onExportPdf,
    this.onShare,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningLight;
      case 'approved':
        return AppTheme.primaryLight;
      case 'completed':
        return AppTheme.successLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = referralData['patient'] as Map<String, dynamic>? ?? {};
    final specialist =
        referralData['specialist'] as Map<String, dynamic>? ?? {};
    final status = referralData['status'] as String? ?? 'Unknown';
    final aiConfidence = referralData['aiConfidence'] as double? ?? 0.0;
    final estimatedTime = referralData['estimatedTime'] as String? ?? 'N/A';
    final urgency = referralData['urgency'] as String? ?? 'Normal';
    final trackingNumber = referralData['trackingNumber'] as String? ?? '';
    final lastUpdate = referralData['lastUpdate'] as DateTime?;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Slidable(
        key: ValueKey(referralData['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onCall?.call(),
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              icon: Icons.phone,
              label: 'Call',
            ),
            SlidableAction(
              onPressed: (_) => onMessage?.call(),
              backgroundColor: AppTheme.secondaryLight,
              foregroundColor: Colors.white,
              icon: Icons.message,
              label: 'Message',
            ),
            SlidableAction(
              onPressed: (_) => onUpdateStatus?.call(),
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
              icon: Icons.update,
              label: 'Update',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onArchive?.call(),
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with patient info and status
                Row(
                  children: [
                    // Patient photo
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.borderLight,
                          width: 1,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: patient['photo'] as String? ?? '',
                          width: 12.w,
                          height: 12.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    // Patient details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient['name'] as String? ?? 'Unknown Patient',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'ID: ${patient['id'] ?? 'N/A'} • Age: ${patient['age'] ?? 'N/A'}',
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Status badge and urgency
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor(status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (urgency != 'Normal') ...[
                          SizedBox(height: 0.5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w, vertical: 0.3.h),
                            decoration: BoxDecoration(
                              color: urgency == 'High'
                                  ? AppTheme.errorLight
                                  : AppTheme.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              urgency.toUpperCase(),
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
                  ],
                ),
                SizedBox(height: 2.h),
                // Specialist info
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'local_hospital',
                      color: AppTheme.primaryLight,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist['name'] as String? ??
                                'Unknown Specialist',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${specialist['specialty'] ?? 'N/A'} • ${specialist['hospital'] ?? 'N/A'}',
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // AI confidence and estimated time
                Row(
                  children: [
                    // AI confidence
                    Expanded(
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'psychology',
                            color: AppTheme.secondaryLight,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'AI Match: ${(aiConfidence * 100).toInt()}%',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.secondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Estimated time
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: AppTheme.textSecondaryLight,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'ETA: $estimatedTime',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // Tracking number and last update
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tracking: $trackingNumber',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lastUpdate != null)
                      Text(
                        'Updated: ${_formatLastUpdate(lastUpdate)}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                // Timeline indicator
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppTheme.borderLight,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getProgressFactor(status),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getProgressFactor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0.25;
      case 'approved':
        return 0.75;
      case 'completed':
        return 1.0;
      default:
        return 0.1;
    }
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Referral Actions',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildContextMenuItem(
              context,
              'View Details',
              Icons.visibility,
              onViewDetails,
            ),
            _buildContextMenuItem(
              context,
              'Duplicate Referral',
              Icons.copy,
              onDuplicate,
            ),
            _buildContextMenuItem(
              context,
              'Export PDF',
              Icons.picture_as_pdf,
              onExportPdf,
            ),
            _buildContextMenuItem(
              context,
              'Share with Team',
              Icons.share,
              onShare,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.toString().split('.').last,
        color: AppTheme.primaryLight,
        size: 20,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }
}
