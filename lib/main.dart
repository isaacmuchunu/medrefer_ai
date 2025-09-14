
import 'core/app_export.dart';
import 'core/performance/performance_service.dart';
import 'services/ai_service.dart';
import 'services/collaboration_service.dart';
import 'services/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance optimizations
  await PerformanceService.initialize();

  // Initialize database service
  final dataService = DataService();
  await dataService.initialize();

  // Initialize error handling service
  final errorHandlingService = ErrorHandlingService();
  await errorHandlingService.initialize();

  // Initialize sync service
  final syncService = SyncService();
  await syncService.initialize();

  // Initialize security audit service
  final securityAuditService = SecurityAuditService();
  await securityAuditService.initialize();

  // Initialize pharmacy service
  final pharmacyService = PharmacyService(dataService);
  await pharmacyService.initialize();

  // Initialize M-Pesa service
  final mpesaService = MpesaService();
  await mpesaService.initialize();

  // Initialize RBAC service
  final rbacService = RBACService();

  // Initialize route guard service
  final routeGuardService = RouteGuardService();

  // Initialize advanced AI service
  final aiService = AIService();
  await aiService.initialize();

  // Initialize offline sync service
  final offlineSyncService = OfflineSyncService();
  await offlineSyncService.initialize();

  // Note: CollaborationService will be initialized after authentication
  // as it requires userId and authToken

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataService>(
            create: (context) => dataService,
          ),
          ChangeNotifierProvider<PharmacyService>(
            create: (context) => pharmacyService,
          ),
          ChangeNotifierProvider<MpesaService>(
            create: (context) => mpesaService,
          ),
          ChangeNotifierProvider<RBACService>(
            create: (context) => rbacService,
          ),
          Provider<RouteGuardService>(
            create: (context) => routeGuardService,
          ),
          ChangeNotifierProvider<AIService>(
            create: (context) => aiService,
          ),
          ChangeNotifierProvider<OfflineSyncService>(
            create: (context) => offlineSyncService,
          ),
          ChangeNotifierProvider<CollaborationService>(
            create: (context) => CollaborationService(),
          ),
        ],
        child: MyApp(),
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'medrefer_ai',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.splashScreen,
      );
    });
  }
}
