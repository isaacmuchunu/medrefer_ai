import 'base_model.dart';

class Role extends BaseModel {
  final String name;
  final String? description;

  Role({
    super.id,
    required this.name,
    this.description,
    super.createdAt,
    super.updatedAt,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'name': name,
      'description': description,
    });
    return map;
  }
}

class PermissionModel extends BaseModel {
  final String key;
  final String? description;

  PermissionModel({
    super.id,
    required this.key,
    this.description,
    super.createdAt,
    super.updatedAt,
  });

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    return PermissionModel(
      id: map['id'],
      key: map['key'],
      description: map['description'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'key': key,
      'description': description,
    });
    return map;
  }
}

class RolePermission extends BaseModel {
  final String roleId;
  final String permissionId;

  RolePermission({
    super.id,
    required this.roleId,
    required this.permissionId,
    super.createdAt,
    super.updatedAt,
  });

  factory RolePermission.fromMap(Map<String, dynamic> map) {
    return RolePermission(
      id: map['id'],
      roleId: map['role_id'],
      permissionId: map['permission_id'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'role_id': roleId,
      'permission_id': permissionId,
    });
    return map;
  }
}

