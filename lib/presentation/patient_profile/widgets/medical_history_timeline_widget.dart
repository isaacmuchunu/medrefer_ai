
import '../../../core/app_export.dart';

class MedicalHistoryTimelineWidget extends StatefulWidget {
  final List<Map<String, dynamic>> historyData;

  const MedicalHistoryTimelineWidget({
    super.key,
    required this.historyData,
  });

  @override
  State<MedicalHistoryTimelineWidget> createState() =>
      _MedicalHistoryTimelineWidgetState();
}

class _MedicalHistoryTimelineWidgetState
    extends State<MedicalHistoryTimelineWidget> {
  int? expandedIndex;

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
                iconName: 'history',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Medical History Timeline",
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.secondary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${widget.historyData.length} Entries",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          widget.historyData.isEmpty
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
                        iconName: 'history_edu',
                        color: AppTheme.textSecondaryLight,
                        size: 32,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "No medical history available",
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.historyData.length,
                  itemBuilder: (context, index) {
                    final entry = widget.historyData[index];
                    final isExpanded = expandedIndex == index;
                    final isLast = index == widget.historyData.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getEntryTypeColor(
                                      entry["type"] as String? ?? ""),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppTheme.lightTheme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppTheme.borderLight,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  expandedIndex = isExpanded ? null : index;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 3.h),
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: _getEntryTypeColor(
                                          entry["type"] as String? ?? "")
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getEntryTypeColor(
                                            entry["type"] as String? ?? "")
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2.w, vertical: 0.5.h),
                                          decoration: BoxDecoration(
                                            color: _getEntryTypeColor(
                                                entry["type"] as String? ?? ""),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            entry["type"] as String? ??
                                                "Unknown",
                                            style: AppTheme
                                                .lightTheme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          entry["date"] as String? ?? "N/A",
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.textSecondaryLight,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        CustomIconWidget(
                                          iconName: isExpanded
                                              ? 'expand_less'
                                              : 'expand_more',
                                          color: AppTheme.textSecondaryLight,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      entry["title"] as String? ??
                                          "Unknown Entry",
                                      style: AppTheme
                                          .lightTheme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: isExpanded ? null : 1,
                                      overflow: isExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      entry["description"] as String? ??
                                          "No description available",
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textSecondaryLight,
                                      ),
                                      maxLines: isExpanded ? null : 2,
                                      overflow: isExpanded
                                          ? null
                                          : TextOverflow.ellipsis,
                                    ),
                                    if (isExpanded &&
                                        entry["provider"] != null) ...[
                                      SizedBox(height: 2.h),
                                      Row(
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'person',
                                            color: AppTheme.textSecondaryLight,
                                            size: 14,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            "Provider: ${entry["provider"]}",
                                            style: AppTheme
                                                .lightTheme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  AppTheme.textSecondaryLight,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isExpanded &&
                                        entry["location"] != null) ...[
                                      SizedBox(height: 0.5.h),
                                      Row(
                                        children: [
                                          CustomIconWidget(
                                            iconName: 'location_on',
                                            color: AppTheme.textSecondaryLight,
                                            size: 14,
                                          ),
                                          SizedBox(width: 1.w),
                                          Text(
                                            "Location: ${entry["location"]}",
                                            style: AppTheme
                                                .lightTheme.textTheme.bodySmall
                                                ?.copyWith(
                                              color:
                                                  AppTheme.textSecondaryLight,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Color _getEntryTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'surgery':
        return AppTheme.errorLight;
      case 'diagnosis':
        return AppTheme.warningLight;
      case 'treatment':
        return AppTheme.successLight;
      case 'procedure':
        return AppTheme.lightTheme.primaryColor;
      case 'consultation':
        return AppTheme.lightTheme.colorScheme.secondary;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
