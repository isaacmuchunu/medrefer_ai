import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/app_export.dart';

class PatientHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> patientData;
  final bool isPrivacyEnabled;
  final VoidCallback onPrivacyToggle;
  final LocalAuthentication _localAuth = LocalAuthentication();

  PatientHeaderWidget({
    super.key,
    required this.patientData,
    required this.isPrivacyEnabled,
    required this.onPrivacyToggle,
  });

  Future<void> _authenticateAndTogglePrivacy(BuildContext context) async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to show patient details',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuthenticate) {
        onPrivacyToggle();
      }
    } catch (e) {
      // Handle error
    }
  }

  void _showQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: patientData["medicalRecordNumber"] ?? "N/A",
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
      ),
    );
  }

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
        children: [
          Row(
            children: [
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.primaryColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: (patientData["photo"] as String?) ?? "",
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isPrivacyEnabled
                                ? "****** ******"
                                : (patientData["name"] as String?) ??
                                    "Unknown Patient",
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _authenticateAndTogglePrivacy(context),
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: isPrivacyEnabled
                                  ? AppTheme.warningLight.withValues(alpha: 0.1)
                                  : AppTheme.successLight
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomIconWidget(
                              iconName: isPrivacyEnabled
                                  ? 'visibility_off'
                                  : 'visibility',
                              color: isPrivacyEnabled
                                  ? AppTheme.warningLight
                                  : AppTheme.successLight,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildInfoChip(
                            "Age: ${patientData["age"] ?? "N/A"}",
                            AppTheme.lightTheme.primaryColor,
                          ),
                          SizedBox(width: 2.w),
                          _buildInfoChip(
                            "ID: ${isPrivacyEnabled ? "****" : (patientData["medicalRecordNumber"] ?? "N/A")}",
                            AppTheme.lightTheme.colorScheme.secondary,
                          ),
                          SizedBox(width: 2.w),
                          _buildInfoChip(
                            patientData["status"] ?? "Status N/A",
                            patientData["status"] == "Admitted" ? Colors.green : Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionChip(
                context,
                icon: 'call',
                label: 'Contact',
                onTap: () {
                  // Show emergency contact
                },
              ),
              _buildActionChip(
                context,
                icon: 'qr_code',
                label: 'Show QR',
                onTap: () => _showQrCode(context),
              ),
              _buildActionChip(
                context,
                icon: 'warning',
                label: 'Allergies',
                onTap: () {
                  // Show allergies
                },
                isAlert: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionChip(BuildContext context,
      {required String icon,
      required String label,
      required VoidCallback onTap,
      bool isAlert = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isAlert
                  ? AppTheme.lightTheme.colorScheme.errorContainer
                  : AppTheme.lightTheme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: isAlert
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
