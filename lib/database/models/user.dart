import 'base_model.dart';

class User extends BaseModel {
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final UserStatus status;
  final String? profileImageUrl;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? department;
  final String? specialization;
  final String? licenseNumber;
  final Map<String, dynamic> preferences;

  User({
    required String id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.status = UserStatus.active,
    this.profileImageUrl,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.department,
    this.specialization,
    this.licenseNumber,
    this.preferences = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'],
      role: UserRole.values.firstWhere(
        (r) => r.name == (map['role'] ?? 'patient'),
        orElse: () => UserRole.patient,
      ),
      status: UserStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'active'),
        orElse: () => UserStatus.active,
      ),
      profileImageUrl: map['profile_image_url'],
      lastLoginAt: map['last_login_at'] != null 
          ? BaseModel.parseDateTime(map['last_login_at'])
          : null,
      isEmailVerified: (map['is_email_verified'] ?? 0) == 1,
      isPhoneVerified: (map['is_phone_verified'] ?? 0) == 1,
      department: map['department'],
      specialization: map['specialization'],
      licenseNumber: map['license_number'],
      preferences: map['preferences'] != null 
          ? Map<String, dynamic>.from(map['preferences'] is String 
              ? {} // Handle string case
              : map['preferences'])
          : {},
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role.name,
      'status': status.name,
      'profile_image_url': profileImageUrl,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'is_email_verified': isEmailVerified ? 1 : 0,
      'is_phone_verified': isPhoneVerified ? 1 : 0,
      'department': department,
      'specialization': specialization,
      'license_number': licenseNumber,
      'preferences': preferences.isNotEmpty ? preferences : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    UserStatus? status,
    String? profileImageUrl,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? department,
    String? specialization,
    String? licenseNumber,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      department: department ?? this.department,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName';
  
  String get displayName {
    switch (role) {
      case UserRole.doctor:
        return 'Dr. $fullName';
      case UserRole.specialist:
        return 'Dr. $fullName';
      default:
        return fullName;
    }
  }

  bool get isActive => status == UserStatus.active;
  bool get isDoctor => role == UserRole.doctor || role == UserRole.specialist;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get canPrescribe => role == UserRole.doctor || role == UserRole.specialist;

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, role: ${role.name})';
  }
}

/// User roles in the system
enum UserRole {
  patient,
  doctor,
  specialist,
  nurse,
  pharmacist,
  admin,
  superAdmin,
}

/// User status
enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

/// User authentication model
class UserAuth extends BaseModel {
  final String userId;
  final String passwordHash;
  final String? salt;
  final DateTime? lastPasswordChange;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final bool requiresPasswordChange;
  final String? resetToken;
  final DateTime? resetTokenExpiry;

  UserAuth({
    required String id,
    required this.userId,
    required this.passwordHash,
    this.salt,
    this.lastPasswordChange,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.requiresPasswordChange = false,
    this.resetToken,
    this.resetTokenExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

  factory UserAuth.fromMap(Map<String, dynamic> map) {
    return UserAuth(
      id: map['id'],
      userId: map['user_id'],
      passwordHash: map['password_hash'],
      salt: map['salt'],
      lastPasswordChange: map['last_password_change'] != null
          ? BaseModel.parseDateTime(map['last_password_change'])
          : null,
      failedLoginAttempts: map['failed_login_attempts'] ?? 0,
      lockedUntil: map['locked_until'] != null
          ? BaseModel.parseDateTime(map['locked_until'])
          : null,
      requiresPasswordChange: (map['requires_password_change'] ?? 0) == 1,
      resetToken: map['reset_token'],
      resetTokenExpiry: map['reset_token_expiry'] != null
          ? BaseModel.parseDateTime(map['reset_token_expiry'])
          : null,
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'password_hash': passwordHash,
      'salt': salt,
      'last_password_change': lastPasswordChange?.toIso8601String(),
      'failed_login_attempts': failedLoginAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
      'requires_password_change': requiresPasswordChange ? 1 : 0,
      'reset_token': resetToken,
      'reset_token_expiry': resetTokenExpiry?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserAuth copyWith({
    String? passwordHash,
    String? salt,
    DateTime? lastPasswordChange,
    int? failedLoginAttempts,
    DateTime? lockedUntil,
    bool? requiresPasswordChange,
    String? resetToken,
    DateTime? resetTokenExpiry,
  }) {
    return UserAuth(
      id: id,
      userId: userId,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      requiresPasswordChange: requiresPasswordChange ?? this.requiresPasswordChange,
      resetToken: resetToken ?? this.resetToken,
      resetTokenExpiry: resetTokenExpiry ?? this.resetTokenExpiry,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool get isLocked {
    return lockedUntil != null && DateTime.now().isBefore(lockedUntil!);
  }

  bool get isResetTokenValid {
    return resetToken != null && 
           resetTokenExpiry != null && 
           DateTime.now().isBefore(resetTokenExpiry!);
  }
}
