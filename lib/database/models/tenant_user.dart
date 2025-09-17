class TenantUser {
  final String id;
  final String tenantId;
  final String userId;
  final String role; // admin, user, etc.
  final List<String> permissions;
  final bool isActive;
  final DateTime lastLogin;
  final String invitationStatus; // pending, accepted, etc.
  final DateTime? invitationSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TenantUser({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.lastLogin,
    required this.invitationStatus,
    this.invitationSentAt,
    required this.createdAt,
    required this.updatedAt,
  });
class TenantUser {
  TenantUser({
    required this.userId,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
  });
  final String userId;
  final String tenantId;
  final String email;
  final String role;
  final DateTime createdAt;
  DateTime? lastLoginAt;
  bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tenantId': tenantId,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory TenantUser.fromMap(Map<String, dynamic> map) {
    return TenantUser(
      userId: map['userId'],
      tenantId: map['tenantId'],
      email: map['email'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.parse(map['lastLoginAt']) : null,
      isActive: map['isActive'],
    );
  }
}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'userId': userId,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'lastLogin': lastLogin.toIso8601String(),
      'invitationStatus': invitationStatus,
      'invitationSentAt': invitationSentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TenantUser.fromMap(Map<String, dynamic> map) {
    return TenantUser(
      id: map['id'],
      tenantId: map['tenantId'],
      userId: map['userId'],
      role: map['role'],
      permissions: List<String>.from(map['permissions']),
      isActive: map['isActive'],
      lastLogin: DateTime.parse(map['lastLogin']),
      invitationStatus: map['invitationStatus'],
      invitationSentAt: map['invitationSentAt'] != null ? DateTime.parse(map['invitationSentAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
