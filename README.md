# MedRefer AI 🏥

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](https://github.com)

> A comprehensive Flutter application for **medical referral management** with **AI-powered recommendations**, featuring offline-first architecture, M-Pesa payments, pharmacy integration, and HIPAA-compliance.

---

## 🎉 Implementation Status

- ✅ **All major features implemented**  
- ✅ **Comprehensive testing completed**  
- ✅ **Production-ready codebase**

---

## 🌟 Key Features

### 🏥 Core Medical

- Patient registration, search, and profiles  
- AI-powered multi-step referrals with smart specialist recommendations  
- Specialist directory with availability and ratings  
- Calendar-based appointment scheduling with conflict detection  
- Detailed patient medical history and medication tracking  
- Secure document management with encryption  
- Lab results integration and sharing  
- Digital prescriptions with pharmacy integration  

### 💊 Pharmacy & Payments

- Full pharmacy inventory and ordering system  
- Secure M-Pesa integration for payments  
- Shopping cart with multi-item checkout  
- Billing and payment history  
- Insurance verification in real time  

### 💬 Communication

- HIPAA-compliant secure messaging  
- WebRTC-based video conferencing  
- Push notifications for updates  
- In-call chat and secure file sharing  

### 🔐 Security & Compliance

- Role-Based Access Control (RBAC)  
- Biometric login (fingerprint/face ID)  
- End-to-end encryption for medical data  
- HIPAA compliance across all workflows  
- Comprehensive auditing and monitoring  

### 🔧 Technical Excellence

- Offline-first architecture with SQLite sync  
- Performance optimizations for images, lists, and animations  
- Error handling with graceful recovery  
- Real-time data sync and performance monitoring  

### 📱 User Experience

- Material Design 3 with modern UI  
- Light/dark themes with system auto-switching  
- Responsive design for mobile and tablet  
- Accessibility with screen reader and high-contrast support  
- Internationalization with multi-language support  

---

## 🏗️ Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Services     │    │    Database     │
│ • Screens       │◄──►│ • Auth Service  │◄──►│ • SQLite        │
│ • Widgets       │    │ • Data Service  │    │ • Models        │
│ • Controllers   │    │ • Sync Service  │    │ • DAOs          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 📋 Prerequisites

| Requirement                 | Version/Notes                |
|-----------------------------|------------------------------|
| Flutter SDK                 | ^3.6.0                       |
| Dart SDK                    | ^3.6.0                       |
| Android Studio / VS Code    | Flutter plugins recommended  |
| Android SDK                 | 21+                          |
| Xcode iOS                   | 12+                          |
| Git                         |                              |

**Development Environment**

- RAM: 8GB minimum (16GB recommended)
- Storage: 10GB free space
- Network: Stable internet for sync

---

## 🚀 Quick Start

1. **Clone repository**
   ```bash
   git clone https://github.com/your-username/medrefer_ai.git
   cd medrefer_ai
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment**

   Create a `.env` file in project root:
   ```
   DATABASE_URL=your_database_url
   MPESA_CONSUMER_KEY=your_mpesa_consumer_key
   MPESA_CONSUMER_SECRET=your_mpesa_consumer_secret
   MPESA_SHORTCODE=174379
   MPESA_PASSKEY=your_mpesa_passkey
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

<details>
<summary>Click to expand</summary>

```text
medrefer_ai/
├── android/          # Android config
├── ios/              # iOS config
├── assets/           # Static assets
├── docs/             # Documentation
├── lib/              # Source code
│   ├── config/       # App configs
│   ├── core/         # Core utilities
│   ├── database/     # Data layer
│   ├── presentation/ # UI layer
│   ├── routes/       # Navigation
│   ├── services/     # Business logic
│   ├── theme/        # Theming
│   ├── widgets/      # Reusable widgets
│   └── main.dart     # Entry point
└── test/             # Tests
```
</details>

---

## 🖥️ Implemented Screens

- Authentication & onboarding (Login, Registration, Biometrics, Forgot Password)
- Patient management (Add patient, Profile, Search)
- Medical operations (Dashboard, Referral, Appointment scheduling)
- Specialist services (Directory, Profiles, AI recommendations)
- Communication (Chat, Notifications, Teleconference)
- Pharmacy & payments (Cart, Payment, Billing)
- Administrative (Admin dashboard, Insurance verification, Reports)
- System (Error handling, Logout confirmation)

---

## 🔧 Core Services

- **AuthService**: JWT authentication
- **BiometricService**: Fingerprint & Face ID
- **RBACService**: Role-based access control
- **SecurityAuditService**: Auditing and logs
- **DocumentSecurityService**: Encrypted documents
- **WebRTCService**: Video conferencing
- **NotificationService**: Push alerts
- **MpesaService**: Mobile money payments
- **PerformanceService**: Real-time app monitoring

---

## 🎨 Theming & Design

- Material Design 3 principles
- Dynamic color and Google Fonts
- WCAG 2.1 AA accessibility compliance
- Responsive sizing with Sizer package

---

## 🗄️ Database Schema

- **User** – Authentication and roles
- **Patient** – Patient information
- **Specialist** – Healthcare providers
- **Referral** – Referral records
- **MedicalHistory** – Conditions, treatments
- **Message** – Secure communications
- **Document** – Encrypted storage
- **PharmacyDrug** – Inventory

---

## 🔐 Security Features

- End-to-end encryption
- Biometric authentication
- Role-based permissions
- Route protection and session management
- Audit trails with full logging

---

## 💳 Payment Integration

- M-Pesa STK push
- Real-time transaction tracking
- Error handling and receipts

---

## 🧪 Testing

- Unit, widget, integration, and database tests
- Coverage reporting with `flutter test --coverage`

---

## 📦 Build & Deployment

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Play Store
flutter build ios --release        # iOS
flutter build web --release        # Web
```

---

## 📚 Documentation

- API Docs
- Development Guide
- User Guide
- Security & Compliance
- Audit Summary

---

## 🤝 Contributing

1. Fork repo
2. Create feature branch
3. Commit changes
4. Push branch
5. Open PR

---

## 📄 License

MIT License - see [LICENSE](LICENSE).

---

## 🙏 Acknowledgments

- Flutter, Dart, SQLite, Supabase, WebRTC, M-Pesa API
- Material Design 3, Google Fonts, Figma
- Healthcare professionals & beta testers

Built with ❤️ for healthcare professionals worldwide.

**📧 Support:** [support@medrefer.ai](mailto:support@medrefer.ai)
