
import 'core/app_export.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/ai_service.dart';
import 'services/collaboration_service.dart';
import 'services/offline_sync_service.dart';
import 'services/advanced_ml_analytics_service.dart';
import 'services/blockchain_medical_records_service.dart' hide Patient, Referral;
import 'services/iot_medical_device_service.dart';
import 'services/advanced_telemedicine_service.dart';
import 'services/ai_workflow_automation_service.dart';
import 'services/enterprise_integration_service.dart';
import 'services/enterprise_erp_service.dart';
import 'services/business_intelligence_service.dart';
import 'services/multi_tenant_service.dart';
import 'services/workflow_management_service.dart';
import 'services/api_gateway_service.dart';
import 'services/digital_asset_management_service.dart';
import 'services/advanced_reporting_service.dart';
import 'services/robotic_process_automation_service.dart';
import 'services/comprehensive_error_handling_service.dart';

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

  // Initialize advanced ML analytics service
  final mlAnalyticsService = AdvancedMLAnalyticsService();
  await mlAnalyticsService.initialize();

  // Initialize blockchain medical records service
  final blockchainService = BlockchainMedicalRecordsService();
  await blockchainService.initialize();

  // Initialize IoT medical device service
  final iotDeviceService = IoTMedicalDeviceService();
  await iotDeviceService.initialize();

  // Initialize advanced telemedicine service
  final telemedicineService = AdvancedTelemedicineService();
  await telemedicineService.initialize();

  // Initialize AI workflow automation service
  final aiWorkflowService = AIWorkflowAutomationService();
  await aiWorkflowService.initialize();

  // Initialize enterprise integration service
  final integrationService = EnterpriseIntegrationService();
  await integrationService.initialize();

  // Initialize enterprise ERP service
  final erpService = EnterpriseERPService();
  await erpService.initialize();

  // Initialize business intelligence service
  final biService = BusinessIntelligenceService();
  await biService.initialize();

  // Initialize multi-tenant service
  final multiTenantService = MultiTenantService();
  await multiTenantService.initialize();

  // Initialize workflow management service
  final workflowMgmtService = WorkflowManagementService();
  await workflowMgmtService.initialize();

  // Initialize API gateway service
  final apiGatewayService = APIGatewayService();
  await apiGatewayService.initialize();

  // Initialize digital asset management service
  final damService = DigitalAssetManagementService();
  await damService.initialize();

  // Initialize advanced reporting service
  final reportingService = AdvancedReportingService();
  await reportingService.initialize();

  // Initialize robotic process automation service
  final rpaService = RoboticProcessAutomationService();
  await rpaService.initialize();

  // Initialize comprehensive error handling service
  final comprehensiveErrorService = ComprehensiveErrorHandlingService();
  await comprehensiveErrorService.initialize();

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

  var hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
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
          ChangeNotifierProvider<AdvancedMLAnalyticsService>(
            create: (context) => mlAnalyticsService,
          ),
          ChangeNotifierProvider<BlockchainMedicalRecordsService>(
            create: (context) => blockchainService,
          ),
          ChangeNotifierProvider<IoTMedicalDeviceService>(
            create: (context) => iotDeviceService,
          ),
          ChangeNotifierProvider<AdvancedTelemedicineService>(
            create: (context) => telemedicineService,
          ),
          ChangeNotifierProvider<AIWorkflowAutomationService>(
            create: (context) => aiWorkflowService,
          ),
          ChangeNotifierProvider<EnterpriseIntegrationService>(
            create: (context) => integrationService,
          ),
          ChangeNotifierProvider<EnterpriseERPService>(
            create: (context) => erpService,
          ),
          ChangeNotifierProvider<BusinessIntelligenceService>(
            create: (context) => biService,
          ),
          ChangeNotifierProvider<MultiTenantService>(
            create: (context) => multiTenantService,
          ),
          ChangeNotifierProvider<WorkflowManagementService>(
            create: (context) => workflowMgmtService,
          ),
          ChangeNotifierProvider<APIGatewayService>(
            create: (context) => apiGatewayService,
          ),
          ChangeNotifierProvider<DigitalAssetManagementService>(
            create: (context) => damService,
          ),
          ChangeNotifierProvider<AdvancedReportingService>(
            create: (context) => reportingService,
          ),
          ChangeNotifierProvider<RoboticProcessAutomationService>(
            create: (context) => rpaService,
          ),
          ChangeNotifierProvider<ComprehensiveErrorHandlingService>(
            create: (context) => comprehensiveErrorService,
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
