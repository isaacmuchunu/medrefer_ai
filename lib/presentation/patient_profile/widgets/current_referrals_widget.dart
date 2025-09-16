
import '../../../core/app_export.dart';

class CurrentReferralsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> referrals;
  final Function(Map<String, dynamic>) onReferralTap;

  const CurrentReferralsWidget({
    super.key,
    required this.referrals,
    required this.onReferralTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'send',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Current Referrals",
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${referrals.length} Active",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          referrals.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondaryLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      CustomIconWidget(
                        iconName: 'assignment',
                        color: AppTheme.textSecondaryLight,
                        size: 32,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "No active referrals",
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: referrals.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final referral = referrals[index];
                    return GestureDetector(
                      onTap: () => onReferralTap(referral),
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(
                                    color: _getSpecialtyColor(
                                            referral["specialty"] as String? ??
                                                "")
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: CustomIconWidget(
                                      iconName: _getSpecialtyIcon(
                                          referral["specialty"] as String? ??
                                              ""),
                                      color: _getSpecialtyColor(
                                          referral["specialty"] as String? ??
                                              ""),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        referral["specialty"] as String? ??
                                            "Unknown Specialty",
                                        style: AppTheme
                                            .lightTheme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        "Dr. ${referral["specialistName"] ?? "Unknown"}",
                                        style: AppTheme
                                            .lightTheme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: AppTheme.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        referral["status"] as String? ?? ""),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    referral["status"] as String? ?? "Unknown",
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              referral["reason"] as String? ??
                                  "No reason provided",
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'calendar_today',
                                  color: AppTheme.textSecondaryLight,
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  "Referred: ${referral["referredDate"] ?? "N/A"}",
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.textSecondaryLight,
                                    fontSize: 10.sp,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Handle message action
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(
                                          color: AppTheme
                                              .lightTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: CustomIconWidget(
                                          iconName: 'message',
                                          color:
                                              AppTheme.lightTheme.primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    GestureDetector(
                                      onTap: () {
                                        // Handle call action
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(2.w),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successLight
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: CustomIconWidget(
                                          iconName: 'phone',
                                          color: AppTheme.successLight,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Color _getSpecialtyColor(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return AppTheme.errorLight;
      case 'neurology':
        return AppTheme.lightTheme.primaryColor;
      case 'orthopedics':
        return AppTheme.warningLight;
      case 'dermatology':
        return AppTheme.successLight;
      case 'oncology':
        return AppTheme.accentLight;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  String _getSpecialtyIcon(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return 'favorite';
      case 'neurology':
        return 'psychology';
      case 'orthopedics':
        return 'accessibility';
      case 'dermatology':
        return 'face';
      case 'oncology':
        return 'healing';
      default:
        return 'local_hospital';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningLight;
      case 'accepted':
        return AppTheme.successLight;
      case 'scheduled':
        return AppTheme.lightTheme.primaryColor;
      case 'completed':
        return AppTheme.completedState;
      case 'cancelled':
        return AppTheme.errorLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
