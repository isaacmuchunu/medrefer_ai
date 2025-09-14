
import 'core/app_export.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/performance/performance_service.dart';
import 'services/ai_service.dart';
import 'services/collaboration_service.dart';
import 'services/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (non-fatal if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('dotenv: .env not loaded: $e');
  }

  // Initialize performance optimizations
  await PerformanceService.initialize();
  
  // Start performance monitoring
  PerformanceService.startMonitoring();

  // Initialize database service
  final dataService = DataService();
  await dataService.initialize();

  // Initialize error handling service
  final errorHandlingService = ErrorHandlingService();
  await errorHandlingService.initialize();

  // Initialize logging service
  final loggingService = LoggingService();
  await loggingService.initialize();

  // Initialize accessibility service
  final accessibilityService = AccessibilityService();
  await accessibilityService.initialize();

  // Initialize internationalization service
  final i18nService = InternationalizationService();
  await i18nService.initialize();

  // Initialize real-time update service
  final realtimeService = RealtimeUpdateService();
  await realtimeService.initialize();

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

  // Initialize Supabase if configured
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnon = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null && supabaseUrl.isNotEmpty && supabaseAnon != null && supabaseAnon.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

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
        onGenerateRoute: (settings) {
          final routeGuard = Provider.of<RouteGuardService>(context, listen: false);
          final name = settings.name ?? AppRoutes.splashScreen;
          if (!routeGuard.canAccessRoute(name)) {
            final redirect = routeGuard.getRedirectRoute(name);
            return MaterialPageRoute(builder: (_) => AppRoutes.routes[redirect]!(context));
          }
          final builder = AppRoutes.routes[name];
          if (builder != null) {
            return MaterialPageRoute(builder: builder, settings: settings);
          }
          // Fallback to splash
          return MaterialPageRoute(builder: AppRoutes.routes[AppRoutes.splashScreen]!, settings: settings);
        },
      );
    });
  }
}
