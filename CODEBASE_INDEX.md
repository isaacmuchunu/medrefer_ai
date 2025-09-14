# MedRefer AI - Complete Codebase Index

## 📋 Project Overview
- **Project Name**: MedRefer AI
- **Type**: Flutter Mobile/Web Application
- **Version**: 1.0.0+1
- **Flutter SDK**: ^3.6.0
- **Dart SDK**: ^3.6.0
- **Description**: Medical referral management system with AI-powered recommendations
- **Architecture**: Offline-first with SQLite and Supabase backend

## 🗂️ Directory Structure

### 📱 Platform Configurations
```
├── android/                    # Android platform configuration
│   ├── app/
│   │   ├── src/
│   │   │   ├── debug/         # Debug manifest
│   │   │   ├── main/          # Main source code
│   │   │   │   ├── java/      # Generated plugin registrant
│   │   │   │   ├── kotlin/    # MainActivity.kt
│   │   │   │   └── res/       # Resources (layouts, values, drawables)
│   │   │   └── profile/       # Profile manifest
│   │   └── build.gradle       # App-level Gradle config
│   ├── build.gradle           # Project-level Gradle config
│   └── settings.gradle        # Gradle settings
│
├── ios/                       # iOS platform configuration
│   ├── Runner/
│   │   ├── Assets.xcassets/  # App icons and launch images
│   │   └── AppDelegate.swift # iOS app delegate
│   └── RunnerTests/           # iOS tests
│
└── web/                       # Web platform configuration
    ├── index.html             # Main HTML entry
    ├── manifest.json          # Web app manifest
    └── flutter_plugins.js     # Plugin registration
```

### 🎨 Assets & Resources
```
├── assets/
│   ├── images/               # Static images and icons
│   └── (root level assets)   # Other static resources
```

### 📚 Documentation
```
├── docs/
│   ├── API_DOCUMENTATION.md       # API endpoints and integration
│   ├── DATABASE_SCHEMA.md         # Database structure and models
│   ├── DEPLOYMENT_GUIDE.md        # Deployment instructions
│   └── SCREENS_DOCUMENTATION.md   # UI screen documentation
```

### 💻 Source Code (`lib/`)

#### Core Configuration & Utilities
```
├── lib/
│   ├── main.dart                  # Application entry point
│   │
│   ├── config/
│   │   └── mpesa_config.dart     # M-Pesa payment configuration
│   │
│   ├── core/
│   │   ├── app_export.dart       # Central exports file
│   │   ├── performance/
│   │   │   └── performance_service.dart  # Performance monitoring
│   │   ├── realtime/
│   │   │   └── realtime_service.dart     # Real-time data sync
│   │   └── search/
│   │       └── search_service.dart       # Search functionality
```

#### Database Layer
```
│   ├── database/
│   │   ├── database.dart          # Database exports
│   │   ├── database_helper.dart   # SQLite helper class
│   │   │
│   │   ├── dao/                   # Data Access Objects
│   │   │   ├── dao.dart           # Base DAO interface
│   │   │   ├── appointment_dao.dart
│   │   │   ├── condition_dao.dart
│   │   │   ├── document_dao.dart
│   │   │   ├── emergency_contact_dao.dart
│   │   │   ├── feedback_dao.dart
│   │   │   ├── insurance_dao.dart
│   │   │   ├── lab_result_dao.dart
│   │   │   ├── medical_history_dao.dart
│   │   │   ├── medication_dao.dart
│   │   │   ├── message_dao.dart
│   │   │   ├── patient_dao.dart
│   │   │   ├── payment_dao.dart
│   │   │   ├── pharmacy_dao.dart
│   │   │   ├── prescription_dao.dart
│   │   │   ├── referral_dao.dart
│   │   │   ├── specialist_dao.dart
│   │   │   ├── user_dao.dart
│   │   │   └── vital_statistics_dao.dart
│   │   │
│   │   ├── models/                # Data Models
│   │   │   ├── models.dart        # Model exports
│   │   │   ├── base_model.dart    # Base model class
│   │   │   ├── condition.dart
│   │   │   ├── document.dart
│   │   │   ├── emergency_contact.dart
│   │   │   ├── medical_history.dart
│   │   │   ├── medication.dart
│   │   │   ├── message.dart
│   │   │   ├── patient.dart
│   │   │   ├── pharmacy_drug.dart
│   │   │   ├── referral.dart
│   │   │   ├── specialist.dart
│   │   │   ├── user.dart
│   │   │   └── vital_statistics.dart
│   │   │
│   │   └── services/              # Database Services
│   │       ├── data_service.dart
│   │       └── migration_service.dart
```

#### Presentation Layer (Screens)
```
│   ├── presentation/              # UI Screens (40+ screens)
│   │   │
│   │   ├── splash_screen/         # App initialization
│   │   ├── onboarding_screen/     # New user onboarding
│   │   │
│   │   ├── Authentication:
│   │   ├── login_screen/
│   │   ├── registration_screen/
│   │   ├── signup_screen/
│   │   ├── signup_success_screen/
│   │   ├── forgot_password_screen/
│   │   ├── reset_password_screen/
│   │   ├── create_new_password_screen/
│   │   ├── verify_code_screen/
│   │   ├── biometrics_screen/
│   │   ├── logout_confirmation_screen/
│   │   │
│   │   ├── Dashboard & Admin:
│   │   ├── dashboard/
│   │   │   └── widgets/
│   │   │       ├── activity_item_widget.dart
│   │   │       ├── bottom_nav_bar_widget.dart
│   │   │       ├── emergency_alert_widget.dart
│   │   │       ├── header_widget.dart
│   │   │       ├── metric_card_widget.dart
│   │   │       ├── quick_action_card_widget.dart
│   │   │       └── role_based_actions_widget.dart
│   │   ├── admin_dashboard/
│   │   │
│   │   ├── Patient Management:
│   │   ├── patient_search_screen/
│   │   ├── add_patient_screen/
│   │   ├── patient_profile/
│   │   │   └── widgets/
│   │   │       ├── active_conditions_widget.dart
│   │   │       ├── contact_info_widget.dart
│   │   │       ├── current_medications_widget.dart
│   │   │       ├── current_referrals_widget.dart
│   │   │       ├── documents_viewer_widget.dart
│   │   │       ├── medical_history_timeline_widget.dart
│   │   │       ├── patient_header_widget.dart
│   │   │       └── vital_statistics_card_widget.dart
│   │   ├── patient_profile_screen/
│   │   │
│   │   ├── Referral System:
│   │   ├── create_referral/
│   │   │   └── widgets/
│   │   │       ├── document_upload_widget.dart
│   │   │       ├── medical_history_widget.dart
│   │   │       ├── patient_selection_widget.dart
│   │   │       ├── specialist_matching_widget.dart
│   │   │       ├── symptoms_description_widget.dart
│   │   │       └── urgency_selector_widget.dart
│   │   ├── create_referral_screen/
│   │   ├── referral_tracking/
│   │   │   └── widgets/
│   │   │       ├── filter_bottom_sheet_widget.dart
│   │   │       ├── referral_card_widget.dart
│   │   │       ├── search_bar_widget.dart
│   │   │       ├── status_tab_bar_widget.dart
│   │   │       └── sync_indicator_widget.dart
│   │   │
│   │   ├── Specialist & Doctors:
│   │   ├── specialist_directory/
│   │   │   └── widgets/
│   │   │       ├── ai_recommendations_widget.dart
│   │   │       ├── filter_bottom_sheet_widget.dart
│   │   │       ├── map_view_widget.dart
│   │   │       ├── search_bar_widget.dart
│   │   │       └── specialist_card_widget.dart
│   │   ├── specialist_profile_screen/
│   │   ├── specialist_selection_screen/
│   │   ├── doctor_detail_screen/
│   │   ├── top_doctors_screen/
│   │   │
│   │   ├── Appointments:
│   │   ├── appointment_scheduling_screen/
│   │   ├── appointment_history/
│   │   ├── booking_screen/
│   │   ├── booking_success_screen/
│   │   ├── schedule_screen/
│   │   │
│   │   ├── Medical Records:
│   │   ├── lab_results/
│   │   ├── prescription_management/
│   │   ├── document_viewer_screen/
│   │   ├── health_analytics/
│   │   │
│   │   ├── Communication:
│   │   ├── secure_messaging/
│   │   │   └── widgets/
│   │   │       ├── conversation_header_widget.dart
│   │   │       ├── message_bubble_widget.dart
│   │   │       ├── message_input_widget.dart
│   │   │       ├── quick_reply_widget.dart
│   │   │       └── referral_context_card_widget.dart
│   │   ├── chat_screen/
│   │   ├── teleconference_call_screen/
│   │   ├── audio_call_screen/
│   │   ├── notifications_screen/
│   │   │
│   │   ├── Pharmacy & Payments:
│   │   ├── pharmacy_screen/
│   │   │   └── widgets/
│   │   │       ├── category_chip_widget.dart
│   │   │       ├── drug_card_widget.dart
│   │   │       └── search_bar_widget.dart
│   │   ├── drug_detail_screen/
│   │   ├── cart_screen/
│   │   ├── payment_screen/
│   │   ├── mpesa_payment_screen/
│   │   ├── billing_payment/
│   │   ├── insurance_verification/
│   │   │
│   │   ├── User Profile & Settings:
│   │   ├── profile_screen/
│   │   ├── profile_edit/
│   │   ├── settings_screen/
│   │   │
│   │   ├── Support & Info:
│   │   ├── help_support_screen/
│   │   ├── articles_screen/
│   │   ├── feedback_rating/
│   │   │
│   │   └── System:
│   │       └── error_offline_screen/
```

#### Services Layer
```
│   ├── services/                  # Business Logic Services
│   │   ├── auth_service.dart      # Authentication & session management
│   │   ├── biometric_service.dart # Biometric authentication
│   │   ├── document_security_service.dart  # Document encryption
│   │   ├── error_handling_service.dart     # Error management
│   │   ├── mpesa_service.dart     # M-Pesa payment integration
│   │   ├── notification_service.dart       # Push notifications
│   │   ├── pharmacy_service.dart  # Pharmacy operations
│   │   ├── rbac_service.dart      # Role-based access control
│   │   ├── route_guard_service.dart        # Navigation security
│   │   ├── security_audit_service.dart     # Security logging
│   │   ├── sync_service.dart      # Data synchronization
│   │   └── webrtc_service.dart    # Video calling service
```

#### Navigation & Routing
```
│   ├── routes/
│   │   ├── app_navigator.dart     # Navigation helper
│   │   └── app_routes.dart        # Route definitions
```

#### Theme & Styling
```
│   ├── theme/
│   │   └── app_theme.dart         # Material Design 3 themes
```

#### Reusable Widgets
```
│   └── widgets/
│       ├── custom_error_widget.dart
│       ├── custom_icon_widget.dart
│       ├── custom_image_widget.dart
│       ├── optimized_image.dart
│       ├── optimized_list.dart
│       ├── performance_monitor.dart
│       └── protected_route.dart
```

### 🧪 Testing
```
├── test/
│   ├── database_test.dart         # Database unit tests
│   ├── integration/
│   │   ├── app_integration_test.dart
│   │   └── complete_app_test.dart
│   └── presentation/               # Widget tests
│       ├── add_patient_screen_test.dart
│       ├── error_offline_screen_test.dart
│       ├── help_support_screen_test.dart
│       └── teleconference_call_screen_test.dart
```

### 🔧 Scripts & Utilities
```
├── scripts/
│   ├── fix_imports.dart           # Import fixing utility
│   └── validate_implementation.dart # Implementation validator
```

### 📦 Configuration Files
```
├── .flutter-plugins-dependencies  # Flutter plugin dependencies
├── .gitignore                     # Git ignore rules
├── analysis_options.yaml          # Dart analyzer configuration
├── cleanupproject.bat            # Windows cleanup script
├── env.json                      # Environment variables
├── pubspec.yaml                  # Package dependencies
├── pubspec.lock                  # Locked dependencies
├── README.md                     # Project documentation
└── Tasks_2025-09-03T16-40-32.md # Task tracking
```

## 📊 Statistics

### File Count by Type
- **Dart Files (.dart)**: 150+
- **YAML Files (.yaml)**: 3
- **JSON Files (.json)**: 5
- **Markdown Files (.md)**: 6
- **XML Files (.xml)**: 10
- **Gradle Files (.gradle)**: 3
- **HTML/JS/CSS**: 5
- **Swift/Kotlin/Java**: 3

### Code Organization
- **Screens**: 40+ complete UI screens
- **Services**: 12 business logic services
- **Models**: 13 data models
- **DAOs**: 19 data access objects
- **Custom Widgets**: 30+ reusable components
- **Tests**: Unit, widget, and integration tests

## 🏗️ Architecture Pattern

### Layer Structure
```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, Controllers)        │
├─────────────────────────────────────────┤
│         Business Logic Layer            │
│    (Services, State Management)         │
├─────────────────────────────────────────┤
│          Data Access Layer              │
│      (DAOs, Models, Database)           │
├─────────────────────────────────────────┤
│         Infrastructure Layer            │
│   (SQLite, Network, File System)        │
└─────────────────────────────────────────┘
```

## 🔑 Key Dependencies

### Core Flutter Packages
- `flutter`: UI framework
- `sizer`: ^2.0.15 - Responsive design
- `flutter_svg`: ^2.0.9 - SVG support
- `google_fonts`: ^6.1.0 - Typography
- `shared_preferences`: ^2.2.2 - Local storage

### Backend & Database
- `supabase_flutter`: ^2.0.0 - Backend services
- `sqflite`: ^2.3.0 - SQLite database
- `flutter_dotenv`: ^5.1.0 - Environment variables
- `provider`: ^6.1.1 - State management

### UI & UX
- `cached_network_image`: ^3.3.1 - Image caching
- `fluttertoast`: ^8.2.4 - Toast messages
- `fl_chart`: ^0.65.0 - Charts and graphs
- `flutter_slidable`: ^4.0.1 - Swipeable list items

### Communication
- `flutter_webrtc`: ^0.9.48 - Video calling
- `record`: ^6.0.0 - Audio recording
- `permission_handler`: ^11.1.0 - Permissions

### Payments & Security
- `flutter_stripe`: ^12.0.2 - Stripe payments
- `local_auth`: ^2.1.6 - Biometric auth
- `flutter_secure_storage`: ^9.0.0 - Secure storage
- `crypto`: ^3.0.3 - Cryptography

### Maps & Location
- `google_maps_flutter`: ^2.12.3 - Maps integration

### Media & Files
- `camera`: ^0.10.5+5 - Camera access
- `image_picker`: ^1.0.4 - Image selection
- `file_picker`: ^8.1.7 - File selection
- `path_provider`: ^2.1.2 - File paths

### Utilities
- `connectivity_plus`: ^5.0.2 - Network status
- `dio`: ^5.4.0 - HTTP client
- `uuid`: ^4.2.1 - UUID generation
- `intl`: ^0.19.0 - Internationalization
- `mobile_scanner`: ^7.0.0-beta.8 - QR/barcode scanning

## 🚀 Entry Points

### Main Application
- **Entry**: `lib/main.dart`
- **Initial Route**: Splash Screen → Login/Dashboard
- **Route Configuration**: `lib/routes/app_routes.dart`

### Key Services Initialization
1. Database: `DatabaseHelper.instance`
2. Authentication: `AuthService.instance`
3. Synchronization: `SyncService.instance`
4. Performance: `PerformanceService.instance`

## 📝 Notes

- **Architecture**: Offline-first with automatic cloud sync
- **State Management**: Provider pattern
- **Database**: SQLite with Supabase backend
- **Security**: HIPAA-compliant with encryption
- **Performance**: Optimized for mobile and web
- **Testing**: Comprehensive test coverage
- **Documentation**: Extensive inline and external docs

---

Generated on: 2025-09-13
Flutter Version: 3.6.0+
Platform: Windows (D:\projects\medrefer_ai)