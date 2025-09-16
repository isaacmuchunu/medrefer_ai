import 'dart:async';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';

class HeaderWidget extends StatefulWidget {
  final String hospitalName;
  final String userName;
  final String userRole;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final bool isEmergencyMode;

  const HeaderWidget({
    super.key,
    required this.hospitalName,
    required this.userName,
    required this.userRole,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.isEmergencyMode = false,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  late Timer _timer;
  String _currentTime = '';
  String _networkStatus = 'Checking...';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      // Take the first result for status display
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      switch (result) {
        case ConnectivityResult.wifi:
          _networkStatus = 'WiFi Connected';
          break;
        case ConnectivityResult.mobile:
          _networkStatus = 'Mobile Data';
          break;
        case ConnectivityResult.none:
          _networkStatus = 'Offline';
          break;
        default:
          _networkStatus = 'Unknown';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSecureConnection = _networkStatus != 'Offline';
    final connectionColor = isSecureConnection ? AppTheme.successLight : AppTheme.errorLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isEmergencyMode
              ? [Colors.red.shade700, Colors.red.shade900]
              : [
                  AppTheme.primaryLight,
                  AppTheme.primaryVariantLight,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${widget.userName}',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.hospitalName,
                        style: AppTheme.lightTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: isSecureConnection ? 'lock' : 'lock_open',
                            color: connectionColor,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _networkStatus,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: connectionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          CustomIconWidget(
                            iconName: 'access_time',
                            color: AppTheme.textSecondaryLight,
                            size: 4.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _currentTime,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: widget.onNotificationTap,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: 'notifications',
                              color: Colors.white,
                              size: 6.w,
                            ),
                          ),
                          if (widget.unreadNotifications > 0)
                            Container(
                              padding: EdgeInsets.all(0.5.w),
                              decoration: BoxDecoration(
                                color: AppTheme.lightTheme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 4.w,
                                minHeight: 4.w,
                              ),
                              child: Text(
                                '${widget.unreadNotifications}',
                                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.userRole,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
