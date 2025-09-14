# MedRefer AI - Deployment Guide

## 📋 Prerequisites

### Development Environment
- **Flutter SDK**: 3.6.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio**: Latest version with Flutter plugin
- **VS Code**: With Flutter and Dart extensions (optional)
- **Git**: For version control

### Platform Requirements
- **Android**: API level 21 (Android 5.0) or higher
- **iOS**: iOS 12.0 or higher
- **Web**: Modern browsers with WebAssembly support

## 🚀 Build and Deployment

### 1. Environment Setup

```bash
# Clone the repository
git clone <repository-url>
cd medrefer_ai

# Install dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 2. Configuration

#### Environment Variables
Create `.env` files for different environments:

```bash
# .env.development
API_BASE_URL=https://dev-api.medrefer.com
DATABASE_URL=sqlite://dev.db
ENABLE_LOGGING=true
ENABLE_ANALYTICS=false

# .env.production
API_BASE_URL=https://api.medrefer.com
DATABASE_URL=sqlite://prod.db
ENABLE_LOGGING=false
ENABLE_ANALYTICS=true
```

#### Firebase Configuration (if using)
1. Add `google-services.json` for Android
2. Add `GoogleService-Info.plist` for iOS
3. Configure Firebase project settings

### 3. Build Commands

#### Development Build
```bash
# Debug build for testing
flutter run --debug

# Profile build for performance testing
flutter run --profile
```

#### Production Build

##### Android
```bash
# Generate signed APK
flutter build apk --release

# Generate signed App Bundle (recommended for Play Store)
flutter build appbundle --release

# Install on device
flutter install --release
```

##### iOS
```bash
# Build for iOS
flutter build ios --release

# Archive for App Store (requires Xcode)
# Open ios/Runner.xcworkspace in Xcode
# Product > Archive
```

##### Web
```bash
# Build for web
flutter build web --release

# Deploy to web server
# Copy build/web/* to your web server
```

### 4. Code Signing

#### Android
1. Generate keystore:
```bash
keytool -genkey -v -keystore ~/medrefer-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias medrefer
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=medrefer
storeFile=<path-to-keystore>
```

#### iOS
1. Configure signing in Xcode
2. Set up provisioning profiles
3. Configure App Store Connect

## 🔧 Configuration Management

### Database Configuration
- **Development**: SQLite local database
- **Production**: SQLite with cloud backup
- **Migration**: Automatic schema migrations

### API Configuration
- **Base URL**: Configurable per environment
- **Authentication**: JWT tokens with refresh
- **Rate Limiting**: Implemented on server side

### Security Configuration
- **HTTPS**: Enforced in production
- **Certificate Pinning**: Enabled for API calls
- **Data Encryption**: AES-256 for sensitive data
- **Biometric Auth**: Available on supported devices

## 📱 Platform-Specific Deployment

### Android Play Store
1. **Prepare Release**:
   - Update version in `pubspec.yaml`
   - Generate signed App Bundle
   - Test on multiple devices

2. **Play Console Setup**:
   - Create app listing
   - Upload App Bundle
   - Configure store listing
   - Set up pricing and distribution

3. **Review Process**:
   - Submit for review
   - Address any policy violations
   - Monitor crash reports

### iOS App Store
1. **Prepare Release**:
   - Update version in `pubspec.yaml`
   - Archive in Xcode
   - Test on multiple devices

2. **App Store Connect**:
   - Create app record
   - Upload build
   - Configure app information
   - Submit for review

3. **Review Process**:
   - Follow App Store guidelines
   - Address reviewer feedback
   - Monitor TestFlight feedback

### Web Deployment
1. **Build Optimization**:
   - Enable web optimizations
   - Configure PWA settings
   - Optimize bundle size

2. **Server Configuration**:
   - Configure HTTPS
   - Set up CDN
   - Configure caching headers

3. **Domain Setup**:
   - Configure DNS
   - Set up SSL certificates
   - Configure redirects

## 🔍 Testing and Quality Assurance

### Pre-Deployment Checklist
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] UI tests pass
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] Accessibility compliance verified
- [ ] HIPAA compliance verified

### Testing Commands
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Run performance tests
flutter test --profile

# Generate test coverage
flutter test --coverage
```

### Quality Gates
- **Code Coverage**: Minimum 80%
- **Performance**: App startup < 3 seconds
- **Memory Usage**: < 100MB average
- **Crash Rate**: < 0.1%

## 📊 Monitoring and Analytics

### Performance Monitoring
- **Firebase Performance**: App performance metrics
- **Crashlytics**: Crash reporting and analysis
- **Custom Metrics**: Healthcare-specific KPIs

### Analytics Setup
- **User Analytics**: User behavior tracking
- **Medical Analytics**: Referral success rates
- **Performance Analytics**: App performance metrics

### Logging Configuration
```dart
// Production logging configuration
Logger.root.level = Level.WARNING;
Logger.root.onRecord.listen((record) {
  // Send to logging service
});
```

## 🔐 Security Considerations

### Data Protection
- **Encryption at Rest**: SQLite database encryption
- **Encryption in Transit**: TLS 1.3 for all communications
- **Key Management**: Secure key storage
- **Data Anonymization**: PII protection

### HIPAA Compliance
- **Access Controls**: Role-based permissions
- **Audit Logging**: All data access logged
- **Data Backup**: Encrypted backups
- **Incident Response**: Security incident procedures

### Security Testing
- **Penetration Testing**: Regular security audits
- **Vulnerability Scanning**: Automated security scans
- **Code Analysis**: Static security analysis

## 🚨 Troubleshooting

### Common Issues
1. **Build Failures**:
   - Clean build: `flutter clean && flutter pub get`
   - Check Flutter version compatibility
   - Verify platform-specific configurations

2. **Performance Issues**:
   - Profile app performance
   - Check memory leaks
   - Optimize image loading

3. **Deployment Issues**:
   - Verify signing certificates
   - Check platform requirements
   - Review store policies

### Support Contacts
- **Development Team**: dev@medrefer.com
- **DevOps Team**: devops@medrefer.com
- **Security Team**: security@medrefer.com

## 📈 Post-Deployment

### Monitoring
- Set up alerts for crashes and errors
- Monitor app performance metrics
- Track user engagement metrics

### Updates
- Plan regular update cycles
- Monitor user feedback
- Address security vulnerabilities promptly

### Maintenance
- Regular database maintenance
- Performance optimization
- Security updates

---

**Last Updated**: December 2024
**Version**: 1.0.0
**Maintainer**: MedRefer AI Development Team
