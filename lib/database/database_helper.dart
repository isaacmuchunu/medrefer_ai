import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dao/pharmacy_dao.dart';
import 'dao/user_dao.dart';
import 'dao/audit_log_dao.dart';
import 'dao/feature_flag_dao.dart';
import 'dao/notification_dao.dart';
import 'dao/rbac_dao.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'medrefer_ai.db');
    
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create patients table
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        medical_record_number TEXT UNIQUE NOT NULL,
        date_of_birth TEXT NOT NULL,
        gender TEXT NOT NULL,
        blood_type TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        profile_image_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create specialists table
    await db.execute('''
      CREATE TABLE specialists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        credentials TEXT,
        specialty TEXT NOT NULL,
        hospital TEXT NOT NULL,
        profile_image_url TEXT,
        is_available INTEGER DEFAULT 1,
        rating REAL DEFAULT 0.0,
        distance TEXT,
        languages TEXT, -- JSON array as string
        insurance TEXT, -- JSON array as string
        hospital_network TEXT,
        success_rate REAL DEFAULT 0.0,
        match_reason TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create referrals table
    await db.execute('''
      CREATE TABLE referrals (
        id TEXT PRIMARY KEY,
        tracking_number TEXT UNIQUE NOT NULL,
        patient_id TEXT NOT NULL,
        specialist_id TEXT,
        status TEXT NOT NULL DEFAULT 'Pending',
        urgency TEXT NOT NULL,
        symptoms_description TEXT,
        ai_confidence REAL DEFAULT 0.0,
        estimated_time TEXT,
        department TEXT,
        referring_physician TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (specialist_id) REFERENCES specialists (id) ON DELETE SET NULL
      )
    ''');

    // Create medical_history table
    await db.execute('''
      CREATE TABLE medical_history (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        type TEXT NOT NULL, -- Surgery, Diagnosis, Treatment, Procedure
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        provider TEXT,
        location TEXT,
        icd10_code TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create medications table
    await db.execute('''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        type TEXT,
        status TEXT DEFAULT 'Active',
        start_date TEXT,
        end_date TEXT,
        prescribed_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create conditions table
    await db.execute('''
      CREATE TABLE conditions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        name TEXT NOT NULL,
        severity TEXT,
        description TEXT,
        diagnosed_date TEXT,
        diagnosed_by TEXT,
        icd10_code TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_avatar TEXT,
        content TEXT NOT NULL,
        message_type TEXT DEFAULT 'text', -- text, voice, attachment, referral_context
        attachments TEXT, -- JSON array as string
        referral_id TEXT,
        timestamp TEXT NOT NULL,
        status TEXT DEFAULT 'sent', -- sent, delivered, read
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (referral_id) REFERENCES referrals (id) ON DELETE SET NULL
      )
    ''');

    // Create documents table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        referral_id TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL, -- Lab, Image, Prescription, PDF
        category TEXT NOT NULL,
        file_path TEXT,
        file_url TEXT,
        thumbnail_url TEXT,
        file_size INTEGER,
        upload_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (referral_id) REFERENCES referrals (id) ON DELETE CASCADE
      )
    ''');

    // Create emergency_contacts table
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        name TEXT NOT NULL,
        relationship TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        is_primary INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create vital_statistics table
    await db.execute('''
      CREATE TABLE vital_statistics (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        blood_pressure TEXT,
        heart_rate TEXT,
        temperature TEXT,
        oxygen_saturation TEXT,
        weight REAL,
        height REAL,
        bmi REAL,
        recorded_date TEXT NOT NULL,
        recorded_by TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create app_settings table
    await db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create consents table
    await db.execute('''
      CREATE TABLE consents (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        consent_type TEXT NOT NULL,
        status TEXT NOT NULL,
        granted_by TEXT,
        granted_at TEXT NOT NULL,
        expires_at TEXT,
        scope TEXT,
        revocation_reason TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create care_plans table
    await db.execute('''
      CREATE TABLE care_plans (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        goals TEXT,
        interventions TEXT,
        assigned_to TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Create sync_queue table for offline operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
        data TEXT, -- JSON data for the operation
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create pharmacy tables
    await PharmacyDAO.createTables(db);

    // Create user tables
    await UserDAO.createTables(db);

    // Create enterprise tables
    await AuditLogDAO.createTables(db);
    await FeatureFlagDAO.createTables(db);
    await NotificationDAO.createTables(db);
    await RBACDAO.createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add comprehensive indexes for performance optimization
      await _createPerformanceIndexes(db);
    }
    
    if (oldVersion < 3) {
      // Add additional indexes for new features
      await _createAdditionalIndexes(db);
    }

    if (oldVersion < 4) {
      // Enterprise tables
      await AuditLogDAO.createTables(db);
      await FeatureFlagDAO.createTables(db);
      await NotificationDAO.createTables(db);
      await RBACDAO.createTables(db);
    }

    if (oldVersion < 5) {
      // New consent and care plan tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS consents (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          consent_type TEXT NOT NULL,
          status TEXT NOT NULL,
          granted_by TEXT,
          granted_at TEXT NOT NULL,
          expires_at TEXT,
          scope TEXT,
          revocation_reason TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS care_plans (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          status TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          goals TEXT,
          interventions TEXT,
          assigned_to TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
        )
      ''');

      // Indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_consents_patient_id ON consents(patient_id);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_consents_status ON consents(status);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_care_plans_patient_id ON care_plans(patient_id);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_care_plans_status ON care_plans(status);');
    }
  }

  /// Create performance indexes
  Future<void> _createPerformanceIndexes(Database db) async {
    // Patient-related indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_medical_record_number ON patients(medical_record_number);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_email ON patients(email);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_phone ON patients(phone);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_patients_created_at ON patients(created_at);');
    
    // Referral-related indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_patient_id ON referrals(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_specialist_id ON referrals(specialist_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_urgency ON referrals(urgency);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_tracking_number ON referrals(tracking_number);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals(created_at);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_department ON referrals(department);');
    
    // Medical history indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medical_history_patient_id ON medical_history(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medical_history_type ON medical_history(type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medical_history_date ON medical_history(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medical_history_icd10_code ON medical_history(icd10_code);');
    
    // Medication indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_patient_id ON medications(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(name);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_status ON medications(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_prescribed_by ON medications(prescribed_by);');
    
    // Condition indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_patient_id ON conditions(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_name ON conditions(name);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_severity ON conditions(severity);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_is_active ON conditions(is_active);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_icd10_code ON conditions(icd10_code);');
    
    // Document indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_patient_id ON documents(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_referral_id ON documents(referral_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_upload_date ON documents(upload_date);');
    
    // Message indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_referral_id ON messages(referral_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);');
    
    // Emergency contact indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_emergency_contacts_patient_id ON emergency_contacts(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_emergency_contacts_is_primary ON emergency_contacts(is_primary);');
    
    // Vital statistics indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vital_statistics_patient_id ON vital_statistics(patient_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vital_statistics_recorded_date ON vital_statistics(recorded_date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vital_statistics_recorded_by ON vital_statistics(recorded_by);');
    
    // Specialist indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_specialists_specialty ON specialists(specialty);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_specialists_hospital ON specialists(hospital);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_specialists_is_available ON specialists(is_available);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_specialists_rating ON specialists(rating);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_specialists_latitude_longitude ON specialists(latitude, longitude);');
  }

  /// Create additional indexes for new features
  Future<void> _createAdditionalIndexes(Database db) async {
    // Composite indexes for complex queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_patient_status ON referrals(patient_id, status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_referrals_specialist_status ON referrals(specialist_id, status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medical_history_patient_type ON medical_history(patient_id, type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medications_patient_status ON medications(patient_id, status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_conditions_patient_active ON conditions(patient_id, is_active);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_documents_patient_type ON documents(patient_id, type);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_conversation_timestamp ON messages(conversation_id, timestamp);');
    
    // Full-text search indexes (if supported)
    try {
      await db.execute('CREATE VIRTUAL TABLE IF NOT EXISTS patients_fts USING fts5(name, medical_record_number, email, phone, content="patients", content_rowid="rowid");');
      await db.execute('CREATE VIRTUAL TABLE IF NOT EXISTS specialists_fts USING fts5(name, specialty, hospital, content="specialists", content_rowid="rowid");');
    } catch (e) {
      // FTS5 might not be available on all platforms
      debugPrint('FTS5 not available: $e');
    }
  }

  // Generic CRUD operations
  Future<String> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    data['created_at'] = now;
    data['updated_at'] = now;
    
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    return data['id'];
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    final results = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    
    return await db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Batch operations for better performance
  Future<void> batchInsert(String table, List<Map<String, dynamic>> dataList) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (var data in dataList) {
      data['created_at'] = now;
      data['updated_at'] = now;
      batch.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  // Search functionality
  Future<List<Map<String, dynamic>>> search(
    String table,
    String searchColumn,
    String searchTerm, {
    String? additionalWhere,
    List<dynamic>? additionalWhereArgs,
  }) async {
    final db = await database;
    String where = '$searchColumn LIKE ?';
    List<dynamic> whereArgs = ['%$searchTerm%'];
    
    if (additionalWhere != null) {
      where += ' AND $additionalWhere';
      whereArgs.addAll(additionalWhereArgs ?? []);
    }
    
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  // Database maintenance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  Future<int> getTableCount(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Count method with optional where clause
  Future<int> getCount(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    String query = 'SELECT COUNT(*) as count FROM $table';
    if (where != null) {
      query += ' WHERE $where';
    }
    final result = await db.rawQuery(query, whereArgs);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Advanced query methods for better performance
  Future<List<Map<String, dynamic>>> queryWithJoins({
    required String baseTable,
    required List<String> joinTables,
    required List<String> selectColumns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    
    String query = 'SELECT ${selectColumns.join(', ')} FROM $baseTable';
    
    for (String join in joinTables) {
      query += ' $join';
    }
    
    if (where != null) {
      query += ' WHERE $where';
    }
    
    if (orderBy != null) {
      query += ' ORDER BY $orderBy';
    }
    
    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }
    
    return await db.rawQuery(query, whereArgs);
  }

  // Full-text search
  Future<List<Map<String, dynamic>>> fullTextSearch({
    required String table,
    required String searchTerm,
    List<String>? columns,
    int? limit,
  }) async {
    final db = await database;
    
    try {
      // Try FTS5 first
      final ftsTable = '${table}_fts';
      String query = 'SELECT * FROM $ftsTable WHERE $ftsTable MATCH ?';
      
      if (limit != null) {
        query += ' LIMIT $limit';
      }
      
      return await db.rawQuery(query, [searchTerm]);
    } catch (e) {
      // Fallback to LIKE search
      final searchColumns = columns ?? ['name', 'description'];
      final likeConditions = searchColumns.map((col) => '$col LIKE ?').join(' OR ');
      final searchArgs = List.filled(searchColumns.length, '%$searchTerm%');
      
      String query = 'SELECT * FROM $table WHERE $likeConditions';
      
      if (limit != null) {
        query += ' LIMIT $limit';
      }
      
      return await db.rawQuery(query, searchArgs);
    }
  }

  // Paginated query with total count
  Future<Map<String, dynamic>> paginatedQuery({
    required String table,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;
    
    // Get total count
    final totalCount = await getCount(table, where: where, whereArgs: whereArgs);
    
    // Get paginated data
    final data = await query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: pageSize,
      offset: offset,
    );
    
    return {
      'data': data,
      'totalCount': totalCount,
      'page': page,
      'pageSize': pageSize,
      'totalPages': (totalCount / pageSize).ceil(),
      'hasNextPage': offset + pageSize < totalCount,
      'hasPreviousPage': page > 1,
    };
  }

  // Batch operations with transaction
  Future<void> batchOperation(List<BatchOperation> operations) async {
    final db = await database;
    final batch = db.batch();
    
    for (final operation in operations) {
      switch (operation.type) {
        case BatchOperationType.insert:
          batch.insert(operation.table, operation.data, conflictAlgorithm: ConflictAlgorithm.replace);
          break;
        case BatchOperationType.update:
          batch.update(operation.table, operation.data, where: operation.where, whereArgs: operation.whereArgs);
          break;
        case BatchOperationType.delete:
          batch.delete(operation.table, where: operation.where, whereArgs: operation.whereArgs);
          break;
      }
    }
    
    await batch.commit(noResult: true);
  }

  // Database maintenance and optimization
  Future<void> optimizeDatabase() async {
    final db = await database;
    
    // Analyze tables for query optimization
    await db.execute('ANALYZE');
    
    // Vacuum to reclaim space
    await db.execute('VACUUM');
    
    // Update statistics
    await db.execute('UPDATE sqlite_stat1 SET stat = (SELECT COUNT(*) FROM patients) WHERE tbl = "patients"');
    await db.execute('UPDATE sqlite_stat1 SET stat = (SELECT COUNT(*) FROM referrals) WHERE tbl = "referrals"');
    await db.execute('UPDATE sqlite_stat1 SET stat = (SELECT COUNT(*) FROM specialists) WHERE tbl = "specialists"');
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final tables = ['patients', 'referrals', 'specialists', 'medical_history', 'medications', 'conditions', 'documents', 'messages'];
    final stats = <String, int>{};
    
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }
    
    // Get database size
    final dbPath = db.path;
    final dbFile = File(dbPath);
    final dbSize = await dbFile.length();
    
    return {
      'tableCounts': stats,
      'databaseSize': dbSize,
      'databaseSizeMB': (dbSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  // Backup database
  Future<String> backupDatabase() async {
    final db = await database;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '${db.path}.backup.$timestamp';
    
    final sourceFile = File(db.path);
    final backupFile = File(backupPath);
    
    await sourceFile.copy(backupFile.path);
    
    return backupPath;
  }

  // Restore database from backup
  Future<void> restoreDatabase(String backupPath) async {
    final db = await database;
    await db.close();
    
    final sourceFile = File(backupPath);
    final targetFile = File(db.path);
    
    await sourceFile.copy(targetFile.path);
    
    // Reopen database
    _database = await _initDatabase();
  }
}

// Batch operation model
class BatchOperation {
  final BatchOperationType type;
  final String table;
  final Map<String, dynamic>? data;
  final String? where;
  final List<dynamic>? whereArgs;

  BatchOperation({
    required this.type,
    required this.table,
    this.data,
    this.where,
    this.whereArgs,
  });
}

enum BatchOperationType {
  insert,
  update,
  delete,
}
