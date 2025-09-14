import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dao/pharmacy_dao.dart';
import 'dao/user_dao.dart';

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
      version: 2,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add indexes for performance optimization
      await db.execute('CREATE INDEX idx_referrals_patient_id ON referrals(patient_id);');
      await db.execute('CREATE INDEX idx_medical_history_patient_id ON medical_history(patient_id);');
      await db.execute('CREATE INDEX idx_medications_patient_id ON medications(patient_id);');
      await db.execute('CREATE INDEX idx_conditions_patient_id ON conditions(patient_id);');
      await db.execute('CREATE INDEX idx_documents_patient_id ON documents(patient_id);');
      await db.execute('CREATE INDEX idx_emergency_contacts_patient_id ON emergency_contacts(patient_id);');
      await db.execute('CREATE INDEX idx_vital_statistics_patient_id ON vital_statistics(patient_id);');
      await db.execute('CREATE INDEX idx_referrals_specialist_id ON referrals(specialist_id);');
      await db.execute('CREATE INDEX idx_documents_referral_id ON documents(referral_id);');
      await db.execute('CREATE INDEX idx_messages_referral_id ON messages(referral_id);');
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
}
