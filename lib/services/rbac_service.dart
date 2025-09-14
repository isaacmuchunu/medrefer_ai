import 'package:flutter/foundation.dart';
import '../database/models/models.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/dao/rbac_dao.dart';

/// Role-Based Access Control Service for MedRefer AI
class RBACService extends ChangeNotifier {
  static final RBACService _instance = RBACService._internal();
  factory RBACService() => _instance;
  RBACService._internal();

  User? _currentUser;
  UserRole? _currentRole;
  List<Permission> _currentPermissions = [];

  // Getters
  User? get currentUser => _currentUser;
  UserRole? get currentRole => _currentRole;
  List<Permission> get currentPermissions => List.unmodifiable(_currentPermissions);
  bool get isAuthenticated => _currentUser != null;

  /// Set current user and load their permissions
  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    _currentRole = user.role;
    await _loadUserPermissions();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('RBAC: User ${user.email} logged in with role ${user.role.name}');
    }
  }

  /// Clear current user session
  void clearCurrentUser() {
    _currentUser = null;
    _currentRole = null;
    _currentPermissions.clear();
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('RBAC: User session cleared');
    }
  }

  /// Load permissions for current user role
  Future<void> _loadUserPermissions() async {
    if (_currentRole == null) {
      _currentPermissions = [];
      return;
    }

    // Try to load from RBAC tables; fallback to static map if not found
    try {
      final db = await DatabaseHelper().database;
      final rbac = RBACDAO(db);
      final role = await rbac.getRoleByName(_currentRole!.name);
      if (role != null) {
        final perms = await rbac.getPermissionsForRole(role.id);
        _currentPermissions = perms
            .map((p) => _mapPermissionKey(p.key))
            .whereType<Permission>()
            .toList();
        return;
      }
    } catch (_) {
      // ignore and fallback
    }

    _currentPermissions = _getPermissionsForRole(_currentRole!);
  }

  /// Get permissions for a specific role
  List<Permission> _getPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return [
          // Pharmacy permissions
          Permission.viewPharmacy,
          Permission.purchaseMedicine,
          Permission.viewOwnOrders,
          
          // Profile permissions
          Permission.viewOwnProfile,
          Permission.editOwnProfile,
          Permission.viewOwnMedicalHistory,
          
          // Appointment permissions
          Permission.bookAppointment,
          Permission.viewOwnAppointments,
          Permission.cancelOwnAppointment,
          
          // Communication permissions
          Permission.sendMessage,
          Permission.viewOwnMessages,
          
          // Document permissions
          Permission.viewOwnDocuments,
          Permission.uploadDocuments,
        ];

      case UserRole.doctor:
        return [
          // Patient management
          Permission.viewPatients,
          Permission.viewPatientProfiles,
          Permission.viewMedicalHistory,
          Permission.updateMedicalHistory,
          
          // Referral management
          Permission.createReferral,
          Permission.viewReferrals,
          Permission.updateReferralStatus,
          
          // Prescription management
          Permission.prescribeMedicine,
          Permission.viewPrescriptions,
          Permission.updatePrescriptions,
          
          // Appointment management
          Permission.viewAppointments,
          Permission.manageAppointments,
          Permission.viewSchedule,
          
          // Communication
          Permission.sendMessage,
          Permission.viewMessages,
          Permission.sendSecureMessage,
          
          // Document management
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.shareDocuments,
          
          // Profile management
          Permission.viewOwnProfile,
          Permission.editOwnProfile,
        ];

      case UserRole.specialist:
        return [
          // Patient management (limited)
          Permission.viewAssignedPatients,
          Permission.viewPatientProfiles,
          Permission.viewMedicalHistory,
          Permission.updateMedicalHistory,
          
          // Referral management
          Permission.viewReferrals,
          Permission.acceptReferral,
          Permission.updateReferralStatus,
          Permission.completeReferral,
          
          // Appointment management
          Permission.viewAppointments,
          Permission.manageAppointments,
          Permission.viewSchedule,
          
          // Communication
          Permission.sendMessage,
          Permission.viewMessages,
          Permission.sendSecureMessage,
          
          // Document management
          Permission.viewDocuments,
          Permission.uploadDocuments,
          Permission.shareDocuments,
          
          // Profile management
          Permission.viewOwnProfile,
          Permission.editOwnProfile,
        ];

      case UserRole.nurse:
        return [
          // Patient management
          Permission.viewPatients,
          Permission.viewPatientProfiles,
          Permission.viewMedicalHistory,
          Permission.updateVitalSigns,
          
          // Appointment support
          Permission.viewAppointments,
          Permission.assistAppointments,
          
          // Communication
          Permission.sendMessage,
          Permission.viewMessages,
          
          // Document management
          Permission.viewDocuments,
          Permission.uploadDocuments,
          
          // Profile management
          Permission.viewOwnProfile,
          Permission.editOwnProfile,
        ];

      case UserRole.pharmacist:
        return [
          // Pharmacy management
          Permission.viewPharmacy,
          Permission.manageMedicine,
          Permission.viewAllOrders,
          Permission.processOrders,
          Permission.manageInventory,
          
          // Prescription management
          Permission.viewPrescriptions,
          Permission.dispenseMedicine,
          Permission.validatePrescriptions,
          
          // Communication
          Permission.sendMessage,
          Permission.viewMessages,
          
          // Profile management
          Permission.viewOwnProfile,
          Permission.editOwnProfile,
        ];

      case UserRole.admin:
        return Permission.values; // Admin has all permissions

      case UserRole.superAdmin:
        return Permission.values; // Super admin has all permissions
    }
  }

  Permission? _mapPermissionKey(String key) {
    try {
      return Permission.values.firstWhere((p) => p.name == key);
    } catch (_) {
      return null;
    }
  }

  /// Check if current user has a specific permission
  bool hasPermission(Permission permission) {
    return _currentPermissions.contains(permission);
  }

  /// Check if current user has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if current user has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Check if current user has a specific role
  bool hasRole(UserRole role) {
    return _currentRole == role;
  }

  /// Check if current user has any of the specified roles
  bool hasAnyRole(List<UserRole> roles) {
    return _currentRole != null && roles.contains(_currentRole);
  }

  /// Check if user can access a specific screen/feature
  bool canAccess(String feature) {
    switch (feature) {
      case 'pharmacy':
        return hasAnyPermission([Permission.viewPharmacy, Permission.manageMedicine]);
      
      case 'pharmacy_purchase':
        return hasPermission(Permission.purchaseMedicine);
      
      case 'patient_management':
        return hasAnyPermission([Permission.viewPatients, Permission.viewAssignedPatients]);
      
      case 'referral_creation':
        return hasPermission(Permission.createReferral);
      
      case 'referral_management':
        return hasAnyPermission([Permission.viewReferrals, Permission.updateReferralStatus]);
      
      case 'prescription_management':
        return hasAnyPermission([Permission.prescribeMedicine, Permission.viewPrescriptions]);
      
      case 'appointment_booking':
        return hasPermission(Permission.bookAppointment);
      
      case 'appointment_management':
        return hasPermission(Permission.manageAppointments);
      
      case 'secure_messaging':
        return hasAnyPermission([Permission.sendMessage, Permission.sendSecureMessage]);
      
      case 'document_management':
        return hasAnyPermission([Permission.viewDocuments, Permission.uploadDocuments]);
      
      case 'admin_panel':
        return hasAnyRole([UserRole.admin, UserRole.superAdmin]);
      
      case 'user_management':
        return hasAnyRole([UserRole.admin, UserRole.superAdmin]);
      
      case 'system_settings':
        return hasRole(UserRole.superAdmin);
      
      default:
        return false;
    }
  }

  /// Check if user can perform action on specific resource
  bool canPerformAction(String action, String resource, {String? resourceOwnerId}) {
    switch (action) {
      case 'view':
        return _canView(resource, resourceOwnerId);
      case 'edit':
        return _canEdit(resource, resourceOwnerId);
      case 'delete':
        return _canDelete(resource, resourceOwnerId);
      case 'create':
        return _canCreate(resource);
      default:
        return false;
    }
  }

  bool _canView(String resource, String? resourceOwnerId) {
    switch (resource) {
      case 'patient_profile':
        if (resourceOwnerId == _currentUser?.id) return true; // Own profile
        return hasAnyPermission([Permission.viewPatients, Permission.viewAssignedPatients]);
      
      case 'medical_history':
        if (resourceOwnerId == _currentUser?.id) return hasPermission(Permission.viewOwnMedicalHistory);
        return hasPermission(Permission.viewMedicalHistory);
      
      case 'prescription':
        return hasAnyPermission([Permission.viewPrescriptions, Permission.prescribeMedicine]);
      
      case 'order':
        if (resourceOwnerId == _currentUser?.id) return hasPermission(Permission.viewOwnOrders);
        return hasPermission(Permission.viewAllOrders);
      
      default:
        return false;
    }
  }

  bool _canEdit(String resource, String? resourceOwnerId) {
    switch (resource) {
      case 'patient_profile':
        if (resourceOwnerId == _currentUser?.id) return hasPermission(Permission.editOwnProfile);
        return hasAnyRole([UserRole.doctor, UserRole.nurse, UserRole.admin]);
      
      case 'medical_history':
        return hasPermission(Permission.updateMedicalHistory);
      
      case 'prescription':
        return hasAnyPermission([Permission.prescribeMedicine, Permission.updatePrescriptions]);
      
      default:
        return false;
    }
  }

  bool _canDelete(String resource, String? resourceOwnerId) {
    switch (resource) {
      case 'patient_profile':
        return hasAnyRole([UserRole.admin, UserRole.superAdmin]);
      
      case 'prescription':
        return hasAnyRole([UserRole.doctor, UserRole.admin]);
      
      default:
        return hasAnyRole([UserRole.admin, UserRole.superAdmin]);
    }
  }

  bool _canCreate(String resource) {
    switch (resource) {
      case 'referral':
        return hasPermission(Permission.createReferral);
      
      case 'prescription':
        return hasPermission(Permission.prescribeMedicine);
      
      case 'appointment':
        return hasAnyPermission([Permission.bookAppointment, Permission.manageAppointments]);
      
      default:
        return false;
    }
  }

  /// Get user-friendly role name
  String getRoleName(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.specialist:
        return 'Specialist';
      case UserRole.nurse:
        return 'Nurse';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.superAdmin:
        return 'Super Administrator';
    }
  }

  /// Get available features for current user
  List<String> getAvailableFeatures() {
    final features = <String>[];
    
    if (canAccess('pharmacy')) features.add('pharmacy');
    if (canAccess('patient_management')) features.add('patient_management');
    if (canAccess('referral_creation')) features.add('referral_creation');
    if (canAccess('referral_management')) features.add('referral_management');
    if (canAccess('prescription_management')) features.add('prescription_management');
    if (canAccess('appointment_booking')) features.add('appointment_booking');
    if (canAccess('appointment_management')) features.add('appointment_management');
    if (canAccess('secure_messaging')) features.add('secure_messaging');
    if (canAccess('document_management')) features.add('document_management');
    if (canAccess('admin_panel')) features.add('admin_panel');
    
    return features;
  }
}

/// User permissions enum
enum Permission {
  // Pharmacy permissions
  viewPharmacy,
  purchaseMedicine,
  manageMedicine,
  viewOwnOrders,
  viewAllOrders,
  processOrders,
  manageInventory,
  
  // Profile permissions
  viewOwnProfile,
  editOwnProfile,
  viewPatients,
  viewAssignedPatients,
  viewPatientProfiles,
  
  // Medical permissions
  viewOwnMedicalHistory,
  viewMedicalHistory,
  updateMedicalHistory,
  updateVitalSigns,
  
  // Referral permissions
  createReferral,
  viewReferrals,
  acceptReferral,
  updateReferralStatus,
  completeReferral,
  
  // Prescription permissions
  prescribeMedicine,
  viewPrescriptions,
  updatePrescriptions,
  dispenseMedicine,
  validatePrescriptions,
  
  // Appointment permissions
  bookAppointment,
  viewOwnAppointments,
  viewAppointments,
  manageAppointments,
  assistAppointments,
  cancelOwnAppointment,
  viewSchedule,
  
  // Communication permissions
  sendMessage,
  viewOwnMessages,
  viewMessages,
  sendSecureMessage,
  
  // Document permissions
  viewOwnDocuments,
  viewDocuments,
  uploadDocuments,
  shareDocuments,
  
  // Admin permissions
  manageUsers,
  viewSystemLogs,
  manageSystemSettings,
}
