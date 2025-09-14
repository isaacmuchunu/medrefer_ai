
import '../../../core/app_export.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;

  const MessageBubbleWidget({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 4.w),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 2.5.h,
              backgroundImage: NetworkImage(message['senderAvatar'] ?? ''),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 70.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.w),
                  topRight: Radius.circular(4.w),
                  bottomLeft: isCurrentUser
                      ? Radius.circular(4.w)
                      : Radius.circular(1.w),
                  bottomRight: isCurrentUser
                      ? Radius.circular(1.w)
                      : Radius.circular(4.w),
                ),
                border: !isCurrentUser
                    ? Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.2),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['type'] == 'referral_context') ...[
                    Container(
                      padding: EdgeInsets.all(2.w),
                      margin: EdgeInsets.only(bottom: 1.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.w),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'medical_services',
                            color: AppTheme.lightTheme.colorScheme.tertiary,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Referral: ${message['referralTitle'] ?? 'Patient Case'}',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (message['attachments'] != null &&
                      (message['attachments'] as List).isNotEmpty) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: Wrap(
                        spacing: 2.w,
                        runSpacing: 1.h,
                        children: (message['attachments'] as List)
                            .map<Widget>((attachment) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppTheme.lightTheme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2.w),
                              border: Border.all(
                                color: isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : AppTheme.lightTheme.colorScheme.primary
                                        .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName:
                                      _getAttachmentIcon(attachment['type']),
                                  color: isCurrentUser
                                      ? Colors.white
                                      : AppTheme.lightTheme.colorScheme.primary,
                                  size: 14,
                                ),
                                SizedBox(width: 2.w),
                                Flexible(
                                  child: Text(
                                    attachment['name'] ?? 'Document',
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : AppTheme
                                              .lightTheme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  Text(
                    message['content'] ?? '',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isCurrentUser
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message['timestamp']),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: isCurrentUser
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 1.w),
                        CustomIconWidget(
                          iconName: message['status'] == 'delivered'
                              ? 'done_all'
                              : 'done',
                          color: message['status'] == 'delivered'
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : Colors.white.withValues(alpha: 0.8),
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              radius: 2.5.h,
              backgroundImage: NetworkImage(message['senderAvatar'] ?? ''),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary
                  .withValues(alpha: 0.1),
            ),
          ],
        ],
      ),
    );
  }

  String _getAttachmentIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'image':
      case 'jpg':
      case 'png':
        return 'image';
      case 'doc':
      case 'docx':
        return 'description';
      default:
        return 'attach_file';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
