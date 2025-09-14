import 'dart:io';

/// Script to validate and fix import statements across the codebase
void main() async {
  print('🔍 Validating and fixing imports...\n');
  
  // Check core app_export.dart
  await validateAppExports();
  
  // Check database layer imports
  await validateDatabaseImports();
  
  // Check services imports
  await validateServicesImports();
  
  // Check presentation layer imports
  await validatePresentationImports();
  
  // Check test imports
  await validateTestImports();
  
  print('\n✅ Import validation complete!');
}

Future<void> validateAppExports() async {
  print('📦 Validating core app exports...');
  
  final appExportFile = File('lib/core/app_export.dart');
  if (!await appExportFile.exists()) {
    print('  ❌ app_export.dart not found');
    return;
  }
  
  final content = await appExportFile.readAsString();
  final requiredExports = [
    'package:flutter/material.dart',
    'package:flutter/services.dart',
    'package:sizer/sizer.dart',
    'package:provider/provider.dart',
    '../routes/app_routes.dart',
    '../theme/app_theme.dart',
    '../database/database.dart',
    '../services/auth_service.dart',
    '../services/biometric_service.dart',
    '../services/notification_service.dart',
  ];
  
  for (final export in requiredExports) {
    if (content.contains("export '$export'")) {
      print('  ✅ $export');
    } else {
      print('  ❌ Missing: $export');
    }
  }
}

Future<void> validateDatabaseImports() async {
  print('\n🗄️ Validating database imports...');
  
  // Check database.dart export file
  final dbExportFile = File('lib/database/database.dart');
  if (await dbExportFile.exists()) {
    print('  ✅ database.dart exists');
  } else {
    print('  ❌ database.dart missing');
  }
  
  // Check models export file
  final modelsFile = File('lib/database/models/models.dart');
  if (await modelsFile.exists()) {
    final content = await modelsFile.readAsString();
    final requiredModels = [
      'base_model.dart',
      'patient.dart',
      'specialist.dart',
      'referral.dart',
      'message.dart',
      'medical_history.dart',
      'condition.dart',
      'medication.dart',
      'document.dart',
      'emergency_contact.dart',
      'vital_statistics.dart',
    ];
    
    for (final model in requiredModels) {
      if (content.contains("export '$model'")) {
        print('  ✅ Model: $model');
      } else {
        print('  ❌ Missing model: $model');
      }
    }
  }
  
  // Check DAO export file
  final daoFile = File('lib/database/dao/dao.dart');
  if (await daoFile.exists()) {
    final content = await daoFile.readAsString();
    final requiredDaos = [
      'patient_dao.dart',
      'specialist_dao.dart',
      'referral_dao.dart',
      'message_dao.dart',
      'medical_history_dao.dart',
      'condition_dao.dart',
      'medication_dao.dart',
      'document_dao.dart',
      'emergency_contact_dao.dart',
      'vital_statistics_dao.dart',
    ];
    
    for (final dao in requiredDaos) {
      if (content.contains("export '$dao'")) {
        print('  ✅ DAO: $dao');
      } else {
        print('  ❌ Missing DAO: $dao');
      }
    }
  }
}

Future<void> validateServicesImports() async {
  print('\n🔧 Validating services imports...');
  
  final services = [
    'lib/services/auth_service.dart',
    'lib/services/biometric_service.dart',
    'lib/services/notification_service.dart',
  ];
  
  for (final service in services) {
    final file = File(service);
    if (await file.exists()) {
      print('  ✅ ${service.split('/').last}');
    } else {
      print('  ❌ Missing: ${service.split('/').last}');
    }
  }
  
  // Check core services
  final coreServices = [
    'lib/core/performance/performance_service.dart',
    'lib/core/realtime/realtime_service.dart',
  ];
  
  for (final service in coreServices) {
    final file = File(service);
    if (await file.exists()) {
      print('  ✅ ${service.split('/').last}');
    } else {
      print('  ❌ Missing: ${service.split('/').last}');
    }
  }
}

Future<void> validatePresentationImports() async {
  print('\n🎨 Validating presentation layer imports...');
  
  // Check main screens
  final screens = [
    'lib/presentation/dashboard/dashboard.dart',
    'lib/presentation/patient_profile/patient_profile.dart',
    'lib/presentation/referral_tracking/referral_tracking.dart',
    'lib/presentation/specialist_directory/specialist_directory.dart',
    'lib/presentation/create_referral/create_referral.dart',
    'lib/presentation/secure_messaging/secure_messaging.dart',
    'lib/presentation/login_screen/login_screen.dart',
    'lib/presentation/splash_screen/splash_screen.dart',
  ];
  
  for (final screen in screens) {
    final file = File(screen);
    if (await file.exists()) {
      print('  ✅ ${screen.split('/').last}');
      
      // Check if it imports app_export
      final content = await file.readAsString();
      if (content.contains("import '../../core/app_export.dart'")) {
        print('    ✅ Uses app_export');
      } else {
        print('    ⚠️  Missing app_export import');
      }
    } else {
      print('  ❌ Missing: ${screen.split('/').last}');
    }
  }
}

Future<void> validateTestImports() async {
  print('\n🧪 Validating test imports...');
  
  final testFiles = [
    'test/database_test.dart',
  ];
  
  for (final testFile in testFiles) {
    final file = File(testFile);
    if (await file.exists()) {
      print('  ✅ ${testFile.split('/').last}');
      
      // Check test imports
      final content = await file.readAsString();
      if (content.contains("import 'package:flutter_test/flutter_test.dart'")) {
        print('    ✅ Has flutter_test import');
      }
      if (content.contains("import '../lib/database/database.dart'")) {
        print('    ✅ Has database import');
      }
    } else {
      print('  ❌ Missing: ${testFile.split('/').last}');
    }
  }
}
