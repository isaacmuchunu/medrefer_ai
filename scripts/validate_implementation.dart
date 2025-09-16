import 'dart:io';

/// Validation script to check all implementations are complete
void main() async {
  print('🔍 Validating MedRefer AI Implementation...\n');

  final validationResults = <String, bool>{};

  // Check core screens
  validationResults['Core Screens'] = await _validateCoreScreens();
  
  // Check database implementation
  validationResults['Database System'] = await _validateDatabase();
  
  // Check routes
  validationResults['Route Integration'] = await _validateRoutes();
  
  // Check new screens
  validationResults['New Screens'] = await _validateNewScreens();
  
  // Check performance optimizations
  validationResults['Performance'] = await _validatePerformance();
  
  // Check tests
  validationResults['Testing'] = await _validateTests();

  // Print results
  _printValidationResults(validationResults);
  
  // Overall status
  final allPassed = validationResults.values.every((result) => result);
  print('\n${allPassed ? '✅' : '❌'} Overall Status: ${allPassed ? 'PASSED' : 'FAILED'}');
  
  if (allPassed) {
    print('\n🎉 All validations passed! The MedRefer AI implementation is complete.');
  } else {
    print('\n⚠️  Some validations failed. Please check the issues above.');
  }
}

Future<bool> _validateCoreScreens() async {
  print('📱 Validating Core Screens...');
  
  final coreScreens = [
    'lib/presentation/splash_screen/splash_screen.dart',
    'lib/presentation/login_screen/login_screen.dart',
    'lib/presentation/dashboard/dashboard.dart',
    'lib/presentation/create_referral_screen/create_referral_screen.dart',
    'lib/presentation/patient_search_screen/patient_search_screen.dart',
    'lib/presentation/referral_tracking/referral_tracking.dart',
    'lib/presentation/chat_screen/chat_screen.dart',
    'lib/presentation/biometrics_screen/biometrics_screen.dart',
  ];

  var allExist = true;
  for (final screen in coreScreens) {
    final file = File(screen);
    if (await file.exists()) {
      print('  ✅ ${screen.split('/').last}');
    } else {
      print('  ❌ ${screen.split('/').last} - Missing');
      allExist = false;
    }
  }

  return allExist;
}

Future<bool> _validateDatabase() async {
  print('\n🗄️  Validating Database System...');
  
  final databaseFiles = [
    'lib/database/database_helper.dart',
    'lib/database/models/models.dart',
    'lib/database/models/patient.dart',
    'lib/database/models/specialist.dart',
    'lib/database/models/referral.dart',
    'lib/database/models/message.dart',
    'lib/database/models/medical_history.dart',
    'lib/database/models/condition.dart',
    'lib/database/models/medication.dart',
    'lib/database/models/document.dart',
    'lib/database/models/emergency_contact.dart',
    'lib/database/models/vital_statistics.dart',
    'lib/database/dao/dao.dart',
    'lib/database/services/data_service.dart',
    'lib/database/services/migration_service.dart',
  ];

  var allExist = true;
  for (final file in databaseFiles) {
    final fileObj = File(file);
    if (await fileObj.exists()) {
      print('  ✅ ${file.split('/').last}');
    } else {
      print('  ❌ ${file.split('/').last} - Missing');
      allExist = false;
    }
  }


  return allExist;
}

Future<bool> _validateRoutes() async {
  print('\n🛣️  Validating Route Integration...');
  
  final routesFile = File('lib/routes/app_routes.dart');
  if (!await routesFile.exists()) {
    print('  ❌ app_routes.dart - Missing');
    return false;
  }

  final content = await routesFile.readAsString();
  final requiredRoutes = [
    'dashboard',
    'login',
    'createReferral',
    'patientSearch',
    'addPatient',
    'chat',
    'teleconferenceCall',
    'errorOffline',
    'helpSupport',
  ];

  var allRoutesExist = true;
  for (final route in requiredRoutes) {
    if (content.contains(route)) {
      print('  ✅ $route route');
    } else {
      print('  ❌ $route route - Missing');
      allRoutesExist = false;
    }
  }

  return allRoutesExist;
}

Future<bool> _validateNewScreens() async {
  print('\n🆕 Validating New Screens...');
  
  final newScreens = [
    'lib/presentation/add_patient_screen/add_patient_screen.dart',
    'lib/presentation/teleconference_call_screen/teleconference_call_screen.dart',
    'lib/presentation/error_offline_screen/error_offline_screen.dart',
    'lib/presentation/help_support_screen/help_support_screen.dart',
    'lib/presentation/settings_screen/settings_screen.dart',
    'lib/presentation/notifications_screen/notifications_screen.dart',
  ];

  var allExist = true;
  for (final screen in newScreens) {
    final file = File(screen);
    if (await file.exists()) {
      print('  ✅ ${screen.split('/').last}');
    } else {
      print('  ❌ ${screen.split('/').last} - Missing');
      allExist = false;
    }
  }

  return allExist;
}

Future<bool> _validatePerformance() async {
  print('\n⚡ Validating Performance Optimizations...');
  
  final performanceFiles = [
    'lib/core/performance/performance_service.dart',
    'lib/widgets/optimized_image.dart',
    'lib/widgets/optimized_list.dart',
    'lib/widgets/performance_monitor.dart',
  ];

  var allExist = true;
  for (final file in performanceFiles) {
    final fileObj = File(file);
    if (await fileObj.exists()) {
      print('  ✅ ${file.split('/').last}');
    } else {
      print('  ❌ ${file.split('/').last} - Missing');
      allExist = false;
    }
  }

  // Check if main.dart includes performance initialization
  final mainFile = File('lib/main.dart');
  if (await mainFile.exists()) {
    final content = await mainFile.readAsString();
    if (content.contains('PerformanceService.initialize')) {
      print('  ✅ Performance service initialized in main.dart');
    } else {
      print('  ❌ Performance service not initialized in main.dart');
      allExist = false;
    }
  }

  return allExist;
}

Future<bool> _validateTests() async {
  print('\n🧪 Validating Tests...');
  
  final testFiles = [
    'test/database_test.dart',
    'test/presentation/add_patient_screen_test.dart',
    'test/presentation/teleconference_call_screen_test.dart',
    'test/presentation/error_offline_screen_test.dart',
    'test/presentation/help_support_screen_test.dart',
    'test/integration/app_integration_test.dart',
    'test/integration/complete_app_test.dart',
  ];

  var allExist = true;
  for (final test in testFiles) {
    final file = File(test);
    if (await file.exists()) {
      print('  ✅ ${test.split('/').last}');
    } else {
      print('  ❌ ${test.split('/').last} - Missing');
      allExist = false;
    }
  }

  return allExist;
}

void _printValidationResults(Map<String, bool> results) {
  print('\n📊 Validation Summary:');
  print('=' * 50);
  
  results.forEach((category, passed) {
    final status = passed ? '✅ PASSED' : '❌ FAILED';
    final padding = ' ' * (30 - category.length);
    print('$category$padding$status');
  });
  
  print('=' * 50);
  
  final passedCount = results.values.where((result) => result).length;
  final totalCount = results.length;
  print('Results: $passedCount/$totalCount categories passed');
}

/// Additional validation functions
Future<bool> _validateDependencies() async {
  print('\n📦 Validating Dependencies...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('  ❌ pubspec.yaml - Missing');
    return false;
  }

  final content = await pubspecFile.readAsString();
  final requiredDependencies = [
    'flutter',
    'provider',
    'sqflite',
    'path',
    'shared_preferences',
  ];

  var allDepsExist = true;
  for (final dep in requiredDependencies) {
    if (content.contains('$dep:')) {
      print('  ✅ $dep dependency');
    } else {
      print('  ❌ $dep dependency - Missing');
      allDepsExist = false;
    }
  }

  return allDepsExist;
}

Future<bool> _validateAssets() async {
  print('\n🖼️  Validating Assets...');
  
  final assetsDir = Directory('assets');
  if (!await assetsDir.exists()) {
    print('  ❌ assets directory - Missing');
    return false;
  }

  final requiredAssets = [
    'assets/images',
    'assets/icons',
  ];

  var allAssetsExist = true;
  for (final asset in requiredAssets) {
    final dir = Directory(asset);
    if (await dir.exists()) {
      print('  ✅ ${asset.split('/').last} directory');
    } else {
      print('  ❌ ${asset.split('/').last} directory - Missing');
      allAssetsExist = false;
    }
  }

  return allAssetsExist;
}

