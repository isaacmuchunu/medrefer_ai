
import '../../../core/app_export.dart';

class DocumentsViewerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> documents;

  const DocumentsViewerWidget({
    Key? key,
    required this.documents,
  }) : super(key: key);

  @override
  State<DocumentsViewerWidget> createState() => _DocumentsViewerWidgetState();
}

class _DocumentsViewerWidgetState extends State<DocumentsViewerWidget> {
  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Lab Reports",
    "X-Rays",
    "Prescriptions",
    "Discharge Notes"
  ];

  @override
  Widget build(BuildContext context) {
    final filteredDocuments = selectedCategory == "All"
        ? widget.documents
        : widget.documents
            .where((doc) => doc["category"] == selectedCategory)
            .toList();

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
                iconName: 'folder',
                color: AppTheme.warningLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Medical Documents",
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.warningLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${widget.documents.length} Files",
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningLight,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Category Filter
          SizedBox(
            height: 5.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => SizedBox(width: 2.w),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 3.h),
          // Documents Grid
          filteredDocuments.isEmpty
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
                        iconName: 'description',
                        color: AppTheme.textSecondaryLight,
                        size: 32,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        selectedCategory == "All"
                            ? "No documents available"
                            : "No documents in $selectedCategory",
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3.w,
                    mainAxisSpacing: 2.h,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredDocuments.length,
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    return GestureDetector(
                      onTap: () => _viewDocument(document),
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
                            Container(
                              width: double.infinity,
                              height: 15.h,
                              decoration: BoxDecoration(
                                color: _getDocumentTypeColor(
                                        document["type"] as String? ?? "")
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: document["type"]?.toLowerCase() ==
                                          "image" &&
                                      document["thumbnail"] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CustomImageWidget(
                                        imageUrl:
                                            document["thumbnail"] as String,
                                        width: double.infinity,
                                        height: 15.h,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Center(
                                      child: CustomIconWidget(
                                        iconName: _getDocumentTypeIcon(
                                            document["type"] as String? ?? ""),
                                        color: _getDocumentTypeColor(
                                            document["type"] as String? ?? ""),
                                        size: 32,
                                      ),
                                    ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              document["name"] as String? ?? "Unknown Document",
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: _getDocumentTypeColor(
                                            document["type"] as String? ?? "")
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    document["category"] as String? ??
                                        "Unknown",
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: _getDocumentTypeColor(
                                          document["type"] as String? ?? ""),
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'calendar_today',
                                  color: AppTheme.textSecondaryLight,
                                  size: 12,
                                ),
                                SizedBox(width: 1.w),
                                Expanded(
                                  child: Text(
                                    document["date"] as String? ?? "N/A",
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.textSecondaryLight,
                                      fontSize: 9.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

  void _viewDocument(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 90.w,
          height: 80.h,
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName:
                        _getDocumentTypeIcon(document["type"] as String? ?? ""),
                    color: _getDocumentTypeColor(
                        document["type"] as String? ?? ""),
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      document["name"] as String? ?? "Unknown Document",
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.textSecondaryLight,
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  child: document["type"]?.toLowerCase() == "image" &&
                          document["url"] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: InteractiveViewer(
                            child: CustomImageWidget(
                              imageUrl: document["url"] as String,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomIconWidget(
                                iconName: _getDocumentTypeIcon(
                                    document["type"] as String? ?? ""),
                                color: _getDocumentTypeColor(
                                    document["type"] as String? ?? ""),
                                size: 48,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "Document Preview",
                                style:
                                    AppTheme.lightTheme.textTheme.titleMedium,
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                "Tap to download and view",
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return AppTheme.errorLight;
      case 'image':
        return AppTheme.successLight;
      case 'lab':
        return AppTheme.lightTheme.primaryColor;
      case 'prescription':
        return AppTheme.warningLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  String _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return 'picture_as_pdf';
      case 'image':
        return 'image';
      case 'lab':
        return 'science';
      case 'prescription':
        return 'medication';
      default:
        return 'description';
    }
  }
}
