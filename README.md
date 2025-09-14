# MedRefer AI 🏥

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com)

A comprehensive Flutter application for medical referral management with AI-powered recommendations, featuring offline-first architecture, M-Pesa payments, pharmacy integration, and HIPAA-compliant security.

## 🎉 Implementation Status: COMPLETE ✅

All major features and screens have been successfully implemented with comprehensive testing, documentation, and production-ready code.

## 🌟 Key Features

### 🏥 Core Medical Features
- **Patient Management**: Complete patient registration, search, and profile management
- **AI-Powered Referrals**: Multi-step referral process with intelligent specialist recommendations
- **Specialist Directory**: Comprehensive specialist profiles with ratings and availability
- **Appointment Scheduling**: Calendar-based appointment booking with conflict detection
- **Medical History**: Detailed patient medical history, conditions, and medications tracking
- **Document Management**: Secure document upload, viewing, and sharing with encryption
- **Lab Results**: Integration with laboratory systems for result viewing and sharing
- **Prescription Management**: Digital prescription creation, tracking, and pharmacy integration

### 💊 Pharmacy & Payments
- **Integrated Pharmacy**: Complete pharmacy system with drug inventory and ordering
- **M-Pesa Integration**: Secure mobile money payments for consultations and medications
- **Shopping Cart**: Multi-item pharmacy orders with quantity management
- **Payment Processing**: Support for multiple payment methods including mobile money
- **Billing System**: Comprehensive billing and payment history tracking
- **Insurance Verification**: Real-time insurance coverage verification

### 💬 Communication & Collaboration
- **Secure Messaging**: HIPAA-compliant messaging between healthcare providers
- **Video Conferencing**: Full-featured WebRTC teleconference system for consultations
- **Real-time Notifications**: Push notifications for referral updates and appointments
- **Chat Integration**: In-call messaging during video conferences
- **File Sharing**: Secure document and image sharing within conversations

### 🔐 Security & Compliance
- **Role-Based Access Control (RBAC)**: Granular permissions for different user types
- **Biometric Authentication**: Secure login with fingerprint/face recognition
- **Data Encryption**: End-to-end encryption for sensitive medical data
- **HIPAA Compliance**: Full compliance with healthcare data protection regulations
- **Security Auditing**: Comprehensive audit trails and security monitoring
- **Document Security**: Encrypted document storage and secure sharing

### 🔧 Technical Excellence
- **Offline-First Architecture**: Full functionality without internet connection
- **SQLite Database**: Local data storage with automatic cloud synchronization
- **Performance Optimizations**: Optimized images, lists, and animations
- **Error Handling**: Comprehensive error handling and graceful recovery
- **Real-time Sync**: Automatic data synchronization when connection is restored
- **Performance Monitoring**: Real-time performance tracking and optimization

### 📱 User Experience
- **Material Design 3**: Modern, accessible UI design with dynamic theming
- **Dark/Light Themes**: Automatic theme switching based on system preferences
- **Responsive Design**: Optimized for all screen sizes from phones to tablets
- **Accessibility**: Full screen reader support and high contrast modes
- **Internationalization**: Multi-language support with localization
- **Smooth Animations**: Fluid transitions and micro-interactions

## 🏗️ Architecture Overview

MedRefer AI follows a clean, scalable architecture with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Services     │    │    Database     │
│                 │    │                 │    │                 │
│ • Screens       │◄──►│ • Auth Service  │◄──►│ • SQLite        │
│ • Widgets       │    │ • Data Service  │    │ • Models        │
│ • Controllers   │    │ • Sync Service  │    │ • DAOs          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

### System Requirements
- **Flutter SDK**: ^3.6.0
- **Dart SDK**: ^3.6.0
- **Android Studio** / **VS Code** with Flutter extensions
- **Android SDK** (API level 21+) / **Xcode** (iOS 12.0+)
- **Git** for version control

### Development Environment
- **Minimum RAM**: 8GB (16GB recommended)
- **Storage**: 10GB free space
- **Network**: Internet connection for initial setup and sync

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/medrefer_ai.git
cd medrefer_ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Environment Setup
Create a `.env` file in the project root:
```env
# Database Configuration
DATABASE_URL=your_database_url

# M-Pesa Configuration (Sandbox)
MPESA_CONSUMER_KEY=your_mpesa_consumer_key
MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
MPESA_SHORTCODE=174379
MPESA_PASSKEY=your_mpesa_passkey

# Supabase Configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 4. Run the Application
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific device
flutter run -d <device_id>
```

## 📁 Project Structure

```
medrefer_ai/
├── android/                    # Android-specific configuration
├── ios/                        # iOS-specific configuration
├── assets/                     # Static assets (images, designs)
│   ├── images/                 # App images and icons
│   └── designs/                # Figma design files
├── docs/                       # Comprehensive documentation
│   ├── API_DOCUMENTATION.md    # API endpoints and usage
│   ├── DATABASE_SCHEMA.md      # Database structure
│   ├── DEPLOYMENT_GUIDE.md     # Deployment instructions
│   └── SCREENS_DOCUMENTATION.md # Screen-by-screen documentation
├── lib/
│   ├── config/                 # Configuration files
│   │   └── mpesa_config.dart   # M-Pesa payment configuration
│   ├── core/                   # Core utilities and services
│   │   ├── app_export.dart     # Central exports
│   │   ├── performance/        # Performance optimization
│   │   ├── realtime/           # Real-time data services
│   │   └── search/             # Search functionality
│   ├── database/               # Data layer
│   │   ├── dao/                # Data Access Objects
│   │   ├── models/             # Data models
│   │   ├── services/           # Database services
│   │   ├── database.dart       # Database exports
│   │   └── database_helper.dart # SQLite helper
│   ├── presentation/           # UI layer (40+ screens)
│   │   ├── add_patient_screen/
│   │   ├── admin_dashboard/
│   │   ├── appointment_scheduling_screen/
│   │   ├── billing_payment/
│   │   ├── biometrics_screen/
│   │   ├── cart_screen/
│   │   ├── chat_screen/
│   │   ├── create_referral_screen/
│   │   ├── dashboard/
│   │   ├── login_screen/
│   │   ├── mpesa_payment_screen/
│   │   ├── pharmacy_screen/
│   │   ├── teleconference_call_screen/
│   │   └── ... (30+ more screens)
│   ├── routes/                 # Navigation and routing
│   │   └── app_routes.dart     # Route definitions
│   ├── services/               # Business logic services
│   │   ├── auth_service.dart   # Authentication
│   │   ├── biometric_service.dart # Biometric auth
│   │   ├── mpesa_service.dart  # M-Pesa payments
│   │   ├── pharmacy_service.dart # Pharmacy operations
│   │   ├── rbac_service.dart   # Role-based access control
│   │   ├── sync_service.dart   # Data synchronization
│   │   ├── webrtc_service.dart # Video calling
│   │   └── ... (12 services total)
│   ├── theme/                  # UI theming
│   │   └── app_theme.dart      # Light/dark themes
│   ├── widgets/                # Reusable UI components
│   │   ├── custom_error_widget.dart
│   │   ├── optimized_image.dart
│   │   ├── performance_monitor.dart
│   │   └── protected_route.dart
│   └── main.dart               # Application entry point
├── test/                       # Test files
│   ├── database_test.dart      # Database tests
│   ├── integration/            # Integration tests
│   └── presentation/           # Widget tests
├── pubspec.yaml                # Dependencies and configuration
└── README.md                   # This file
```

## 🖥️ Implemented Screens (40+)

### Authentication & Onboarding
- **Splash Screen**: App initialization and loading
- **Onboarding Screen**: Feature introduction for new users
- **Login Screen**: Secure authentication with biometrics
- **Registration Screen**: New user account creation
- **Forgot Password Screen**: Password recovery flow
- **Biometrics Screen**: Fingerprint/face ID setup

### Patient Management
- **Patient Search Screen**: Advanced patient search and filtering
- **Add Patient Screen**: Comprehensive patient registration
- **Patient Profile Screen**: Detailed patient information view
- **Patient Profile Edit**: Patient information modification

### Medical Operations
- **Dashboard**: Role-based dashboard with analytics
- **Create Referral Screen**: AI-powered referral creation
- **Referral Tracking**: Real-time referral status monitoring
- **Appointment Scheduling**: Calendar-based appointment booking
- **Appointment History**: Past and upcoming appointments
- **Medical History**: Patient medical records management
- **Lab Results**: Laboratory test results viewing
- **Prescription Management**: Digital prescription handling

### Specialist Services
- **Specialist Directory**: Browse and search specialists
- **Specialist Profile Screen**: Detailed specialist information
- **Specialist Selection**: AI-recommended specialist matching
- **Doctor Detail Screen**: Comprehensive doctor profiles

### Communication
- **Secure Messaging**: HIPAA-compliant messaging system
- **Chat Screen**: Real-time conversation interface
- **Teleconference Call Screen**: Full-featured video calling
- **Notifications Screen**: System and user notifications

### Pharmacy & Payments
- **Pharmacy Screen**: Browse medications and health products
- **Drug Detail Screen**: Detailed medication information
- **Cart Screen**: Shopping cart for pharmacy orders
- **Payment Screen**: Multiple payment method support
- **M-Pesa Payment Screen**: Mobile money integration
- **Billing Payment**: Invoice and payment management

### Administrative
- **Admin Dashboard**: System administration interface
- **Settings Screen**: User preferences and configuration
- **Profile Edit**: User profile management
- **Help Support Screen**: Customer support and FAQ
- **Health Analytics**: Health metrics and reporting
- **Insurance Verification**: Insurance coverage verification
- **Document Viewer Screen**: Secure document viewing
- **Feedback Rating**: User feedback and rating system

### System Screens
- **Error/Offline Screen**: Graceful error handling
- **Logout Confirmation**: Secure logout process

## 🔧 Core Services

### Authentication & Security
- **AuthService**: Secure user authentication with JWT tokens
- **BiometricService**: Fingerprint and face ID authentication
- **RBACService**: Role-based access control and permissions
- **SecurityAuditService**: Security monitoring and audit trails
- **DocumentSecurityService**: Encrypted document handling

### Data Management
- **DataService**: Centralized data operations and caching
- **SyncService**: Offline-first data synchronization
- **ErrorHandlingService**: Comprehensive error handling and recovery

### Communication & Integration
- **WebRTCService**: Video calling and real-time communication
- **NotificationService**: Push notifications and alerts
- **MpesaService**: Mobile money payment integration
- **PharmacyService**: Pharmacy operations and inventory

### Performance & Monitoring
- **PerformanceService**: App performance monitoring and optimization
- **RouteGuardService**: Navigation security and access control

## 🎨 Theming & Design

### Material Design 3
The app implements Google's latest Material Design 3 principles with:
- **Dynamic Color**: Adaptive color schemes based on user preferences
- **Typography**: Comprehensive type scale with custom Google Fonts
- **Components**: Modern Material 3 components and interactions
- **Accessibility**: Full WCAG 2.1 AA compliance

### Theme Configuration
```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
Color surfaceColor = theme.colorScheme.surface;

// Custom theme extensions
CustomColors customColors = theme.extension<CustomColors>()!;
```

### Responsive Design
Built with the Sizer package for consistent responsive behavior:

```dart
// Responsive sizing examples
Container(
  width: 90.w,          // 90% of screen width
  height: 25.h,         // 25% of screen height
  padding: EdgeInsets.symmetric(
    horizontal: 4.w,    // 4% of screen width
    vertical: 2.h,      // 2% of screen height
  ),
  child: Text(
    'Responsive Text',
    style: TextStyle(fontSize: 16.sp), // Responsive font size
  ),
)
```
## 🗄️ Database Schema

### Core Models
- **User**: Authentication and user management
- **Patient**: Patient information and medical records
- **Specialist**: Healthcare provider profiles
- **Referral**: Medical referrals and tracking
- **Message**: Secure messaging system
- **MedicalHistory**: Patient medical history
- **Medication**: Prescription and medication tracking
- **Document**: Secure document storage
- **PharmacyDrug**: Pharmacy inventory management
- **VitalStatistics**: Patient vital signs and measurements

### Relationships
```sql
Patient (1) ←→ (N) MedicalHistory
Patient (1) ←→ (N) Referral
Specialist (1) ←→ (N) Referral
User (1) ←→ (N) Message
Patient (1) ←→ (N) Document
```

## 🔐 Security Features

### Data Protection
- **End-to-End Encryption**: All sensitive data encrypted at rest and in transit
- **HIPAA Compliance**: Full compliance with healthcare data protection regulations
- **Secure Storage**: Flutter Secure Storage for sensitive information
- **Biometric Authentication**: Fingerprint and face ID support

### Access Control
- **Role-Based Permissions**: Granular access control for different user types
- **Route Protection**: Secured navigation based on user roles
- **Session Management**: Secure session handling with automatic timeout
- **Audit Trails**: Comprehensive logging of all user actions

## 💳 Payment Integration

### M-Pesa Mobile Money
- **STK Push**: Seamless mobile money payments
- **Transaction Tracking**: Real-time payment status monitoring
- **Error Handling**: Comprehensive error handling for failed transactions
- **Receipt Generation**: Automatic receipt generation and storage

### Configuration
```dart
// M-Pesa configuration in lib/config/mpesa_config.dart
class MpesaConfig {
  static const bool isProduction = false;
  static String get consumerKey => isProduction ? productionKey : sandboxKey;
  // ... additional configuration
}
```

## 🧪 Testing

### Test Coverage
- **Unit Tests**: Service layer and business logic testing
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end user flow testing
- **Database Tests**: Data layer testing with SQLite

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/auth_service_test.dart

# Run integration tests
flutter test integration_test/

# Generate coverage report
flutter test --coverage
```

## 📦 Build & Deployment

### Development Build
```bash
# Debug build
flutter run

# Profile build (performance testing)
flutter run --profile
```

### Production Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Environment Configuration
Create environment-specific configuration files:
```bash
# Development
.env.development

# Staging
.env.staging

# Production
.env.production
```

## 🚀 Performance Optimizations

### Implemented Optimizations
- **Image Optimization**: Cached network images with automatic resizing
- **List Virtualization**: Efficient scrolling for large datasets
- **Memory Management**: Proper disposal of controllers and streams
- **Database Indexing**: Optimized database queries with proper indexing
- **Code Splitting**: Lazy loading of screens and features

### Performance Monitoring
```dart
// Performance monitoring in debug mode
PerformanceService.startMonitoring();
PerformanceService.trackScreenLoad('PatientListScreen');
PerformanceService.trackUserAction('create_referral');
```

## 📚 Documentation

### Available Documentation
- **[API Documentation](docs/API_DOCUMENTATION.md)**: Complete API reference
- **[Database Schema](docs/DATABASE_SCHEMA.md)**: Database structure and relationships
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)**: Step-by-step deployment instructions
- **[Screens Documentation](docs/SCREENS_DOCUMENTATION.md)**: Detailed screen documentation

### Code Documentation
All code is thoroughly documented with:
- **Inline Comments**: Explaining complex logic
- **Method Documentation**: Comprehensive method descriptions
- **Class Documentation**: Purpose and usage of each class
- **README Files**: Module-specific documentation

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write comprehensive tests for new features
- Update documentation for any changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### Technologies Used
- **[Flutter](https://flutter.dev)** - UI framework
- **[Dart](https://dart.dev)** - Programming language
- **[SQLite](https://sqlite.org)** - Local database
- **[Supabase](https://supabase.com)** - Backend services
- **[WebRTC](https://webrtc.org)** - Video calling
- **[M-Pesa API](https://developer.safaricom.co.ke)** - Mobile payments

### Design & Assets
- **Material Design 3** - Design system
- **Google Fonts** - Typography
- **Figma** - Design files and prototypes

### Special Thanks
- Healthcare professionals who provided domain expertise
- Beta testers who helped improve the user experience
- Open source community for the amazing packages and tools

---

**Built with ❤️ for healthcare professionals worldwide**

For support, please contact: [support@medrefer.ai](mailto:support@medrefer.ai)
#   m e d r e f e r - a i  
 