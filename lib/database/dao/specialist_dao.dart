import '../database_helper.dart';
import '../models/models.dart';

class SpecialistDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String tableName = 'specialists';

  // Create
  Future<String> createSpecialist(Specialist specialist) async {
    try {
      return await _dbHelper.insert(tableName, specialist.toMap());
    } catch (e) {
      throw Exception('Failed to create specialist: $e');
    }
  }

  // Read
  Future<List<Specialist>> getAllSpecialists() async {
    try {
      final maps = await _dbHelper.query(tableName, orderBy: 'name ASC');
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get specialists: $e');
    }
  }

  Future<Specialist?> getSpecialistById(String id) async {
    try {
      final map = await _dbHelper.queryById(tableName, id);
      return map != null ? Specialist.fromMap(map) : null;
    } catch (e) {
      throw Exception('Failed to get specialist: $e');
    }
  }

  Future<List<Specialist>> getSpecialistsBySpecialty(String specialty) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'specialty = ?',
        whereArgs: [specialty],
        orderBy: 'rating DESC, success_rate DESC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get specialists by specialty: $e');
    }
  }

  Future<List<Specialist>> getAvailableSpecialists() async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'is_available = ?',
        whereArgs: [1],
        orderBy: 'rating DESC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get available specialists: $e');
    }
  }

  Future<List<Specialist>> searchSpecialists(String searchTerm) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'name LIKE ? OR specialty LIKE ? OR hospital LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: 'rating DESC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to search specialists: $e');
    }
  }

  Future<List<Specialist>> getSpecialistsByHospital(String hospital) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'hospital = ?',
        whereArgs: [hospital],
        orderBy: 'name ASC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get specialists by hospital: $e');
    }
  }

  Future<List<Specialist>> getSpecialistsByRating(double minRating) async {
    try {
      final maps = await _dbHelper.query(
        tableName,
        where: 'rating >= ?',
        whereArgs: [minRating],
        orderBy: 'rating DESC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to get specialists by rating: $e');
    }
  }

  Future<List<Specialist>> filterSpecialists({
    String? specialty,
    String? hospital,
    bool? isAvailable,
    double? minRating,
    String? language,
    String? insurance,
    String? hospitalNetwork,
  }) async {
    try {
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (specialty != null) {
        whereConditions.add('specialty = ?');
        whereArgs.add(specialty);
      }

      if (hospital != null) {
        whereConditions.add('hospital = ?');
        whereArgs.add(hospital);
      }

      if (isAvailable != null) {
        whereConditions.add('is_available = ?');
        whereArgs.add(isAvailable ? 1 : 0);
      }

      if (minRating != null) {
        whereConditions.add('rating >= ?');
        whereArgs.add(minRating);
      }

      if (language != null) {
        whereConditions.add('languages LIKE ?');
        whereArgs.add('%$language%');
      }

      if (insurance != null) {
        whereConditions.add('insurance LIKE ?');
        whereArgs.add('%$insurance%');
      }

      if (hospitalNetwork != null) {
        whereConditions.add('hospital_network = ?');
        whereArgs.add(hospitalNetwork);
      }

      final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

      final maps = await _dbHelper.query(
        tableName,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'rating DESC, success_rate DESC',
      );
      return maps.map(Specialist.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to filter specialists: $e');
    }
  }

  // Update
  Future<bool> updateSpecialist(Specialist specialist) async {
    try {
      specialist.updateTimestamp();
      final rowsAffected = await _dbHelper.update(tableName, specialist.toMap(), specialist.id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update specialist: $e');
    }
  }

  Future<bool> updateAvailability(String id, bool isAvailable) async {
    try {
      final rowsAffected = await _dbHelper.update(
        tableName,
        {
          'is_available': isAvailable ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        id,
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update specialist availability: $e');
    }
  }

  Future<bool> updateRating(String id, double rating) async {
    try {
      final rowsAffected = await _dbHelper.update(
        tableName,
        {
          'rating': rating,
          'updated_at': DateTime.now().toIso8601String(),
        },
        id,
      );
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to update specialist rating: $e');
    }
  }

  // Delete
  Future<bool> deleteSpecialist(String id) async {
    try {
      final rowsAffected = await _dbHelper.delete(tableName, id);
      return rowsAffected > 0;
    } catch (e) {
      throw Exception('Failed to delete specialist: $e');
    }
  }

  // Batch operations
  Future<void> createMultipleSpecialists(List<Specialist> specialists) async {
    try {
      final maps = specialists.map((specialist) => specialist.toMap()).toList();
      await _dbHelper.batchInsert(tableName, maps);
    } catch (e) {
      throw Exception('Failed to create multiple specialists: $e');
    }
  }

  // Statistics
  Future<int> getTotalSpecialistsCount() async {
    try {
      return await _dbHelper.getTableCount(tableName);
    } catch (e) {
      throw Exception('Failed to get specialists count: $e');
    }
  }

  Future<Map<String, int>> getSpecialistsBySpecialtyCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT specialty, COUNT(*) as count 
        FROM $tableName 
        GROUP BY specialty
        ORDER BY count DESC
      ''');
      
      final specialtyCounts = <String, int>{};
      for (var row in result) {
        specialtyCounts[row['specialty'] as String] = row['count'] as int;
      }
      return specialtyCounts;
    } catch (e) {
      throw Exception('Failed to get specialty statistics: $e');
    }
  }

  Future<List<String>> getAllSpecialties() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT specialty 
        FROM $tableName 
        ORDER BY specialty ASC
      ''');
      
      return result.map((row) => row['specialty'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get specialties: $e');
    }
  }

  Future<List<String>> getAllHospitals() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT hospital 
        FROM $tableName 
        ORDER BY hospital ASC
      ''');
      
      return result.map((row) => row['hospital'] as String).toList();
    } catch (e) {
      throw Exception('Failed to get hospitals: $e');
    }
  }

  Future<double> getAverageRating() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT AVG(rating) as avg_rating 
        FROM $tableName 
        WHERE rating > 0
      ''');
      
      return (result.first['avg_rating'] as double?) ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get average rating: $e');
    }
  }
}
