class DatabasePartition {
  final String id;
  final String tenantId;
  final String partitionType; // dedicated, shared
  final String connectionString;
  final int maxConnections;
  final double storageLimit; // in GB
  final double currentUsage; // in GB
  final int maxTables;
  final bool backupEnabled;
  final String backupFrequency; // daily, weekly, etc.
  final int backupRetentionDays;
  final DateTime lastBackupAt;
  final String status; // active, suspended, maintenance
  final DateTime createdAt;
  final DateTime updatedAt;
class DatabasePartition {
  DatabasePartition({
    required this.tenantId,
    required this.partitionName,
    required this.strategy,
    required this.connectionString,
    required this.isActive,
    required this.createdAt,
  });
  final String tenantId;
  final String partitionName;
  final PartitionStrategy strategy;
  final String connectionString;
  bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'partitionName': partitionName,
      'strategy': strategy.toString(),
      'connectionString': connectionString,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DatabasePartition.fromMap(Map<String, dynamic> map) {
    return DatabasePartition(
      tenantId: map['tenantId'],
      partitionName: map['partitionName'],
      strategy: PartitionStrategy.values.firstWhere(
          (e) => e.toString() == map['strategy']),
      connectionString: map['connectionString'],
      isActive: map['isActive'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

enum PartitionStrategy { schema, table, database }
  DatabasePartition({
    required this.id,
    required this.tenantId,
    required this.partitionType,
    required this.connectionString,
    required this.maxConnections,
    required this.storageLimit,
    required this.currentUsage,
    required this.maxTables,
    required this.backupEnabled,
    required this.backupFrequency,
    required this.backupRetentionDays,
    required this.lastBackupAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'partitionType': partitionType,
      'connectionString': connectionString,
      'maxConnections': maxConnections,
      'storageLimit': storageLimit,
      'currentUsage': currentUsage,
      'maxTables': maxTables,
      'backupEnabled': backupEnabled,
      'backupFrequency': backupFrequency,
      'backupRetentionDays': backupRetentionDays,
      'lastBackupAt': lastBackupAt.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DatabasePartition.fromMap(Map<String, dynamic> map) {
    return DatabasePartition(
      id: map['id'],
      tenantId: map['tenantId'],
      partitionType: map['partitionType'],
      connectionString: map['connectionString'],
      maxConnections: map['maxConnections'],
      storageLimit: map['storageLimit'],
      currentUsage: map['currentUsage'],
      maxTables: map['maxTables'],
      backupEnabled: map['backupEnabled'],
      backupFrequency: map['backupFrequency'],
      backupRetentionDays: map['backupRetentionDays'],
      lastBackupAt: DateTime.parse(map['lastBackupAt']),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
