import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/app_export.dart';

class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({Key? key}) : super(key: key);

  @override
  _BiometricsScreenState createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> with TickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isAuthenticating = false;
  bool _authenticationFailed = false;
  String _statusMessage = 'Touch the sensor to authenticate';
  IconData _biometricIcon = Icons.fingerprint;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometrics();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canAuthenticate = canCheckBiometrics || isDeviceSupported;

      if (!canAuthenticate) {
        setState(() {
          _statusMessage = 'Biometric authentication not available on this device';
        });
        return;
      }

      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        setState(() {
          _statusMessage = 'No biometrics enrolled. Please set up in device settings';
        });
        return;
      }

      // Adapt UI based on available types
      setState(() {
        if (availableBiometrics.contains(BiometricType.face)) {
          _statusMessage = 'Look at the camera to authenticate';
          _biometricIcon = Icons.face;
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          _statusMessage = 'Touch the sensor to authenticate';
          _biometricIcon = Icons.fingerprint;
        } else {
          _statusMessage = 'Use available biometrics to authenticate';
          _biometricIcon = Icons.security;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking biometrics: $e';
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isAuthenticating = true;
      _authenticationFailed = false;
      _statusMessage = 'Authenticating...';
    });

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Use your biometric authentication to securely access your medical data',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        setState(() {
          _statusMessage = 'Authentication successful!';
        });
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } else {
        setState(() {
          _authenticationFailed = true;
          _statusMessage = 'Authentication failed. Please try again.';
        });
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _authenticationFailed = false;
          // Reset to original based on type
          _checkBiometrics();
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _authenticationFailed = true;
        if (e.code == 'NotEnrolled') {
          _statusMessage = 'No biometrics enrolled. Please set up in device settings.';
        } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
          _statusMessage = 'Too many attempts. Device locked.';
        } else {
          _statusMessage = 'Biometric authentication unavailable: ${e.message}';
        }
      });
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _skipBiometrics() {
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _skipBiometrics,
            child: Text(
              'Skip',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'Secure Access',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Use your biometric authentication to securely access your medical data',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 60),

                // Biometric sensor animation
                GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticateWithBiometrics,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isAuthenticating ? 1.0 : _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _authenticationFailed
                                ? theme.colorScheme.error.withOpacity(0.1)
                                : theme.colorScheme.primary.withOpacity(0.1),
                            border: Border.all(
                              color: _authenticationFailed
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              width: 3,
                            ),
                          ),
                          child: _isAuthenticating
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _authenticationFailed
                                      ? _biometricIcon
                                      : _biometricIcon,
                                  size: 60,
                                  color: _authenticationFailed
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // Status message
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _authenticationFailed
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Alternative authentication options
                Column(
                  children: [
                    Text(
                      'Alternative Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAlternativeOption(
                          context,
                          icon: Icons.face,
                          label: 'Face ID',
                          onTap: _authenticateWithBiometrics,
                        ),
                        _buildAlternativeOption(
                          context,
                          icon: Icons.pin,
                          label: 'PIN',
                          onTap: () {
                            // TODO: Navigate to actual PIN entry screen
                            _skipBiometrics();
                          },
                        ),
                        _buildAlternativeOption(
                          context,
                          icon: Icons.pattern,
                          label: 'Pattern',
                          onTap: () {
                            // TODO: Navigate to actual pattern entry screen
                            _skipBiometrics();
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Security notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your biometric data is stored securely on your device and never shared.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativeOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}