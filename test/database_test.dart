import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/database/database.dart';

void main() {
  group('Database Tests', () {
    late DataService dataService;
    late DatabaseHelper dbHelper;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DatabaseHelper();
      dataService = DataService();
      await dataService.initialize();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Database initialization should work', () async {
      expect(dataService.isInitialized, true);
    });

    test('Should create and retrieve patients', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST001',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-TEST',
        email: 'test@example.com',
        address: 'Test Address',
      );

      final patientId = await dataService.createPatient(patient);
      expect(patientId, isNotEmpty);

      final retrievedPatient = await dataService.getPatientById(patientId);
      expect(retrievedPatient, isNotNull);
      expect(retrievedPatient!.name, equals('Test Patient'));
      expect(retrievedPatient.medicalRecordNumber, equals('TEST001'));
    });

    test('Should create and retrieve specialists', () async {
      final specialist = Specialist(
        name: 'Dr. Test Specialist',
        credentials: 'MD',
        specialty: 'Test Specialty',
        hospital: 'Test Hospital',
        rating: 4.5,
        successRate: 0.9,
        languages: ['English'],
        insurance: ['Test Insurance'],
      );

      final specialistId = await dataService.createSpecialist(specialist);
      expect(specialistId, isNotEmpty);

      final retrievedSpecialist = await dataService.getSpecialistById(specialistId);
      expect(retrievedSpecialist, isNotNull);
      expect(retrievedSpecialist!.name, equals('Dr. Test Specialist'));
      expect(retrievedSpecialist.specialty, equals('Test Specialty'));
    });

    test('Should create referrals with patient and specialist', () async {
      // Create patient
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST001',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-TEST',
        email: 'test@example.com',
        address: 'Test Address',
      );
      final patientId = await dataService.createPatient(patient);

      // Create specialist
      final specialist = Specialist(
        name: 'Dr. Test Specialist',
        credentials: 'MD',
        specialty: 'Test Specialty',
        hospital: 'Test Hospital',
        rating: 4.5,
        successRate: 0.9,
        languages: ['English'],
        insurance: ['Test Insurance'],
      );
      final specialistId = await dataService.createSpecialist(specialist);

      // Create referral
      final referral = Referral(
        trackingNumber: 'TEST-REF-001',
        patientId: patientId,
        specialistId: specialistId,
        status: 'Pending',
        urgency: 'Medium',
        symptomsDescription: 'Test symptoms',
        aiConfidence: 0.85,
        estimatedTime: '1 week',
        department: 'Test Department',
        referringPhysician: 'Dr. Test Referring',
      );

      final referralId = await dataService.createReferral(referral);
      expect(referralId, isNotEmpty);

      final retrievedReferral = await dataService.getReferralById(referralId);
      expect(retrievedReferral, isNotNull);
      expect(retrievedReferral!.trackingNumber, equals('TEST-REF-001'));
      expect(retrievedReferral.patientId, equals(patientId));
      expect(retrievedReferral.specialistId, equals(specialistId));
    });

    test('Should get dashboard statistics', () async {
      final stats = await dataService.getDashboardStats();
      expect(stats, isNotNull);
      expect(stats.containsKey('totalPatients'), true);
      expect(stats.containsKey('totalSpecialists'), true);
      expect(stats.containsKey('totalReferrals'), true);
      expect(stats.containsKey('pendingReferrals'), true);
    });

    test('Should search patients by name', () async {
      final patient = Patient(
        name: 'John Search Test',
        age: 30,
        medicalRecordNumber: 'SEARCH001',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-SEARCH',
        email: 'search@example.com',
        address: 'Search Address',
      );

      await dataService.createPatient(patient);

      final searchResults = await dataService.searchPatients('John Search');
      expect(searchResults, isNotEmpty);
      expect(searchResults.any((p) => p.name == 'John Search Test'), true);
    });

    test('Should filter specialists by specialty', () async {
      final specialist = Specialist(
        name: 'Dr. Cardiology Test',
        credentials: 'MD',
        specialty: 'Cardiology',
        hospital: 'Test Hospital',
        rating: 4.5,
        successRate: 0.9,
        languages: ['English'],
        insurance: ['Test Insurance'],
      );

      await dataService.createSpecialist(specialist);

      final cardiologists = await dataService.getSpecialistsBySpecialty('Cardiology');
      expect(cardiologists, isNotEmpty);
      expect(cardiologists.any((s) => s.specialty == 'Cardiology'), true);
    });

    test('Should update referral status', () async {
      // Create a test referral first
      final patient = Patient(
        name: 'Status Test Patient',
        age: 30,
        medicalRecordNumber: 'STATUS001',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
        phone: '+1-555-STATUS',
        email: 'status@example.com',
        address: 'Status Address',
      );
      final patientId = await dataService.createPatient(patient);

      final referral = Referral(
        trackingNumber: 'STATUS-REF-001',
        patientId: patientId,
        status: 'Pending',
        urgency: 'Medium',
        symptomsDescription: 'Status test symptoms',
        aiConfidence: 0.85,
        estimatedTime: '1 week',
        department: 'Test Department',
        referringPhysician: 'Dr. Status Test',
      );

      final referralId = await dataService.createReferral(referral);

      // Update status
      final updateSuccess = await dataService.updateReferralStatus(referralId, 'Approved');
      expect(updateSuccess, true);

      // Verify status was updated
      final updatedReferral = await dataService.getReferralById(referralId);
      expect(updatedReferral!.status, equals('Approved'));
    });

    test('Should create and retrieve conditions', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST001',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
      );
      final patientId = await dataService.createPatient(patient);

      final condition = Condition(
        patientId: patientId,
        name: 'Test Condition',
        severity: 'Mild',
        description: 'Test description',
        diagnosedDate: DateTime.now(),
        diagnosedBy: 'Dr. Test',
        icd10Code: 'T001',
        isActive: true,
      );

      final conditionId = await dataService.createCondition(condition);
      expect(conditionId, isNotEmpty);

      final retrieved = await dataService.getConditionById(conditionId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Condition'));
    });

    test('Should create and retrieve medications', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST002',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
      );
      final patientId = await dataService.createPatient(patient);

      final medication = Medication(
        patientId: patientId,
        name: 'Test Medication',
        dosage: '10mg',
        frequency: 'Daily',
        type: 'Pill',
        status: 'Active',
        startDate: DateTime.now(),
        prescribedBy: 'Dr. Test',
      );

      final medId = await dataService.createMedication(medication);
      expect(medId, isNotEmpty);

      final retrieved = await dataService.getMedicationById(medId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Medication'));
    });

    test('Should create and retrieve documents', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST003',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
      );
      final patientId = await dataService.createPatient(patient);

      final document = Document(
        patientId: patientId,
        name: 'Test Document',
        type: 'pdf',
        category: 'Test',
        filePath: '/test/path',
        fileSize: 1024,
        uploadDate: DateTime.now(),
      );

      final docId = await dataService.createDocument(document);
      expect(docId, isNotEmpty);

      final retrieved = await dataService.getDocumentById(docId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Document'));
    });

    test('Should create and retrieve emergency contacts', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST004',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
      );
      final patientId = await dataService.createPatient(patient);

      final contact = EmergencyContact(
        patientId: patientId,
        name: 'Test Contact',
        relationship: 'Friend',
        phone: '+1-555-TEST',
        email: 'contact@test.com',
        isPrimary: true,
      );

      final contactId = await dataService.createEmergencyContact(contact);
      expect(contactId, isNotEmpty);

      final retrieved = await dataService.getEmergencyContactById(contactId);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Contact'));
    });

    test('Should create and retrieve vital statistics', () async {
      final patient = Patient(
        name: 'Test Patient',
        age: 30,
        medicalRecordNumber: 'TEST005',
        dateOfBirth: DateTime(1994, 1, 1),
        gender: 'Male',
        bloodType: 'O+',
      );
      final patientId = await dataService.createPatient(patient);

      final vital = VitalStatistics(
        patientId: patientId,
        bloodPressure: '120/80',
        heartRate: '72',
        temperature: '98.6',
        oxygenSaturation: '98',
        weight: 70.0,
        height: 170.0,
        bmi: 24.2,
        recordedDate: DateTime.now(),
        recordedBy: 'Nurse Test',
      );

      final vitalId = await dataService.createVitalStatistics(vital);
      expect(vitalId, isNotEmpty);

      final retrieved = await dataService.getVitalStatisticsById(vitalId);
      expect(retrieved, isNotNull);
      expect(retrieved!.bloodPressure, equals('120/80'));
    });
  });
}
