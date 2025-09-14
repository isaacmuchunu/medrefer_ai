import 'package:medrefer_ai/core/app_export.dart';

/// Enhanced User model with enterprise features
class EnterpriseUser extends BaseModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? profileImage;
  final String role;
  final List<String> permissions;
  final List<String> userGroups;
  final String? departmentId;
  final String? organizationId;
  final String? managerId;
  final String? employeeId;
  final String? jobTitle;
  final String? location;
  final String? timezone;
  final String language;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final DateTime? passwordChangedAt;
  final DateTime? accountExpiresAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnterpriseUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.profileImage,
    required this.role,
    this.permissions = const [],
    this.userGroups = const [],
    this.departmentId,
    this.organizationId,
    this.managerId,
    this.employeeId,
    this.jobTitle,
    this.location,
    this.timezone,
    this.language = 'en',
    this.isActive = true,
    this.isVerified = false,
    this.lastLoginAt,
    this.passwordChangedAt,
    this.accountExpiresAt,
    this.preferences = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'role': role,
      'permissions': jsonEncode(permissions),
      'user_groups': jsonEncode(userGroups),
      'department_id': departmentId,
      'organization_id': organizationId,
      'manager_id': managerId,
      'employee_id': employeeId,
      'job_title': jobTitle,
      'location': location,
      'timezone': timezone,
      'language': language,
      'is_active': isActive ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'password_changed_at': passwordChangedAt?.toIso8601String(),
      'account_expires_at': accountExpiresAt?.toIso8601String(),
      'preferences': jsonEncode(preferences),
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory EnterpriseUser.fromMap(Map<String, dynamic> map) {
    return EnterpriseUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      phoneNumber: map['phone_number'],
      profileImage: map['profile_image'],
      role: map['role'] ?? 'user',
      permissions: map['permissions'] != null 
          ? List<String>.from(jsonDecode(map['permissions'])) 
          : [],
      userGroups: map['user_groups'] != null 
          ? List<String>.from(jsonDecode(map['user_groups'])) 
          : [],
      departmentId: map['department_id'],
      organizationId: map['organization_id'],
      managerId: map['manager_id'],
      employeeId: map['employee_id'],
      jobTitle: map['job_title'],
      location: map['location'],
      timezone: map['timezone'],
      language: map['language'] ?? 'en',
      isActive: (map['is_active'] ?? 1) == 1,
      isVerified: (map['is_verified'] ?? 0) == 1,
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
      passwordChangedAt: map['password_changed_at'] != null 
          ? DateTime.parse(map['password_changed_at']) 
          : null,
      accountExpiresAt: map['account_expires_at'] != null 
          ? DateTime.parse(map['account_expires_at']) 
          : null,
      preferences: map['preferences'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['preferences'])) 
          : {},
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// User Group model for organizing users
class UserGroup extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String? organizationId;
  final String? departmentId;
  final List<String> permissions;
  final List<String> memberIds;
  final String? groupManagerId;
  final String color;
  final String icon;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGroup({
    required this.id,
    required this.name,
    required this.description,
    this.organizationId,
    this.departmentId,
    this.permissions = const [],
    this.memberIds = const [],
    this.groupManagerId,
    this.color = '#3B82F6',
    this.icon = 'group',
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'organization_id': organizationId,
      'department_id': departmentId,
      'permissions': jsonEncode(permissions),
      'member_ids': jsonEncode(memberIds),
      'group_manager_id': groupManagerId,
      'color': color,
      'icon': icon,
      'is_active': isActive ? 1 : 0,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserGroup.fromMap(Map<String, dynamic> map) {
    return UserGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      organizationId: map['organization_id'],
      departmentId: map['department_id'],
      permissions: map['permissions'] != null 
          ? List<String>.from(jsonDecode(map['permissions'])) 
          : [],
      memberIds: map['member_ids'] != null 
          ? List<String>.from(jsonDecode(map['member_ids'])) 
          : [],
      groupManagerId: map['group_manager_id'],
      color: map['color'] ?? '#3B82F6',
      icon: map['icon'] ?? 'group',
      isActive: (map['is_active'] ?? 1) == 1,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Permission model for fine-grained access control
class Permission extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String resource; // patients, referrals, appointments, etc.
  final String action; // create, read, update, delete, manage
  final String? condition; // additional conditions for permission
  final bool isSystemPermission;
  final String? organizationId;
  final DateTime createdAt;

  Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.resource,
    required this.action,
    this.condition,
    this.isSystemPermission = false,
    this.organizationId,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'resource': resource,
      'action': action,
      'condition': condition,
      'is_system_permission': isSystemPermission ? 1 : 0,
      'organization_id': organizationId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      resource: map['resource'] ?? '',
      action: map['action'] ?? '',
      condition: map['condition'],
      isSystemPermission: (map['is_system_permission'] ?? 0) == 1,
      organizationId: map['organization_id'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Role model for role-based access control
class Role extends BaseModel {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final String? organizationId;
  final bool isSystemRole;
  final int level; // hierarchy level (1 = highest)
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.organizationId,
    this.isSystemRole = false,
    this.level = 1,
    this.color = '#6B7280',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': jsonEncode(permissions),
      'organization_id': organizationId,
      'is_system_role': isSystemRole ? 1 : 0,
      'level': level,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      permissions: map['permissions'] != null 
          ? List<String>.from(jsonDecode(map['permissions'])) 
          : [],
      organizationId: map['organization_id'],
      isSystemRole: (map['is_system_role'] ?? 0) == 1,
      level: map['level'] ?? 1,
      color: map['color'] ?? '#6B7280',
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Department model for organizational structure
class Department extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String? organizationId;
  final String? parentDepartmentId;
  final String? departmentHeadId;
  final String color;
  final String icon;
  final List<String> subDepartmentIds;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.description,
    this.organizationId,
    this.parentDepartmentId,
    this.departmentHeadId,
    this.color = '#8B5CF6',
    this.icon = 'business',
    this.subDepartmentIds = const [],
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'organization_id': organizationId,
      'parent_department_id': parentDepartmentId,
      'department_head_id': departmentHeadId,
      'color': color,
      'icon': icon,
      'sub_department_ids': jsonEncode(subDepartmentIds),
      'is_active': isActive ? 1 : 0,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      organizationId: map['organization_id'],
      parentDepartmentId: map['parent_department_id'],
      departmentHeadId: map['department_head_id'],
      color: map['color'] ?? '#8B5CF6',
      icon: map['icon'] ?? 'business',
      subDepartmentIds: map['sub_department_ids'] != null 
          ? List<String>.from(jsonDecode(map['sub_department_ids'])) 
          : [],
      isActive: (map['is_active'] ?? 1) == 1,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Organization model for multi-tenant support
class Organization extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String? logo;
  final String? website;
  final String? email;
  final String? phone;
  final String? address;
  final String? timezone;
  final String? language;
  final String? currency;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.description,
    this.logo,
    this.website,
    this.email,
    this.phone,
    this.address,
    this.timezone = 'UTC',
    this.language = 'en',
    this.currency = 'USD',
    this.settings = const {},
    this.metadata = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'website': website,
      'email': email,
      'phone': phone,
      'address': address,
      'timezone': timezone,
      'language': language,
      'currency': currency,
      'settings': jsonEncode(settings),
      'metadata': jsonEncode(metadata),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      logo: map['logo'],
      website: map['website'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      timezone: map['timezone'] ?? 'UTC',
      language: map['language'] ?? 'en',
      currency: map['currency'] ?? 'USD',
      settings: map['settings'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['settings'])) 
          : {},
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// User session model for tracking active sessions
class UserSession extends BaseModel {
  final String id;
  final String userId;
  final String sessionToken;
  final String? deviceId;
  final String? deviceName;
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final DateTime loginAt;
  final DateTime? lastActivityAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  UserSession({
    required this.id,
    required this.userId,
    required this.sessionToken,
    this.deviceId,
    this.deviceName,
    this.ipAddress,
    this.userAgent,
    this.location,
    required this.loginAt,
    this.lastActivityAt,
    this.expiresAt,
    this.isActive = true,
    this.metadata = const {},
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'session_token': sessionToken,
      'device_id': deviceId,
      'device_name': deviceName,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'login_at': loginAt.toIso8601String(),
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'metadata': jsonEncode(metadata),
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      sessionToken: map['session_token'] ?? '',
      deviceId: map['device_id'],
      deviceName: map['device_name'],
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      location: map['location'],
      loginAt: DateTime.parse(map['login_at'] ?? DateTime.now().toIso8601String()),
      lastActivityAt: map['last_activity_at'] != null 
          ? DateTime.parse(map['last_activity_at']) 
          : null,
      expiresAt: map['expires_at'] != null 
          ? DateTime.parse(map['expires_at']) 
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
    );
  }
}