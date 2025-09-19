import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../dao/dao.dart';
import '../dao/pharmacy_dao.dart';
import '../models/models.dart';
import 'migration_service.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Expose a static singleton for legacy callers
  static DataService get instance => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MigrationService _migrationService = MigrationService();

  // DAOs
  final PatientDao _patientDao = PatientDao();
  final SpecialistDao _specialistDao = SpecialistDao();
  final ReferralDao _referralDao = ReferralDao();
  final MessageDao _messageDao = MessageDao();
  final MedicalHistoryDao _medicalHistoryDao = MedicalHistoryDao();
  final ConditionDao _conditionDao = ConditionDao();
  final MedicationDao _medicationDao = MedicationDao();
  final DocumentDao _documentDao = DocumentDao();
  final EmergencyContactDao _emergencyContactDao = EmergencyContactDao();
  final VitalStatisticsDao _vitalStatisticsDao = VitalStatisticsDao();
  final AppointmentDao _appointmentDao = AppointmentDao();
  final PaymentDao _paymentDao = PaymentDao();
  final InsuranceDao _insuranceDao = InsuranceDao();
  final LabResultDao _labResultDao = LabResultDao();
  final PrescriptionDao _prescriptionDao = PrescriptionDao();
  final FeedbackDao _feedbackDao = FeedbackDao();
  // PharmacyDAO is constructed with a Database; expose a getter via DatabaseHelper when needed
  PharmacyDAO getPharmacyDao(Database db) => PharmacyDAO(db);
  final ConsentDao _consentDao = ConsentDao();
  final CarePlanDao _carePlanDao = CarePlanDao();

  // DAO Getters
  PatientDao get patientDAO => _patientDao;
  SpecialistDao get specialistDAO => _specialistDao;
  ReferralDao get referralDAO => _referralDao;
  VitalStatisticsDao get vitalStatisticsDAO => _vitalStatisticsDao;
  AppointmentDao get appointmentDAO => _appointmentDao;
  PaymentDao get paymentDAO => _paymentDao;
  InsuranceDao get insuranceDAO => _insuranceDao;
  LabResultDao get labResultDAO => _labResultDao;
  PrescriptionDao get prescriptionDAO => _prescriptionDao;
  FeedbackDao get feedbackDAO => _feedbackDao;
  MessageDao get messageDAO => _messageDao;
  MedicalHistoryDao get medicalHistoryDAO => _medicalHistoryDao;
  ConditionDao get conditionDAO => _conditionDao;
  MedicationDao get medicationDAO => _medicationDao;
  DocumentDao get documentDAO => _documentDao;
  EmergencyContactDao get emergencyContactDAO => _emergencyContactDao;
  Future<PharmacyDAO> get pharmacyDAO async => getPharmacyDao(await getDatabase());
  ConsentDao get consentDAO => _consentDao;
  CarePlanDao get carePlanDAO => _carePlanDao;

  // Cache for frequently accessed data
  List<Patient>? _cachedPatients;
  List<Specialist>? _cachedSpecialists;
  List<Referral>? _cachedReferrals;
  Map<String, List<Message>> _cachedConversations = {};
  List<Appointment>? _cachedUpcomingAppointments;
  List<Payment>? _cachedPayments;
  List<Insurance>? _cachedInsurance;
  List<LabResult>? _cachedLabResults;
  List<Prescription>? _cachedPrescriptions;
  List<Consent>? _cachedConsents;
  List<CarePlan>? _cachedCarePlans;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize database and seed data
  Future<void> initialize() async {
    try {
      await _dbHelper.database; // Initialize database
      await _migrationService.seedComprehensiveData();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize data service: $e');
      rethrow;
    }
  }

  // Low-level database accessor (needed by services that construct DAOs directly)
  Future<Database> getDatabase() async {
    return await _dbHelper.database;
  }

  // Generic DB helpers (legacy compatibility)
  Future<String> insert(String table, Map<String, dynamic> data) async {
    return await _dbHelper.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return await _dbHelper.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    return await _dbHelper.queryById(table, id);
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    return await _dbHelper.update(table, data, id);
  }

  Future<int> delete(String table, String id) async {
    return await _dbHelper.delete(table, id);
  }

  // Patient operations
  Future<List<Patient>> getPatients({bool forceRefresh = false}) async {
    if (_cachedPatients == null || forceRefresh) {
      _cachedPatients = await _patientDao.getAllPatients();
    }
    return _cachedPatients!;
  }

  Future<Patient?> getPatientById(String id) async {
    return await _patientDao.getPatientById(id);
  }

  // Alias for getPatientById for compatibility
  Future<Patient?> getPatient(String id) async {
    return await getPatientById(id);
  }

  Future<Patient?> getPatientByMrn(String mrn) async {
    return await _patientDao.getPatientByMrn(mrn);
  }

  Future<List<Patient>> searchPatients(String searchTerm) async {
    return await _patientDao.searchPatients(searchTerm);
  }

  Future<String> createPatient(Patient patient) async {
    final id = await _patientDao.createPatient(patient);
    _cachedPatients = null; // Invalidate cache
    notifyListeners();
    return id;
  }

  Future<bool> updatePatient(Patient patient) async {
    final success = await _patientDao.updatePatient(patient);
    if (success) {
      _cachedPatients = null; // Invalidate cache
      notifyListeners();
    }
    return success;
  }

  Future<bool> deletePatient(String id) async {
    final success = await _patientDao.deletePatient(id);
    if (success) {
      _cachedPatients = null; // Invalidate cache
      notifyListeners();
    }
    return success;
  }

  // Specialist operations
  Future<List<Specialist>> getSpecialists({bool forceRefresh = false}) async {
    if (_cachedSpecialists == null || forceRefresh) {
      _cachedSpecialists = await _specialistDao.getAllSpecialists();
    }
    return _cachedSpecialists!;
  }

  Future<Specialist?> getSpecialistById(String id) async {
    return await _specialistDao.getSpecialistById(id);
  }

  Future<List<Specialist>> getSpecialistsBySpecialty(String specialty) async {
    return await _specialistDao.getSpecialistsBySpecialty(specialty);
  }

  Future<List<Specialist>> getAvailableSpecialists() async {
    return await _specialistDao.getAvailableSpecialists();
  }

  Future<List<Specialist>> searchSpecialists(String searchTerm) async {
    return await _specialistDao.searchSpecialists(searchTerm);
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
    return await _specialistDao.filterSpecialists(
      specialty: specialty,
      hospital: hospital,
      isAvailable: isAvailable,
      minRating: minRating,
      language: language,
      insurance: insurance,
      hospitalNetwork: hospitalNetwork,
    );
  }

  Future<String> createSpecialist(Specialist specialist) async {
    final id = await _specialistDao.createSpecialist(specialist);
    _cachedSpecialists = null; // Invalidate cache
    notifyListeners();
    return id;
  }

  Future<bool> updateSpecialist(Specialist specialist) async {
    final success = await _specialistDao.updateSpecialist(specialist);
    if (success) {
      _cachedSpecialists = null; // Invalidate cache
      notifyListeners();
    }
    return success;
  }

  // Referral operations
  Future<List<Referral>> getAllReferrals() async {
    return await _referralDao.getAllReferrals();
  }
  Future<List<Referral>> getReferrals({bool forceRefresh = false}) async {
    if (_cachedReferrals == null || forceRefresh) {
      _cachedReferrals = await _referralDao.getAllReferrals();
    }
    return _cachedReferrals!;
  }

  Future<Referral?> getReferralById(String id) async {
    return await _referralDao.getReferralById(id);
  }

  Future<List<Referral>> getReferralsByPatientId(String patientId) async {
    return await _referralDao.getReferralsByPatientId(patientId);
  }

  Future<List<Referral>> getReferralsByStatus(String status) async {
    return await _referralDao.getReferralsByStatus(status);
  }

  Future<String> createReferral(Referral referral) async {
    final id = await _referralDao.createReferral(referral);
    _cachedReferrals = null; // Invalidate cache
    notifyListeners();
    return id;
  }

  Future<bool> updateReferralStatus(String id, String status) async {
    final success = await _referralDao.updateReferralStatus(id, status);
    if (success) {
      _cachedReferrals = null; // Invalidate cache
      notifyListeners();
    }
    return success;
  }

  // Message operations
  Future<List<Message>> getMessagesByConversationId(String conversationId) async {
    if (!_cachedConversations.containsKey(conversationId)) {
      _cachedConversations[conversationId] = await _messageDao.getMessagesByConversationId(conversationId);
    }
    return _cachedConversations[conversationId]!;
  }

  Future<String> createMessage(Message message) async {
    final id = await _messageDao.createMessage(message);
    _cachedConversations.remove(message.conversationId); // Invalidate conversation cache
    notifyListeners();
    return id;
  }

  Future<int> getUnreadMessagesCount(String userId) async {
    return await _messageDao.getUnreadMessagesCount(userId);
  }

  // Medical history operations
  Future<List<MedicalHistory>> getMedicalHistoryByPatientId(String patientId) async {
    return await _medicalHistoryDao.getMedicalHistoryByPatientId(patientId);
  }

  Future<String> createMedicalHistory(MedicalHistory history) async {
    final id = await _medicalHistoryDao.createMedicalHistory(history);
    notifyListeners();
    return id;
  }

  // Condition operations
  Future<List<Condition>> getConditionsByPatientId(String patientId) async {
    return await _conditionDao.getConditionsByPatientId(patientId);
  }

  Future<String> createCondition(Condition condition) async {
    final id = await _conditionDao.createCondition(condition);
    notifyListeners();
    return id;
  }

  Future<bool> updateCondition(Condition condition) async {
    final success = await _conditionDao.updateCondition(condition);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteCondition(String id) async {
    final success = await _conditionDao.deleteCondition(id);
    if (success) notifyListeners();
    return success;
  }

  // Medication operations
  Future<List<Medication>> getMedicationsByPatientId(String patientId) async {
    return await _medicationDao.getMedicationsByPatientId(patientId);
  }

  Future<String> createMedication(Medication medication) async {
    final id = await _medicationDao.createMedication(medication);
    notifyListeners();
    return id;
  }

  Future<bool> updateMedication(Medication medication) async {
    final success = await _medicationDao.updateMedication(medication);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteMedication(String id) async {
    final success = await _medicationDao.deleteMedication(id);
    if (success) notifyListeners();
    return success;
  }

  // Document operations
  Future<List<Document>> getDocumentsByPatientId(String patientId) async {
    return await _documentDao.getDocumentsByPatientId(patientId);
  }

  Future<String> createDocument(Document document) async {
    final id = await _documentDao.createDocument(document);
    notifyListeners();
    return id;
  }

  Future<bool> updateDocument(Document document) async {
    final success = await _documentDao.updateDocument(document);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteDocument(String id) async {
    final success = await _documentDao.deleteDocument(id);
    if (success) notifyListeners();
    return success;
  }

  // Emergency Contact operations
  Future<List<EmergencyContact>> getEmergencyContactsByPatientId(String patientId) async {
    return await _emergencyContactDao.getEmergencyContactsByPatientId(patientId);
  }

  Future<String> createEmergencyContact(EmergencyContact contact) async {
    final id = await _emergencyContactDao.createEmergencyContact(contact);
    notifyListeners();
    return id;
  }

  Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    final success = await _emergencyContactDao.updateEmergencyContact(contact);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteEmergencyContact(String id) async {
    final success = await _emergencyContactDao.deleteEmergencyContact(id);
    if (success) notifyListeners();
    return success;
  }

  // Vital Statistics operations
  Future<List<VitalStatistics>> getVitalStatisticsByPatientId(String patientId) async {
    return await _vitalStatisticsDao.getVitalStatisticsByPatientId(patientId);
  }

  Future<String> createVitalStatistics(VitalStatistics vitals) async {
    final id = await _vitalStatisticsDao.createVitalStatistics(vitals);
    notifyListeners();
    return id;
  }

  Future<bool> updateVitalStatistics(VitalStatistics vitals) async {
    final success = await _vitalStatisticsDao.updateVitalStatistics(vitals);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> deleteVitalStatistics(String id) async {
    final success = await _vitalStatisticsDao.deleteVitalStatistics(id);
    if (success) notifyListeners();
    return success;
  }

  // Appointment operations
  Future<List<Appointment>> getAllAppointments() async {
    return await _appointmentDao.getAllAppointments();
  }
  Future<List<Appointment>> getAppointmentHistory(String patientId) async {
    try {
      return await _appointmentDao.getAppointmentsByPatientId(patientId);
    } catch (e) {
      debugPrint('getAppointmentHistory failed: $e');
      rethrow;
    }
  }

  Future<List<Appointment>> getUpcomingAppointments({bool forceRefresh = false}) async {
    try {
      if (_cachedUpcomingAppointments == null || forceRefresh) {
        _cachedUpcomingAppointments = await _appointmentDao.getUpcomingAppointments();
      }
      return _cachedUpcomingAppointments!;
    } catch (e) {
      debugPrint('getUpcomingAppointments failed: $e');
      rethrow;
    }
  }

  Future<String> createAppointment(Appointment appointment) async {
    try {
      final id = await _appointmentDao.createAppointment(appointment);
      _cachedUpcomingAppointments = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createAppointment failed: $e');
      rethrow;
    }
  }

  Future<bool> updateAppointmentStatus(String id, String status) async {
    try {
      final success = await _appointmentDao.updateAppointmentStatus(id, status);
      if (success) {
        _cachedUpcomingAppointments = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updateAppointmentStatus failed: $e');
      rethrow;
    }
  }

  // Payment operations
  Future<List<Payment>> getPaymentHistory(String patientId) async {
    try {
      return await _paymentDao.getPaymentsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPaymentHistory failed: $e');
      rethrow;
    }
  }

  Future<List<Payment>> getAllPayments({bool forceRefresh = false}) async {
    try {
      if (_cachedPayments == null || forceRefresh) {
        _cachedPayments = await _paymentDao.getAllPayments();
      }
      return _cachedPayments!;
    } catch (e) {
      debugPrint('getAllPayments failed: $e');
      rethrow;
    }
  }

  Future<String> createPayment(Payment payment) async {
    try {
      final id = await _paymentDao.createPayment(payment);
      _cachedPayments = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createPayment failed: $e');
      rethrow;
    }
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      final success = await _paymentDao.updatePayment(payment);
      if (success) {
        _cachedPayments = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updatePayment failed: $e');
      rethrow;
    }
  }

  Future<double> getTotalRevenue() async {
    try {
      return await _paymentDao.getTotalRevenue();
    } catch (e) {
      debugPrint('getTotalRevenue failed: $e');
      rethrow;
    }
  }

  // Insurance operations
  Future<List<Insurance>> getInsuranceForPatient(String patientId) async {
    try {
      return await _insuranceDao.getInsuranceByPatientId(patientId);
    } catch (e) {
      debugPrint('getInsuranceForPatient failed: $e');
      rethrow;
    }
  }

  Future<List<Insurance>> getAllInsurance({bool forceRefresh = false}) async {
    try {
      if (_cachedInsurance == null || forceRefresh) {
        _cachedInsurance = await _insuranceDao.getAllInsurance();
      }
      return _cachedInsurance!;
    } catch (e) {
      debugPrint('getAllInsurance failed: $e');
      rethrow;
    }
  }

  Future<String> createInsurance(Insurance insurance) async {
    try {
      final id = await _insuranceDao.createInsurance(insurance);
      _cachedInsurance = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createInsurance failed: $e');
      rethrow;
    }
  }

  Future<bool> updateInsurance(Insurance insurance) async {
    try {
      final success = await _insuranceDao.updateInsurance(insurance);
      if (success) {
        _cachedInsurance = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updateInsurance failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteInsurance(String id) async {
    try {
      final success = await _insuranceDao.deleteInsurance(id);
      if (success) {
        _cachedInsurance = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deleteInsurance failed: $e');
      rethrow;
    }
  }

  // Lab Result operations
  Future<List<LabResult>> getLabResultsForPatient(String patientId) async {
    try {
      return await _labResultDao.getLabResultsByPatientId(patientId);
    } catch (e) {
      debugPrint('getLabResultsForPatient failed: $e');
      rethrow;
    }
  }

  Future<List<LabResult>> getAllLabResults({bool forceRefresh = false}) async {
    try {
      if (_cachedLabResults == null || forceRefresh) {
        _cachedLabResults = await _labResultDao.getAllLabResults();
      }
      return _cachedLabResults!;
    } catch (e) {
      debugPrint('getAllLabResults failed: $e');
      rethrow;
    }
  }

  Future<String> createLabResult(LabResult labResult) async {
    try {
      final id = await _labResultDao.createLabResult(labResult);
      _cachedLabResults = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createLabResult failed: $e');
      rethrow;
    }
  }

  Future<bool> updateLabResult(LabResult labResult) async {
    try {
      final success = await _labResultDao.updateLabResult(labResult);
      if (success) {
        _cachedLabResults = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updateLabResult failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteLabResult(String id) async {
    try {
      final success = await _labResultDao.deleteLabResult(id);
      if (success) {
        _cachedLabResults = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deleteLabResult failed: $e');
      rethrow;
    }
  }

  // Prescription operations
  Future<List<Prescription>> getPrescriptionsForPatient(String patientId) async {
    try {
      return await _prescriptionDao.getPrescriptionsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPrescriptionsForPatient failed: $e');
      rethrow;
    }
  }

  // Consent operations
  Future<List<Consent>> getConsentsForPatient(String patientId, {bool forceRefresh = false}) async {
    try {
      if (_cachedConsents == null || forceRefresh) {
        _cachedConsents = await _consentDao.getConsentsByPatientId(patientId);
      }
      return _cachedConsents!.where((c) => c.patientId == patientId).toList();
    } catch (e) {
      debugPrint('getConsentsForPatient failed: $e');
      rethrow;
    }
  }

  Future<String> createConsent(Consent consent) async {
    try {
      final id = await _consentDao.createConsent(consent);
      _cachedConsents = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createConsent failed: $e');
      rethrow;
    }
  }

  Future<bool> updateConsent(Consent consent) async {
    try {
      final success = await _consentDao.updateConsent(consent);
      if (success) {
        _cachedConsents = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updateConsent failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteConsent(String id) async {
    try {
      final success = await _consentDao.deleteConsent(id);
      if (success) {
        _cachedConsents = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deleteConsent failed: $e');
      rethrow;
    }
  }

  // Care Plan operations
  Future<List<CarePlan>> getCarePlansForPatient(String patientId, {bool forceRefresh = false}) async {
    try {
      if (_cachedCarePlans == null || forceRefresh) {
        _cachedCarePlans = await _carePlanDao.getCarePlansByPatientId(patientId);
      }
      return _cachedCarePlans!.where((p) => p.patientId == patientId).toList();
    } catch (e) {
      debugPrint('getCarePlansForPatient failed: $e');
      rethrow;
    }
  }

  Future<String> createCarePlan(CarePlan plan) async {
    try {
      final id = await _carePlanDao.createCarePlan(plan);
      _cachedCarePlans = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createCarePlan failed: $e');
      rethrow;
    }
  }

  Future<bool> updateCarePlan(CarePlan plan) async {
    try {
      final success = await _carePlanDao.updateCarePlan(plan);
      if (success) {
        _cachedCarePlans = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updateCarePlan failed: $e');
      rethrow;
    }
  }

  Future<bool> deleteCarePlan(String id) async {
    try {
      final success = await _carePlanDao.deleteCarePlan(id);
      if (success) {
        _cachedCarePlans = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deleteCarePlan failed: $e');
      rethrow;
    }
  }

  Future<List<Prescription>> getAllPrescriptions({bool forceRefresh = false}) async {
    try {
      if (_cachedPrescriptions == null || forceRefresh) {
        _cachedPrescriptions = await _prescriptionDao.getAllPrescriptions();
      }
      return _cachedPrescriptions!;
    } catch (e) {
      debugPrint('getAllPrescriptions failed: $e');
      rethrow;
    }
  }

  Future<String> createPrescription(Prescription prescription) async {
    try {
      final id = await _prescriptionDao.createPrescription(prescription);
      _cachedPrescriptions = null;
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('createPrescription failed: $e');
      rethrow;
    }
  }

  Future<bool> updatePrescription(Prescription prescription) async {
    try {
      final success = await _prescriptionDao.updatePrescription(prescription);
      if (success) {
        _cachedPrescriptions = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('updatePrescription failed: $e');
      rethrow;
    }
  }

  Future<bool> deletePrescription(String id) async {
    try {
      final success = await _prescriptionDao.deletePrescription(id);
      if (success) {
        _cachedPrescriptions = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('deletePrescription failed: $e');
      rethrow;
    }
  }

  // Feedback operations
  Future<String> submitFeedback(Feedback feedback) async {
    try {
      final id = await _feedbackDao.createFeedback(feedback);
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('submitFeedback failed: $e');
      rethrow;
    }
  }

  Future<List<Feedback>> getFeedbackBySpecialist(String specialistId) async {
    try {
      return await _feedbackDao.getFeedbackBySpecialistId(specialistId);
    } catch (e) {
      debugPrint('getFeedbackBySpecialist failed: $e');
      rethrow;
    }
  }

  Future<List<Feedback>> getFeedbackByPatient(String patientId) async {
    try {
      return await _feedbackDao.getFeedbackByPatientId(patientId);
    } catch (e) {
      debugPrint('getFeedbackByPatient failed: $e');
      rethrow;
    }
  }

  Future<double> getAverageRatingForSpecialist(String specialistId) async {
    try {
      return await _feedbackDao.getAverageRatingBySpecialist(specialistId);
    } catch (e) {
      debugPrint('getAverageRatingForSpecialist failed: $e');
      rethrow;
    }
  }

  Future<bool> updateFeedback(Feedback feedback) async {
    try {
      final success = await _feedbackDao.updateFeedback(feedback);
      if (success) notifyListeners();
      return success;
    } catch (e) {
      debugPrint('updateFeedback failed: $e');
      rethrow;
    }
  }

  // Wrapper methods for simplified access
  Future<int> getPatientCount() async {
    return await _patientDao.getTotalPatientsCount();
  }

  Future<int> getSpecialistCount() async {
    return await _specialistDao.getTotalSpecialistsCount();
  }

  Future<int> getReferralCount() async {
    return await _referralDao.getTotalReferralsCount();
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    // Enhanced implementation
    final referrals = await getReferrals(forceRefresh: true);
    final appointments = await appointmentDAO.getAllAppointments();

    final activities = <Map<String, dynamic>>[];

    for (var referral in referrals.take(5)) {
      activities.add({
        'description': 'Referral for ${referral.patientId} is ${referral.status}.',
        'timestamp': referral.updatedAt ?? referral.createdAt,
        'type': 'referral'
      });
    }

    for (var appointment in appointments.take(5)) {
      activities.add({
        'description': 'Appointment for ${appointment.patientId} is scheduled.',
        'timestamp': appointment.updatedAt ?? appointment.createdAt,
        'type': 'appointment'
      });
    }

    activities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return activities.take(10).toList();
  }

  // Additional methods needed by other services
  Future<int> getTotalReferrals() async {
    try {
      return await _referralDao.getTotalReferralsCount();
    } catch (e) {
      debugPrint('getTotalReferrals failed: $e');
      return 0;
    }
  }

  Future<int> getTotalPatients() async {
    try {
      return await _patientDao.getTotalPatientsCount();
    } catch (e) {
      debugPrint('getTotalPatients failed: $e');
      return 0;
    }
  }

  Future<List<Referral>> searchReferrals(String query) async {
    try {
      return await _referralDao.searchReferrals(query);
    } catch (e) {
      debugPrint('searchReferrals failed: $e');
      return [];
    }
  }

  Future<List<Patient>> getAllPatients() async {
    return await getPatients();
  }

  Future<List<Medication>> getPatientMedications(String patientId) async {
    try {
      return await medicationDAO.getMedicationsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPatientMedications failed: $e');
      return [];
    }
  }

  Future<List<Condition>> getPatientConditions(String patientId) async {
    try {
      return await conditionDAO.getConditionsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPatientConditions failed: $e');
      return [];
    }
  }

  Future<List<Referral>> getPatientReferrals(String patientId) async {
    try {
      return await _referralDao.getReferralsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPatientReferrals failed: $e');
      return [];
    }
  }

  Future<List<MedicalHistory>> getPatientMedicalHistory(String patientId) async {
    try {
      return await medicalHistoryDAO.getMedicalHistoryByPatientId(patientId);
    } catch (e) {
      debugPrint('getPatientMedicalHistory failed: $e');
      return [];
    }
  }

  Future<List<VitalStatistics>> getPatientVitalStatistics(String patientId) async {
    try {
      return await vitalStatisticsDAO.getVitalStatisticsByPatientId(patientId);
    } catch (e) {
      debugPrint('getPatientVitalStatistics failed: $e');
      return [];
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      return await messageDAO.getMessagesByConversationId(conversationId);
    } catch (e) {
      debugPrint('getMessages failed: $e');
      return [];
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      await messageDAO.createMessage(message);
      notifyListeners();
    } catch (e) {
      debugPrint('sendMessage failed: $e');
      rethrow;
    }
  }

  Future<Condition?> getConditionById(String id) async {
    try {
      return await conditionDAO.getConditionById(id);
    } catch (e) {
      debugPrint('getConditionById failed: $e');
      return null;
    }
  }

  Future<Medication?> getMedicationById(String id) async {
    try {
      return await medicationDAO.getMedicationById(id);
    } catch (e) {
      debugPrint('getMedicationById failed: $e');
      return null;
    }
  }

  Future<Document?> getDocumentById(String id) async {
    try {
      return await documentDAO.getDocumentById(id);
    } catch (e) {
      debugPrint('getDocumentById failed: $e');
      return null;
    }
  }

  Future<EmergencyContact?> getEmergencyContactById(String id) async {
    try {
      return await emergencyContactDAO.getEmergencyContactById(id);
    } catch (e) {
      debugPrint('getEmergencyContactById failed: $e');
      return null;
    }
  }

  Future<VitalStatistics?> getVitalStatisticsById(String id) async {
    try {
      return await vitalStatisticsDAO.getVitalStatisticsById(id);
    } catch (e) {
      debugPrint('getVitalStatisticsById failed: $e');
      return null;
    }
  }

  // Dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final totalPatients = await _patientDao.getTotalPatientsCount();
      final totalSpecialists = await _specialistDao.getTotalSpecialistsCount();
      final totalReferrals = await _referralDao.getTotalReferralsCount();
      final statusCounts = await _referralDao.getReferralsByStatusCount();
      final urgencyCounts = await _referralDao.getReferralsByUrgencyCount();
      final totalAppointments = await _appointmentDao.getTotalAppointmentsCount();
      final totalPayments = await _paymentDao.getTotalPaymentsCount();
      final totalInsurance = await _insuranceDao.getTotalInsuranceCount();
      final totalLabResults = await _labResultDao.getTotalLabResultsCount();
      final totalPrescriptions = await _prescriptionDao.getTotalPrescriptionsCount();
      final totalFeedback = await _feedbackDao.getTotalFeedbackCount();
      final totalRevenue = await _paymentDao.getTotalRevenue();

      return {
        'totalPatients': totalPatients,
        'totalSpecialists': totalSpecialists,
        'totalReferrals': totalReferrals,
        'pendingReferrals': statusCounts['Pending'] ?? 0,
        'approvedReferrals': statusCounts['Approved'] ?? 0,
        'completedReferrals': statusCounts['Completed'] ?? 0,
        'urgentCases': urgencyCounts['Urgent'] ?? 0,
        'emergencyCases': urgencyCounts['Emergency'] ?? 0,
        'statusBreakdown': statusCounts,
        'urgencyBreakdown': urgencyCounts,
        'totalAppointments': totalAppointments,
        'totalPayments': totalPayments,
        'totalInsurance': totalInsurance,
        'totalLabResults': totalLabResults,
        'totalPrescriptions': totalPrescriptions,
        'totalFeedback': totalFeedback,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Failed to get dashboard stats: $e');
    }
  }

  // Clear all caches
  void clearCache() {
    _cachedPatients = null;
    _cachedSpecialists = null;
    _cachedReferrals = null;
    _cachedConversations.clear();
    _cachedUpcomingAppointments = null;
    _cachedPayments = null;
    _cachedInsurance = null;
    _cachedLabResults = null;
    _cachedPrescriptions = null;
    notifyListeners();
  }

  // Seed initial data
  Future<void> _seedInitialData() async {
    try {
      // Check if data already exists
      final patientCount = await _patientDao.getTotalPatientsCount();
      if (patientCount > 0) return; // Data already seeded

      // Seed patients
      await _seedPatients();
      
      // Seed specialists
      await _seedSpecialists();
      
      // Seed referrals
      await _seedReferrals();

      debugPrint('Initial data seeded successfully');
    } catch (e) {
      debugPrint('Failed to seed initial data: $e');
    }
  }

  Future<void> _seedPatients() async {
    final patients = [
      Patient(
        name: 'John Smith',
        age: 45,
        medicalRecordNumber: 'MRN001',
        dateOfBirth: DateTime(1979, 3, 15),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-0123',
        email: 'john.smith@email.com',
        address: '123 Main St, City, State 12345',
      ),
      Patient(
        name: 'Sarah Johnson',
        age: 32,
        medicalRecordNumber: 'MRN002',
        dateOfBirth: DateTime(1992, 7, 22),
        gender: 'Female',
        bloodType: 'A+',
        phone: '+1-555-0124',
        email: 'sarah.johnson@email.com',
        address: '456 Oak Ave, City, State 12345',
      ),
      Patient(
        name: 'Michael Brown',
        age: 67,
        medicalRecordNumber: 'MRN003',
        dateOfBirth: DateTime(1957, 11, 8),
        gender: 'Male',
        bloodType: 'B+',
        phone: '+1-555-0125',
        email: 'michael.brown@email.com',
        address: '789 Pine St, City, State 12345',
      ),
    ];

    await _patientDao.createMultiplePatients(patients);
  }

  Future<void> _seedSpecialists() async {
    final specialists = [
      Specialist(
        name: 'Dr. Emily Chen',
        credentials: 'MD, PhD',
        specialty: 'Cardiology',
        hospital: 'City General Hospital',
        rating: 4.8,
        successRate: 0.92,
        languages: ['English', 'Mandarin'],
        insurance: ['Blue Cross', 'Aetna', 'Medicare'],
        hospitalNetwork: 'City Health Network',
      ),
      Specialist(
        name: 'Dr. Robert Wilson',
        credentials: 'MD',
        specialty: 'Neurology',
        hospital: 'Metropolitan Medical Center',
        rating: 4.6,
        successRate: 0.89,
        languages: ['English', 'Spanish'],
        insurance: ['United Healthcare', 'Cigna', 'Medicare'],
        hospitalNetwork: 'Metro Health System',
      ),
      Specialist(
        name: 'Dr. Lisa Rodriguez',
        credentials: 'MD, FACP',
        specialty: 'Internal Medicine',
        hospital: 'University Hospital',
        rating: 4.9,
        successRate: 0.95,
        languages: ['English', 'Spanish', 'Portuguese'],
        insurance: ['All Major Insurance', 'Medicare', 'Medicaid'],
        hospitalNetwork: 'University Health System',
      ),
    ];

    await _specialistDao.createMultipleSpecialists(specialists);
  }

  Future<void> _seedReferrals() async {
    final patients = await _patientDao.getAllPatients();
    final specialists = await _specialistDao.getAllSpecialists();
    
    if (patients.isEmpty || specialists.isEmpty) return;

    final referrals = [
      Referral(
        trackingNumber: 'REF001',
        patientId: patients[0].id,
        specialistId: specialists[0].id,
        status: 'Pending',
        urgency: 'High',
        symptomsDescription: 'Chest pain and shortness of breath',
        aiConfidence: 0.87,
        estimatedTime: '2-3 days',
        department: 'Cardiology',
        referringPhysician: 'Dr. Primary Care',
      ),
      Referral(
        trackingNumber: 'REF002',
        patientId: patients[1].id,
        specialistId: specialists[1].id,
        status: 'Approved',
        urgency: 'Medium',
        symptomsDescription: 'Recurring headaches and dizziness',
        aiConfidence: 0.76,
        estimatedTime: '1 week',
        department: 'Neurology',
        referringPhysician: 'Dr. Family Medicine',
      ),
    ];

    for (var referral in referrals) {
      await _referralDao.createReferral(referral);
    }
  }

  // Cleanup
  @override
  void dispose() {
    _dbHelper.close();
    super.dispose();
  }
}
