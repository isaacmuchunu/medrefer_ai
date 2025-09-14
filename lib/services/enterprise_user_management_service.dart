import 'dart:async';
import 'dart:math';
import 'package:medrefer_ai/core/app_export.dart';
import 'package:medrefer_ai/database/models/user_management_models.dart';

/// Enterprise User Management Service for comprehensive user administration
class EnterpriseUserManagementService extends ChangeNotifier {
  static final EnterpriseUserManagementService _instance = EnterpriseUserManagementService._internal();
  factory EnterpriseUserManagementService() => _instance;
  EnterpriseUserManagementService._internal();

  late LoggingService _loggingService;
  final List<EnterpriseUser> _users = [];
  final List<UserGroup> _userGroups = [];
  final List<Role> _roles = [];
  final List<Permission> _permissions = [];
  final List<Department> _departments = [];
  final List<Organization> _organizations = [];
  final List<UserSession> _activeSessions = [];

  // Statistics tracking
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalGroups = 0;
  int _totalDepartments = 0;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _loggingService = LoggingService();
      
      // Initialize with sample data
      await _initializeSampleData();
      
      _loggingService.info('Enterprise User Management Service initialized successfully');
    } catch (e) {
      _loggingService.error('Failed to initialize Enterprise User Management Service', error: e);
      rethrow;
    }
  }

  /// Initialize with sample data
  Future<void> _initializeSampleData() async {
    // Create sample permissions
    _permissions.addAll([
      Permission(
        id: 'perm_1',
        name: 'Read Patients',
        description: 'View patient information',
        resource: 'patients',
        action: 'read',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_2',
        name: 'Create Patients',
        description: 'Add new patients',
        resource: 'patients',
        action: 'create',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_3',
        name: 'Update Patients',
        description: 'Modify patient information',
        resource: 'patients',
        action: 'update',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_4',
        name: 'Delete Patients',
        description: 'Remove patients',
        resource: 'patients',
        action: 'delete',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_5',
        name: 'Manage Referrals',
        description: 'Full access to referral management',
        resource: 'referrals',
        action: 'manage',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_6',
        name: 'View Analytics',
        description: 'Access to analytics dashboard',
        resource: 'analytics',
        action: 'read',
        createdAt: DateTime.now(),
      ),
      Permission(
        id: 'perm_7',
        name: 'Manage Users',
        description: 'User administration',
        resource: 'users',
        action: 'manage',
        createdAt: DateTime.now(),
      ),
    ]);

    // Create sample roles
    _roles.addAll([
      Role(
        id: 'role_1',
        name: 'Super Admin',
        description: 'Full system access',
        permissions: _permissions.map((p) => p.id).toList(),
        level: 1,
        color: '#DC2626',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Role(
        id: 'role_2',
        name: 'Admin',
        description: 'Administrative access',
        permissions: ['perm_1', 'perm_2', 'perm_3', 'perm_5', 'perm_6'],
        level: 2,
        color: '#EA580C',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Role(
        id: 'role_3',
        name: 'Doctor',
        description: 'Medical professional access',
        permissions: ['perm_1', 'perm_2', 'perm_3', 'perm_5'],
        level: 3,
        color: '#059669',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Role(
        id: 'role_4',
        name: 'Nurse',
        description: 'Nursing staff access',
        permissions: ['perm_1', 'perm_3'],
        level: 4,
        color: '#2563EB',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Role(
        id: 'role_5',
        name: 'Staff',
        description: 'General staff access',
        permissions: ['perm_1'],
        level: 5,
        color: '#6B7280',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);

    // Create sample organization
    final organization = Organization(
      id: 'org_1',
      name: 'MedRefer Healthcare',
      description: 'Leading healthcare referral management system',
      website: 'https://medrefer.com',
      email: 'info@medrefer.com',
      phone: '+1-555-0123',
      address: '123 Healthcare Ave, Medical City, MC 12345',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _organizations.add(organization);

    // Create sample departments
    _departments.addAll([
      Department(
        id: 'dept_1',
        name: 'Cardiology',
        description: 'Heart and cardiovascular care',
        organizationId: organization.id,
        color: '#DC2626',
        icon: 'favorite',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Department(
        id: 'dept_2',
        name: 'Neurology',
        description: 'Brain and nervous system care',
        organizationId: organization.id,
        color: '#7C3AED',
        icon: 'psychology',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Department(
        id: 'dept_3',
        name: 'Emergency Medicine',
        description: 'Emergency and urgent care',
        organizationId: organization.id,
        color: '#EA580C',
        icon: 'local_hospital',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Department(
        id: 'dept_4',
        name: 'IT Department',
        description: 'Information technology support',
        organizationId: organization.id,
        color: '#059669',
        icon: 'computer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);

    // Create sample user groups
    _userGroups.addAll([
      UserGroup(
        id: 'group_1',
        name: 'Senior Doctors',
        description: 'Senior medical professionals',
        organizationId: organization.id,
        departmentId: 'dept_1',
        permissions: ['perm_1', 'perm_2', 'perm_3', 'perm_5'],
        color: '#059669',
        icon: 'medical_services',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserGroup(
        id: 'group_2',
        name: 'Emergency Staff',
        description: 'Emergency department staff',
        organizationId: organization.id,
        departmentId: 'dept_3',
        permissions: ['perm_1', 'perm_2', 'perm_3'],
        color: '#EA580C',
        icon: 'emergency',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserGroup(
        id: 'group_3',
        name: 'IT Support',
        description: 'Information technology team',
        organizationId: organization.id,
        departmentId: 'dept_4',
        permissions: ['perm_1', 'perm_6', 'perm_7'],
        color: '#2563EB',
        icon: 'support_agent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);

    // Create sample users
    _users.addAll([
      EnterpriseUser(
        id: 'user_1',
        email: 'admin@medrefer.com',
        firstName: 'John',
        lastName: 'Administrator',
        phoneNumber: '+1-555-0101',
        role: 'Super Admin',
        permissions: _permissions.map((p) => p.id).toList(),
        userGroups: ['group_3'],
        organizationId: organization.id,
        departmentId: 'dept_4',
        jobTitle: 'System Administrator',
        location: 'Headquarters',
        timezone: 'America/New_York',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(hours: 2)),
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      EnterpriseUser(
        id: 'user_2',
        email: 'dr.smith@medrefer.com',
        firstName: 'Dr. Sarah',
        lastName: 'Smith',
        phoneNumber: '+1-555-0102',
        role: 'Doctor',
        permissions: ['perm_1', 'perm_2', 'perm_3', 'perm_5'],
        userGroups: ['group_1'],
        organizationId: organization.id,
        departmentId: 'dept_1',
        managerId: 'user_1',
        employeeId: 'EMP001',
        jobTitle: 'Senior Cardiologist',
        location: 'Cardiology Wing',
        timezone: 'America/New_York',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(minutes: 30)),
        createdAt: DateTime.now().subtract(Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
      EnterpriseUser(
        id: 'user_3',
        email: 'nurse.jones@medrefer.com',
        firstName: 'Mary',
        lastName: 'Jones',
        phoneNumber: '+1-555-0103',
        role: 'Nurse',
        permissions: ['perm_1', 'perm_3'],
        userGroups: ['group_2'],
        organizationId: organization.id,
        departmentId: 'dept_3',
        managerId: 'user_2',
        employeeId: 'EMP002',
        jobTitle: 'Registered Nurse',
        location: 'Emergency Department',
        timezone: 'America/New_York',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(hours: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 150)),
        updatedAt: DateTime.now(),
      ),
      EnterpriseUser(
        id: 'user_4',
        email: 'staff.davis@medrefer.com',
        firstName: 'Robert',
        lastName: 'Davis',
        phoneNumber: '+1-555-0104',
        role: 'Staff',
        permissions: ['perm_1'],
        userGroups: [],
        organizationId: organization.id,
        departmentId: 'dept_1',
        managerId: 'user_2',
        employeeId: 'EMP003',
        jobTitle: 'Administrative Assistant',
        location: 'Cardiology Wing',
        timezone: 'America/New_York',
        isActive: true,
        isVerified: true,
        lastLoginAt: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
    ]);

    _updateStatistics();
  }

  /// Update statistics
  void _updateStatistics() {
    _totalUsers = _users.length;
    _activeUsers = _users.where((user) => user.isActive).length;
    _totalGroups = _userGroups.length;
    _totalDepartments = _departments.length;
  }

  /// Get all users
  List<EnterpriseUser> getAllUsers() {
    return List.from(_users);
  }

  /// Get users by department
  List<EnterpriseUser> getUsersByDepartment(String departmentId) {
    return _users.where((user) => user.departmentId == departmentId).toList();
  }

  /// Get users by role
  List<EnterpriseUser> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  /// Get users by group
  List<EnterpriseUser> getUsersByGroup(String groupId) {
    return _users.where((user) => user.userGroups.contains(groupId)).toList();
  }

  /// Get user by ID
  EnterpriseUser? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Create new user
  Future<String> createUser(EnterpriseUser user) async {
    try {
      final userId = _generateId();
      final newUser = user.copyWith(
        id: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _users.add(newUser);
      _updateStatistics();
      notifyListeners();
      
      _loggingService.info('User created', context: 'UserManagement', metadata: {
        'user_id': userId,
        'email': user.email,
        'role': user.role,
      });
      
      return userId;
    } catch (e) {
      _loggingService.error('Failed to create user', error: e);
      rethrow;
    }
  }

  /// Update user
  Future<void> updateUser(EnterpriseUser user) async {
    try {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user.copyWith(updatedAt: DateTime.now());
        notifyListeners();
        
        _loggingService.info('User updated', context: 'UserManagement', metadata: {
          'user_id': user.id,
          'email': user.email,
        });
      }
    } catch (e) {
      _loggingService.error('Failed to update user', error: e);
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      _users.removeWhere((user) => user.id == userId);
      _updateStatistics();
      notifyListeners();
      
      _loggingService.info('User deleted', context: 'UserManagement', metadata: {
        'user_id': userId,
      });
    } catch (e) {
      _loggingService.error('Failed to delete user', error: e);
      rethrow;
    }
  }

  /// Activate/Deactivate user
  Future<void> toggleUserStatus(String userId) async {
    try {
      final user = getUserById(userId);
      if (user != null) {
        final updatedUser = user.copyWith(
          isActive: !user.isActive,
          updatedAt: DateTime.now(),
        );
        await updateUser(updatedUser);
      }
    } catch (e) {
      _loggingService.error('Failed to toggle user status', error: e);
      rethrow;
    }
  }

  /// Assign user to group
  Future<void> assignUserToGroup(String userId, String groupId) async {
    try {
      final user = getUserById(userId);
      if (user != null && !user.userGroups.contains(groupId)) {
        final updatedGroups = List<String>.from(user.userGroups)..add(groupId);
        final updatedUser = user.copyWith(
          userGroups: updatedGroups,
          updatedAt: DateTime.now(),
        );
        await updateUser(updatedUser);
      }
    } catch (e) {
      _loggingService.error('Failed to assign user to group', error: e);
      rethrow;
    }
  }

  /// Remove user from group
  Future<void> removeUserFromGroup(String userId, String groupId) async {
    try {
      final user = getUserById(userId);
      if (user != null) {
        final updatedGroups = List<String>.from(user.userGroups)..remove(groupId);
        final updatedUser = user.copyWith(
          userGroups: updatedGroups,
          updatedAt: DateTime.now(),
        );
        await updateUser(updatedUser);
      }
    } catch (e) {
      _loggingService.error('Failed to remove user from group', error: e);
      rethrow;
    }
  }

  /// Get all user groups
  List<UserGroup> getAllUserGroups() {
    return List.from(_userGroups);
  }

  /// Create user group
  Future<String> createUserGroup(UserGroup group) async {
    try {
      final groupId = _generateId();
      final newGroup = group.copyWith(
        id: groupId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _userGroups.add(newGroup);
      _updateStatistics();
      notifyListeners();
      
      _loggingService.info('User group created', context: 'UserManagement', metadata: {
        'group_id': groupId,
        'name': group.name,
      });
      
      return groupId;
    } catch (e) {
      _loggingService.error('Failed to create user group', error: e);
      rethrow;
    }
  }

  /// Get all roles
  List<Role> getAllRoles() {
    return List.from(_roles);
  }

  /// Get all permissions
  List<Permission> getAllPermissions() {
    return List.from(_permissions);
  }

  /// Get all departments
  List<Department> getAllDepartments() {
    return List.from(_departments);
  }

  /// Get department hierarchy
  Map<String, List<Department>> getDepartmentHierarchy() {
    final hierarchy = <String, List<Department>>{};
    
    for (final dept in _departments) {
      if (dept.parentDepartmentId == null) {
        hierarchy['root'] ??= [];
        hierarchy['root']!.add(dept);
      } else {
        hierarchy[dept.parentDepartmentId!] ??= [];
        hierarchy[dept.parentDepartmentId!]!.add(dept);
      }
    }
    
    return hierarchy;
  }

  /// Get all organizations
  List<Organization> getAllOrganizations() {
    return List.from(_organizations);
  }

  /// Check user permission
  bool hasPermission(String userId, String resource, String action) {
    final user = getUserById(userId);
    if (user == null) return false;

    // Check direct permissions
    for (final permissionId in user.permissions) {
      final permission = _permissions.firstWhere(
        (p) => p.id == permissionId,
        orElse: () => Permission(
          id: '',
          name: '',
          description: '',
          resource: '',
          action: '',
          createdAt: DateTime.now(),
        ),
      );
      
      if (permission.resource == resource && 
          (permission.action == action || permission.action == 'manage')) {
        return true;
      }
    }

    // Check group permissions
    for (final groupId in user.userGroups) {
      final group = _userGroups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => UserGroup(
          id: '',
          name: '',
          description: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      for (final permissionId in group.permissions) {
        final permission = _permissions.firstWhere(
          (p) => p.id == permissionId,
          orElse: () => Permission(
            id: '',
            name: '',
            description: '',
            resource: '',
            action: '',
            createdAt: DateTime.now(),
          ),
        );
        
        if (permission.resource == resource && 
            (permission.action == action || permission.action == 'manage')) {
          return true;
        }
      }
    }

    // Check role permissions
    final role = _roles.firstWhere(
      (r) => r.name == user.role,
      orElse: () => Role(
        id: '',
        name: '',
        description: '',
        permissions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    for (final permissionId in role.permissions) {
      final permission = _permissions.firstWhere(
        (p) => p.id == permissionId,
        orElse: () => Permission(
          id: '',
          name: '',
          description: '',
          resource: '',
          action: '',
          createdAt: DateTime.now(),
        ),
      );
      
      if (permission.resource == resource && 
          (permission.action == action || permission.action == 'manage')) {
        return true;
      }
    }

    return false;
  }

  /// Get user statistics
  Map<String, dynamic> getUserStatistics() {
    final roleStats = <String, int>{};
    final departmentStats = <String, int>{};
    final groupStats = <String, int>{};
    
    for (final user in _users) {
      roleStats[user.role] = (roleStats[user.role] ?? 0) + 1;
      if (user.departmentId != null) {
        departmentStats[user.departmentId!] = (departmentStats[user.departmentId!] ?? 0) + 1;
      }
      for (final groupId in user.userGroups) {
        groupStats[groupId] = (groupStats[groupId] ?? 0) + 1;
      }
    }

    return {
      'total_users': _totalUsers,
      'active_users': _activeUsers,
      'inactive_users': _totalUsers - _activeUsers,
      'total_groups': _totalGroups,
      'total_departments': _totalDepartments,
      'total_organizations': _organizations.length,
      'role_distribution': roleStats,
      'department_distribution': departmentStats,
      'group_distribution': groupStats,
    };
  }

  /// Search users
  List<EnterpriseUser> searchUsers(String query) {
    if (query.isEmpty) return _users;
    
    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) {
      return user.firstName.toLowerCase().contains(lowercaseQuery) ||
             user.lastName.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             user.jobTitle?.toLowerCase().contains(lowercaseQuery) == true ||
             user.role.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }

  /// Copy with method for EnterpriseUser
  EnterpriseUser _copyUserWith({
    required EnterpriseUser user,
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImage,
    String? role,
    List<String>? permissions,
    List<String>? userGroups,
    String? departmentId,
    String? organizationId,
    String? managerId,
    String? employeeId,
    String? jobTitle,
    String? location,
    String? timezone,
    String? language,
    bool? isActive,
    bool? isVerified,
    DateTime? lastLoginAt,
    DateTime? passwordChangedAt,
    DateTime? accountExpiresAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnterpriseUser(
      id: id ?? user.id,
      email: email ?? user.email,
      firstName: firstName ?? user.firstName,
      lastName: lastName ?? user.lastName,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      profileImage: profileImage ?? user.profileImage,
      role: role ?? user.role,
      permissions: permissions ?? user.permissions,
      userGroups: userGroups ?? user.userGroups,
      departmentId: departmentId ?? user.departmentId,
      organizationId: organizationId ?? user.organizationId,
      managerId: managerId ?? user.managerId,
      employeeId: employeeId ?? user.employeeId,
      jobTitle: jobTitle ?? user.jobTitle,
      location: location ?? user.location,
      timezone: timezone ?? user.timezone,
      language: language ?? user.language,
      isActive: isActive ?? user.isActive,
      isVerified: isVerified ?? user.isVerified,
      lastLoginAt: lastLoginAt ?? user.lastLoginAt,
      passwordChangedAt: passwordChangedAt ?? user.passwordChangedAt,
      accountExpiresAt: accountExpiresAt ?? user.accountExpiresAt,
      preferences: preferences ?? user.preferences,
      metadata: metadata ?? user.metadata,
      createdAt: createdAt ?? user.createdAt,
      updatedAt: updatedAt ?? user.updatedAt,
    );
  }
}