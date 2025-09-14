# MedRefer AI - Screens Documentation

This document provides comprehensive documentation for all screens implemented in the MedRefer AI Flutter application.

## Table of Contents

1. [Add Patient Screen](#add-patient-screen)
2. [Teleconference Call Screen](#teleconference-call-screen)
3. [Error/Offline Screen](#erroroffline-screen)
4. [Help/Support Screen](#helpsupport-screen)
5. [Existing Screens](#existing-screens)

## Add Patient Screen

### Overview
The Add Patient Screen allows healthcare providers to register new patients in the system with comprehensive information collection.

### Features
- **Multi-step Form**: Three-tab interface (Basic Info, Contact, Medical)
- **Form Validation**: Real-time validation for required fields
- **Date Selection**: Interactive date picker for date of birth
- **Dropdown Selections**: Gender, blood type, marital status, relationship options
- **Medical History**: Capture allergies, medications, and medical history
- **Emergency Contact**: Required emergency contact information

### Navigation
- Route: `/add-patient`
- Access: From Patient Search Screen → "Add New Patient" button
- Returns: Patient object on successful creation

### Key Components
```dart
class AddPatientScreen extends StatefulWidget {
  // Multi-tab form with validation
  // Integrates with DataService for patient creation
  // Handles medical history creation
}
```

### Usage Example
```dart
Navigator.pushNamed(
  context,
  AppRoutes.addPatientScreen,
);
```

### Testing
- Unit tests: `test/presentation/add_patient_screen_test.dart`
- Covers form validation, navigation, data submission, error handling

## Teleconference Call Screen

### Overview
Full-featured video conferencing interface for medical consultations with specialists.

### Features
- **Video Grid**: Dynamic participant video feeds
- **Call Controls**: Mute, video toggle, speaker, screen share
- **Participants Panel**: List of call participants with status indicators
- **In-Call Chat**: Real-time messaging during calls
- **Call Duration**: Live call timer with recording indicator
- **Full Screen Mode**: Immersive call experience

### Navigation
- Route: `/teleconference-call`
- Parameters: `callId`, `participantIds`, `isVideoCall`
- Access: From specialist profiles, referral details, or scheduled appointments

### Key Components
```dart
class TeleconferenceCallScreen extends StatefulWidget {
  final String callId;
  final List<String> participantIds;
  final bool isVideoCall;
  
  // Manages call state, participant management
  // Handles audio/video controls
  // Provides in-call messaging
}
```

### Usage Example
```dart
Navigator.pushNamed(
  context,
  AppRoutes.teleconferenceCallScreen,
  arguments: {
    'callId': 'call-123',
    'participantIds': ['user1', 'user2'],
    'isVideoCall': true,
  },
);
```

### Testing
- Unit tests: `test/presentation/teleconference_call_screen_test.dart`
- Covers UI controls, participant management, call state handling

## Error/Offline Screen

### Overview
Comprehensive error handling and offline mode support with graceful degradation.

### Features
- **Dual Mode**: Error state and offline state handling
- **Animated UI**: Pulse animations and slide transitions
- **Queued Actions**: Display and manage offline actions
- **Retry Mechanism**: Smart retry with connectivity checking
- **Help Integration**: Direct access to support and help resources
- **Action Queue**: View pending actions waiting for sync

### Navigation
- Route: `/error-offline`
- Parameters: `errorMessage`, `errorType`, `isOffline`, `onRetry`
- Access: Automatic navigation on errors or network issues

### Key Components
```dart
class ErrorOfflineScreen extends StatefulWidget {
  final String? errorMessage;
  final String? errorType;
  final bool isOffline;
  final VoidCallback? onRetry;
  
  // Handles error display and retry logic
  // Manages queued actions for offline mode
  // Provides help and support access
}
```

### Usage Example
```dart
Navigator.pushNamed(
  context,
  AppRoutes.errorOfflineScreen,
  arguments: {
    'isOffline': true,
    'onRetry': () => _retryConnection(),
  },
);
```

### Testing
- Unit tests: `test/presentation/error_offline_screen_test.dart`
- Covers error states, offline handling, retry mechanisms

## Help/Support Screen

### Overview
Comprehensive help and support system with FAQ, tutorials, contact options, and feedback collection.

### Features
- **FAQ System**: Searchable and categorized frequently asked questions
- **Video Tutorials**: Interactive tutorial library with duration indicators
- **Multiple Contact Options**: Live chat, email, phone, ticket system
- **Feedback Collection**: User feedback form with quick action buttons
- **App Information**: Version details and support ID generation

### Navigation
- Route: `/help-support`
- Access: From settings, profile, or error screens
- Four main tabs: FAQ, Tutorials, Contact, Feedback

### Key Components
```dart
class HelpSupportScreen extends StatefulWidget {
  // Four-tab interface for comprehensive support
  // FAQ search and filtering
  // Contact method integration
  // Feedback submission system
}
```

### Usage Example
```dart
Navigator.pushNamed(
  context,
  AppRoutes.helpSupportScreen,
);
```

### Testing
- Unit tests: `test/presentation/help_support_screen_test.dart`
- Covers all tabs, search functionality, contact methods, feedback submission

## Existing Screens

### Core Screens
- **Splash Screen**: App initialization with database setup
- **Login Screen**: Authentication with biometric support
- **Dashboard**: Main hub with statistics and quick actions
- **Patient Search**: Advanced patient search and filtering
- **Create Referral**: Multi-step referral creation process
- **Referral Tracking**: Comprehensive referral management
- **Chat Screen**: Secure messaging system
- **Settings Screen**: User preferences and configuration
- **Notifications Screen**: Categorized notification management

### Navigation Screens
- **Specialist Profile**: Detailed specialist information
- **Document Viewer**: Medical document viewing with annotations
- **Appointment Scheduling**: Calendar-based appointment booking
- **Biometrics Screen**: Biometric authentication setup

## Integration Testing

### Test Coverage
- Complete app flow testing
- Patient management workflows
- Referral creation processes
- Navigation flow validation
- Error handling scenarios
- Offline mode functionality

### Test Files
- `test/integration/app_integration_test.dart`: Comprehensive integration tests
- Individual unit tests for each screen
- Database integration tests
- Widget interaction tests

## Architecture Notes

### State Management
- Uses Provider pattern for state management
- DataService integration for database operations
- Proper error handling and loading states

### Theme Integration
- Consistent Material Design 3 theming
- Dark/light mode support
- Responsive design for different screen sizes

### Database Integration
- SQLite with sqflite package
- Offline-first architecture
- Data synchronization capabilities

### Security Considerations
- HIPAA compliance considerations
- Secure data handling
- Encrypted local storage
- Biometric authentication support

## Performance Optimizations

### Screen Loading
- Lazy loading of data
- Efficient widget rebuilding
- Memory management for large lists

### Animation Performance
- Hardware acceleration for animations
- Optimized animation controllers
- Smooth transitions between screens

### Database Performance
- Indexed queries for fast search
- Batch operations for efficiency
- Connection pooling and caching

## Accessibility Features

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper focus management
- Voice-over compatibility

### Visual Accessibility
- High contrast mode support
- Scalable text and UI elements
- Color-blind friendly design

### Motor Accessibility
- Large touch targets
- Gesture alternatives
- Keyboard navigation support

## Future Enhancements

### Planned Features
- Real-time video calling integration
- Advanced document annotation
- AI-powered referral suggestions
- Enhanced offline capabilities

### Technical Improvements
- Performance monitoring
- Crash reporting integration
- Analytics implementation
- Automated testing expansion

## Troubleshooting

### Common Issues
1. **Screen not loading**: Check database initialization
2. **Navigation errors**: Verify route configuration
3. **Form validation**: Ensure proper field validation
4. **Offline sync**: Check network connectivity handling

### Debug Information
- Enable debug mode for detailed logging
- Use Flutter Inspector for widget debugging
- Database query logging for data issues
- Network request monitoring for API calls
