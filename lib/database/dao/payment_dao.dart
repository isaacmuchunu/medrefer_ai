import '../../database/database_helper.dart';
import '../models/models.dart';

class PaymentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _tableName = 'payments';

  Future<String> createPayment(Payment payment) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(_tableName, payment.toMap());
      return id.toString();
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName);
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get all payments: $e');
    }
  }

  Future<Payment?> getPaymentById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Payment.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment by id: $e');
    }
  }

  Future<List<Payment>> getPaymentsByPatientId(String patientId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'patient_id = ?', whereArgs: [patientId]);
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get payments by patient id: $e');
    }
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, where: 'status = ?', whereArgs: [status]);
      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e) {
      throw Exception('Failed to get payments by status: $e');
    }
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(_tableName, payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }

  Future<bool> deletePayment(String id) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
      return result > 0;
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }

  Future<int> getTotalPaymentsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
      return result.first.values.first as int;
    } catch (e) {
      throw Exception('Failed to get total payments count: $e');
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT SUM(amount) FROM $_tableName WHERE status = "completed"');
      return (result.first.values.first as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total revenue: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String patientId) async {
    // This is a mock implementation.
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'created_at DESC',
      );
      
      return List.generate(maps.length, (i) {
        final payment = Payment.fromMap(maps[i]);
        return {
          'id': payment.id,
          'amount': payment.amount,
          'date': payment.createdAt.toLocal().toString().substring(0, 16),
          'status': payment.status,
          'description': payment.description,
        };
      });
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }
}
