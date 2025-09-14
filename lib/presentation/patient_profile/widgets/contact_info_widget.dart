
import '../../../core/app_export.dart';

class ContactInfoWidget extends StatelessWidget {
  final Map<String, dynamic> contactData;
  final List<Map<String, dynamic>> emergencyContacts;

  const ContactInfoWidget({
    Key? key,
    required this.contactData,
    required this.emergencyContacts,
  }) : super(key: key);

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
                iconName: 'contact_phone',
                color: AppTheme.successLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Contact Information",
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Patient Contact Info
          _buildContactSection(
            title: "Patient Contact",
            contacts: [
              {
                "type": "Phone",
                "value": contactData["phone"] ?? "Not provided",
                "icon": "phone",
                "action": "call"
              },
              {
                "type": "Email",
                "value": contactData["email"] ?? "Not provided",
                "icon": "email",
                "action": "email"
              },
              {
                "type": "Address",
                "value": contactData["address"] ?? "Not provided",
                "icon": "location_on",
                "action": "map"
              },
            ],
          ),
          SizedBox(height: 4.h),
          // Emergency Contacts
          _buildEmergencyContactsSection(),
        ],
      ),
    );
  }

  Widget _buildContactSection({
    required String title,
    required List<Map<String, dynamic>> contacts,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (context, index) => SizedBox(height: 2.h),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: _getContactTypeColor(contact["type"] as String)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: contact["icon"] as String,
                        color: _getContactTypeColor(contact["type"] as String),
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact["type"] as String,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          contact["value"] as String,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (contact["value"] != "Not provided")
                    GestureDetector(
                      onTap: () => _handleContactAction(
                          contact["action"] as String,
                          contact["value"] as String),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _getContactTypeColor(contact["type"] as String)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: CustomIconWidget(
                          iconName: contact["action"] == "call"
                              ? "phone"
                              : contact["action"] == "email"
                                  ? "email"
                                  : "map",
                          color:
                              _getContactTypeColor(contact["type"] as String),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'emergency',
              color: AppTheme.errorLight,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              "Emergency Contacts",
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.errorLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${emergencyContacts.length} Contacts",
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorLight,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        emergencyContacts.isEmpty
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
                      iconName: 'person_add',
                      color: AppTheme.textSecondaryLight,
                      size: 32,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "No emergency contacts",
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: emergencyContacts.length,
                separatorBuilder: (context, index) => SizedBox(height: 2.h),
                itemBuilder: (context, index) {
                  final contact = emergencyContacts[index];
                  return Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorLight.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: AppTheme.errorLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'emergency',
                              color: AppTheme.errorLight,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact["name"] as String? ?? "Unknown Contact",
                                style: AppTheme.lightTheme.textTheme.titleSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                contact["relationship"] as String? ??
                                    "Unknown Relationship",
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                contact["phone"] as String? ??
                                    "No phone number",
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _handleContactAction(
                                  "call", contact["phone"] as String? ?? ""),
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.successLight
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'phone',
                                  color: AppTheme.successLight,
                                  size: 16,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            GestureDetector(
                              onTap: () => _handleContactAction(
                                  "message", contact["phone"] as String? ?? ""),
                              child: Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CustomIconWidget(
                                  iconName: 'message',
                                  color: AppTheme.lightTheme.primaryColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  Color _getContactTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return AppTheme.successLight;
      case 'email':
        return AppTheme.lightTheme.primaryColor;
      case 'address':
        return AppTheme.warningLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  void _handleContactAction(String action, String value) {
    // Handle contact actions (call, email, map)
    switch (action) {
      case 'call':
        // Implement phone call functionality
        break;
      case 'email':
        // Implement email functionality
        break;
      case 'map':
        // Implement map navigation functionality
        break;
      case 'message':
        // Implement messaging functionality
        break;
    }
  }
}
