import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../dao/dao.dart';
import '../dao/condition_dao.dart';
import '../dao/medication_dao.dart';
import '../dao/document_dao.dart';
import '../dao/emergency_contact_dao.dart';
import '../dao/vital_statistics_dao.dart';
import '../database_helper.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

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

  Future<void> seedComprehensiveData() async {
    try {
      debugPrint('Starting comprehensive data seeding...');
      
      // Check if data already exists
      final patientCount = await _patientDao.getTotalPatientsCount();
      if (patientCount > 10) {
        debugPrint('Data already seeded, skipping...');
        return;
      }

      // Seed patients
      await _seedPatients();
      
      // Seed specialists
      await _seedSpecialists();
      
      // Seed referrals
      await _seedReferrals();
      
      // Seed medical history
      await _seedMedicalHistory();
      
      // Seed messages
      await _seedMessages();
      // Seed conditions
      await _seedConditions();
      // Seed medications
      await _seedMedications();
      // Seed documents
      await _seedDocuments();
      // Seed emergency contacts
      await _seedEmergencyContacts();
      // Seed vital statistics
      await _seedVitalStatistics();

      debugPrint('Comprehensive data seeding completed successfully');
    } catch (e) {
      debugPrint('Failed to seed comprehensive data: $e');
      rethrow;
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
      Patient(
        name: 'Emily Davis',
        age: 28,
        medicalRecordNumber: 'MRN004',
        dateOfBirth: DateTime(1996, 2, 14),
        gender: 'Female',
        bloodType: 'AB+',
        phone: '+1-555-0126',
        email: 'emily.davis@email.com',
        address: '321 Elm St, City, State 12345',
      ),
      Patient(
        name: 'Robert Wilson',
        age: 54,
        medicalRecordNumber: 'MRN005',
        dateOfBirth: DateTime(1970, 9, 3),
        gender: 'Male',
        bloodType: 'O-',
        phone: '+1-555-0127',
        email: 'robert.wilson@email.com',
        address: '654 Maple Ave, City, State 12345',
      ),
      Patient(
        name: 'Lisa Rodriguez',
        age: 39,
        medicalRecordNumber: 'MRN006',
        dateOfBirth: DateTime(1985, 12, 18),
        gender: 'Female',
        bloodType: 'A-',
        phone: '+1-555-0128',
        email: 'lisa.rodriguez@email.com',
        address: '987 Cedar St, City, State 12345',
      ),
      Patient(
        name: 'David Thompson',
        age: 61,
        medicalRecordNumber: 'MRN007',
        dateOfBirth: DateTime(1963, 5, 27),
        gender: 'Male',
        bloodType: 'B-',
        phone: '+1-555-0129',
        email: 'david.thompson@email.com',
        address: '147 Birch Ln, City, State 12345',
      ),
      Patient(
        name: 'Jennifer Lee',
        age: 26,
        medicalRecordNumber: 'MRN008',
        dateOfBirth: DateTime(1998, 8, 11),
        gender: 'Female',
        bloodType: 'AB-',
        phone: '+1-555-0130',
        email: 'jennifer.lee@email.com',
        address: '258 Spruce St, City, State 12345',
      ),
      Patient(
        name: 'Christopher Garcia',
        age: 42,
        medicalRecordNumber: 'MRN009',
        dateOfBirth: DateTime(1982, 1, 9),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-0131',
        email: 'christopher.garcia@email.com',
        address: '369 Willow Dr, City, State 12345',
      ),
      Patient(
        name: 'Amanda Martinez',
        age: 35,
        medicalRecordNumber: 'MRN010',
        dateOfBirth: DateTime(1989, 4, 6),
        gender: 'Female',
        bloodType: 'A+',
        phone: '+1-555-0132',
        email: 'amanda.martinez@email.com',
        address: '741 Poplar Ave, City, State 12345',
      ),
    ];

    await _patientDao.createMultiplePatients(patients);
    debugPrint('Seeded ${patients.length} patients');
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
        latitude: 40.7128,
        longitude: -74.0060,
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
        latitude: 40.7589,
        longitude: -73.9851,
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
        latitude: 40.7505,
        longitude: -73.9934,
      ),
      Specialist(
        name: 'Dr. James Anderson',
        credentials: 'MD, PhD',
        specialty: 'Orthopedics',
        hospital: 'Sports Medicine Institute',
        rating: 4.7,
        successRate: 0.88,
        languages: ['English'],
        insurance: ['Blue Cross', 'United Healthcare', 'Aetna'],
        hospitalNetwork: 'Sports Health Network',
        latitude: 40.7282,
        longitude: -74.0776,
      ),
      Specialist(
        name: 'Dr. Maria Gonzalez',
        credentials: 'MD, FACOG',
        specialty: 'Gynecology',
        hospital: "Women's Health Center",
        rating: 4.9,
        successRate: 0.94,
        languages: ['English', 'Spanish'],
        insurance: ['All Major Insurance', 'Medicare'],
        hospitalNetwork: 'Women\'s Health Network',
        latitude: 40.7614,
        longitude: -73.9776,
      ),
      Specialist(
        name: 'Dr. Kevin Park',
        credentials: 'MD, FACS',
        specialty: 'Surgery',
        hospital: 'Central Surgical Center',
        rating: 4.8,
        successRate: 0.91,
        languages: ['English', 'Korean'],
        insurance: ['Blue Cross', 'Cigna', 'Medicare'],
        hospitalNetwork: 'Surgical Excellence Network',
        latitude: 40.7411,
        longitude: -74.0023,
      ),
      Specialist(
        name: 'Dr. Rachel Green',
        credentials: 'MD, FAAD',
        specialty: 'Dermatology',
        hospital: 'Skin Health Clinic',
        rating: 4.6,
        successRate: 0.87,
        languages: ['English', 'French'],
        insurance: ['United Healthcare', 'Aetna', 'Medicare'],
        hospitalNetwork: 'Dermatology Associates',
        latitude: 40.7831,
        longitude: -73.9712,
      ),
      Specialist(
        name: 'Dr. Thomas Kim',
        credentials: 'MD, FACE',
        specialty: 'Endocrinology',
        hospital: 'Diabetes & Endocrine Center',
        rating: 4.7,
        successRate: 0.90,
        languages: ['English', 'Korean'],
        insurance: ['All Major Insurance', 'Medicare', 'Medicaid'],
        hospitalNetwork: 'Endocrine Health Network',
        latitude: 40.7549,
        longitude: -73.9840,
      ),
    ];

    await _specialistDao.createMultipleSpecialists(specialists);
    debugPrint('Seeded ${specialists.length} specialists');
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
        symptomsDescription: 'Chest pain and shortness of breath during exercise',
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
      Referral(
        trackingNumber: 'REF003',
        patientId: patients[2].id,
        specialistId: specialists[3].id,
        status: 'Urgent',
        urgency: 'Emergency',
        symptomsDescription: 'Severe knee pain after fall',
        aiConfidence: 0.93,
        estimatedTime: 'Same day',
        department: 'Orthopedics',
        referringPhysician: 'Dr. Emergency Medicine',
      ),
      Referral(
        trackingNumber: 'REF004',
        patientId: patients[3].id,
        specialistId: specialists[4].id,
        status: 'Completed',
        urgency: 'Low',
        symptomsDescription: 'Annual gynecological examination',
        aiConfidence: 0.82,
        estimatedTime: '2 weeks',
        department: 'Gynecology',
        referringPhysician: 'Dr. Primary Care',
      ),
      Referral(
        trackingNumber: 'REF005',
        patientId: patients[4].id,
        specialistId: specialists[5].id,
        status: 'Pending',
        urgency: 'High',
        symptomsDescription: 'Suspicious mole requiring biopsy',
        aiConfidence: 0.91,
        estimatedTime: '3-5 days',
        department: 'Surgery',
        referringPhysician: 'Dr. Dermatology',
      ),
    ];

    for (var referral in referrals) {
      await _referralDao.createReferral(referral);
    }
    debugPrint('Seeded ${referrals.length} referrals');
  }

  Future<void> _seedMedicalHistory() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final histories = [
      MedicalHistory(
        patientId: patients[0].id,
        type: 'Diagnosis',
        title: 'Hypertension',
        description: 'Essential hypertension diagnosed during routine checkup',
        date: DateTime.now().subtract(Duration(days: 365)),
        provider: 'Dr. Primary Care',
        location: 'Family Medicine Clinic',
        icd10Code: 'I10',
      ),
      MedicalHistory(
        patientId: patients[0].id,
        type: 'Surgery',
        title: 'Appendectomy',
        description: 'Laparoscopic appendectomy for acute appendicitis',
        date: DateTime.now().subtract(Duration(days: 1095)),
        provider: 'Dr. General Surgery',
        location: 'City General Hospital',
        icd10Code: 'K35.9',
      ),
      MedicalHistory(
        patientId: patients[1].id,
        type: 'Diagnosis',
        title: 'Type 2 Diabetes',
        description: 'Type 2 diabetes mellitus without complications',
        date: DateTime.now().subtract(Duration(days: 730)),
        provider: 'Dr. Endocrinology',
        location: 'Diabetes Center',
        icd10Code: 'E11.9',
      ),
      MedicalHistory(
        patientId: patients[2].id,
        type: 'Procedure',
        title: 'Colonoscopy',
        description: 'Screening colonoscopy - normal findings',
        date: DateTime.now().subtract(Duration(days: 180)),
        provider: 'Dr. Gastroenterology',
        location: 'Endoscopy Center',
        icd10Code: 'Z12.11',
      ),
    ];

    for (var history in histories) {
      await _medicalHistoryDao.createMedicalHistory(history);
    }
    debugPrint('Seeded ${histories.length} medical history records');
  }

  Future<void> _seedMessages() async {
    final referrals = await _referralDao.getAllReferrals();
    if (referrals.isEmpty) return;

    final messages = [
      Message(
        conversationId: 'conv_001',
        senderId: 'user_001',
        senderName: 'Dr. Primary Care',
        content: 'Patient presents with chest pain. Please evaluate for cardiac causes.',
        messageType: 'text',
        referralId: referrals[0].id,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Message(
        conversationId: 'conv_001',
        senderId: 'user_002',
        senderName: 'Dr. Emily Chen',
        content: 'Received the referral. Will schedule EKG and stress test.',
        messageType: 'text',
        referralId: referrals[0].id,
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
      ),
      Message(
        conversationId: 'conv_002',
        senderId: 'user_003',
        senderName: 'Dr. Family Medicine',
        content: 'Patient has been experiencing headaches for 3 weeks.',
        messageType: 'text',
        referralId: referrals[1].id,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
    ];

    for (var message in messages) {
      await _messageDao.createMessage(message);
    }
    debugPrint('Seeded ${messages.length} messages');
  }
  Future<void> _seedConditions() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final conditions = [
      Condition(
        patientId: patients[0].id,
        name: 'Hypertension',
        severity: 'Moderate',
        description: 'Chronic high blood pressure',
        diagnosedDate: DateTime.now().subtract(Duration(days: 365)),
        diagnosedBy: 'Dr. Primary Care',
        icd10Code: 'I10',
        isActive: true,
      ),
      // Add more sample conditions
    ];

    await _conditionDao.createMultipleConditions(conditions);
    debugPrint('Seeded ${conditions.length} conditions');
  }

  Future<void> _seedMedications() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final medications = [
      Medication(
        patientId: patients[0].id,
        name: 'Lisinopril',
        dosage: '10mg',
        frequency: 'Once daily',
        type: 'Tablet',
        status: 'Active',
        startDate: DateTime.now().subtract(Duration(days: 365)),
        prescribedBy: 'Dr. Primary Care',
      ),
      // Add more sample medications
    ];

    await _medicationDao.createMultipleMedications(medications);
    debugPrint('Seeded ${medications.length} medications');
  }

  Future<void> _seedDocuments() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final documents = [
      Document(
        patientId: patients[0].id,
        name: 'Blood Test Results',
        type: 'pdf',
        category: 'Lab Results',
        filePath: '/path/to/document.pdf',
        fileSize: 1024,
        uploadDate: DateTime.now(),
      ),
      // Add more sample documents
    ];

    await _documentDao.createMultipleDocuments(documents);
    debugPrint('Seeded ${documents.length} documents');
  }

  Future<void> _seedEmergencyContacts() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final contacts = [
      EmergencyContact(
        patientId: patients[0].id,
        name: 'Jane Smith',
        relationship: 'Spouse',
        phone: '+1-555-0124',
        email: 'jane.smith@email.com',
        isPrimary: true,
      ),
      // Add more sample contacts
    ];

    await _emergencyContactDao.createMultipleEmergencyContacts(contacts);
    debugPrint('Seeded ${contacts.length} emergency contacts');
  }

  Future<void> _seedVitalStatistics() async {
    final patients = await _patientDao.getAllPatients();
    if (patients.isEmpty) return;

    final vitals = [
      VitalStatistics(
        patientId: patients[0].id,
        bloodPressure: '120/80',
        heartRate: '72',
        temperature: '98.6',
        oxygenSaturation: '98',
        weight: '75.0',
        height: '175.0',
        bmi: '24.5',
        recordedDate: DateTime.now(),
        recordedBy: 'Nurse Practitioner',
      ),
      // Add more sample vitals
    ];

    await _vitalStatisticsDao.createMultipleVitalStatistics(vitals);
    debugPrint('Seeded ${vitals.length} vital statistics');
  }

  Future<void> clearAllData() async {
    try {
      debugPrint('Clearing all data...');
      // Note: Due to foreign key constraints, we need to delete in the right order
      // This is a simplified approach - in production, you might want more sophisticated cleanup
      
      final db = await DatabaseHelper().database;
      await db.delete('messages');
      await db.delete('medical_history');
      await db.delete('medications');
      await db.delete('conditions');
      await db.delete('documents');
      await db.delete('emergency_contacts');
      await db.delete('vital_statistics');
      await db.delete('referrals');
      await db.delete('specialists');
      await db.delete('patients');
      await db.delete('app_settings');
      await db.delete('sync_queue');
      
      debugPrint('All data cleared successfully');
    } catch (e) {
      debugPrint('Failed to clear data: $e');
      rethrow;
    }
  }
}
