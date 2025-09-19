export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:sizer/sizer.dart';
export 'package:provider/provider.dart';
export 'package:connectivity_plus/connectivity_plus.dart';

// Core exports
export '../routes/app_routes.dart';
export '../theme/app_theme.dart';
export 'result.dart';
export 'extensions.dart';

// Widget exports
export '../widgets/custom_icon_widget.dart';
export '../widgets/custom_image_widget.dart';
export '../widgets/custom_error_widget.dart';

// Database exports
export '../database/database_helper.dart';
export '../database/services/data_service.dart';
export '../database/services/migration_service.dart';
export '../database/models/user.dart';
export '../database/models/patient.dart';
export '../database/models/specialist.dart';
export '../database/models/referral.dart';
export '../database/models/message.dart';
export '../database/models/medical_history.dart';
export '../database/models/medication.dart';
export '../database/models/condition.dart';
export '../database/models/document.dart';
export '../database/models/emergency_contact.dart';
export '../database/models/vital_statistics.dart';
export '../database/models/pharmacy_drug.dart';

// Services exports
export '../services/auth_service.dart';
export '../services/biometric_service.dart';
export '../services/notification_service.dart';
export '../services/sync_service.dart';
export '../services/error_handling_service.dart';
export '../services/logging_service.dart';
export '../services/webrtc_service.dart';
export '../services/document_security_service.dart';
export '../services/security_audit_service.dart';
export '../services/pharmacy_service.dart';
export '../services/mpesa_service.dart';
export '../services/rbac_service.dart';
export '../services/route_guard_service.dart';
export '../services/enhanced_security_service.dart';
export '../services/validation_service.dart';
export '../services/accessibility_service.dart';
export '../services/internationalization_service.dart';
export '../services/realtime_update_service.dart';

// Core services exports
export 'performance/performance_service.dart';
export 'realtime/realtime_service.dart';

// Widgets
export '../widgets/protected_route.dart';
