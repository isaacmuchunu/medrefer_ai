import '../../database/database_helper.dart';
import '../models/models.dart';

class AppointmentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'appointments';

  Future<String> createAppointment(Appointment appointment) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, appointment.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  Future<List<Appointment>> getAllAppointments() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all appointments: $e');
    }
  }

  Future<Appointment?> getAppointmentById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Appointment.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment by id: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get appointments by patient id: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsBySpecialistId(String specialistId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'specialist_id = ?', whereArgs: [specialistId]);
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get appointments by specialist id: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    try {
      final db = await _dbHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'appointment_date BETWEEN ? AND ?', whereArgs: [startOfDay, endOfDay]);
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get appointments by date: $e');
    }
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'appointment_date >= ?', whereArgs: [now], orderBy: 'appointment_date ASC');
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get upcoming appointments: $e');
    }
  }

  Future<List<Appointment>> searchAppointments(String searchTerm) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'reason LIKE ?', whereArgs: ['%$searchTerm%']);
      return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to search appointments: $e');
    }
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, appointment.toMap(), where: 'id = ?', whereArgs: [appointment.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  Future<bool> updateAppointmentStatus(String id, String status) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, {'status': status}, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  Future<bool> deleteAppointment(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  Future<int> getTotalAppointmentsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total appointments count: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentHistory(String patientId) async {
    // This is a mock implementation. In a real app, you would join tables
    // to get specialist names, etc.
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'appointment_date DESC',
      );
      
      // Mock joining with a specialist table
      return List.generate(maps.length, (i) {
        final appointment = Appointment.fromMap(maps[i]);
        return {
          'id': appointment.id,
          'specialist': 'Dr. Smith', // Mock data
          'date': appointment.appointmentDate?.toLocal().toString().substring(0, 16) ?? '',
          'status': appointment.status,
          'details': appointment.reasonForAppointment,
        };
      });
    } catch (e) {
      throw Exception('Failed to get appointment history: $e');
    }
  }
}
