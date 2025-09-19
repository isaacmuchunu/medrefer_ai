import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../dao/dao.dart';
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

  final Random _random = Random();

  // Dynamic data generation lists
  final List<String> _firstNames = [
    'James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda',
    'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica',
    'Thomas', 'Sarah', 'Charles', 'Karen', 'Christopher', 'Nancy', 'Daniel', 'Lisa',
    'Matthew', 'Betty', 'Anthony', 'Helen', 'Mark', 'Sandra', 'Donald', 'Donna',
    'Steven', 'Carol', 'Paul', 'Ruth', 'Andrew', 'Sharon', 'Kenneth', 'Michelle',
    'Joshua', 'Laura', 'Kevin', 'Sarah', 'Brian', 'Kimberly', 'George', 'Deborah',
  ];

  final List<String> _lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
    'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas',
    'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson', 'White',
    'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker', 'Young',
    'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
    'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell',
  ];

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  final List<String> _genders = ['Male', 'Female'];
  
  final List<String> _specialties = [
    'Cardiology', 'Dermatology', 'Endocrinology', 'Gastroenterology', 'Hematology',
    'Infectious Disease', 'Nephrology', 'Neurology', 'Oncology', 'Pulmonology',
    'Rheumatology', 'Psychiatry', 'Orthopedics', 'Pediatrics', 'Gynecology',
    'Ophthalmology', 'ENT', 'Urology', 'Anesthesiology', 'Radiology'
  ];

  final List<String> _hospitals = [
    'General Hospital', 'Medical Center', 'Regional Healthcare', 'University Hospital',
    'Community Medical Center', 'St. Mary\'s Hospital', 'Central Hospital',
    'Metropolitan Medical Center', 'City General Hospital', 'Memorial Hospital'
  ];

  final List<String> _conditions = [
    'Hypertension', 'Diabetes Type 2', 'Asthma', 'Arthritis', 'Depression',
    'Anxiety Disorder', 'High Cholesterol', 'COPD', 'Heart Disease', 'Migraine',
    'Fibromyalgia', 'Sleep Apnea', 'Allergies', 'Chronic Pain', 'Thyroid Disorder'
  ];

  final List<String> _medications = [
    'Lisinopril', 'Metformin', 'Amlodipine', 'Metoprolol', 'Omeprazole',
    'Simvastatin', 'Losartan', 'Albuterol', 'Gabapentin', 'Sertraline',
    'Ibuprofen', 'Hydrochlorothiazide', 'Atorvastatin', 'Furosemide', 'Prednisone'
  ];

  final List<String> _streets = [
    'Main St', 'Oak Ave', 'Pine St', 'Elm St', 'Cedar Ave', 'Maple Dr',
    'First St', 'Second Ave', 'Park Blvd', 'Washington St', 'Lincoln Ave',
    'Jefferson Dr', 'Madison St', 'Franklin Ave', 'Roosevelt Blvd'
  ];

  final List<String> _cities = [
    'Springfield', 'Franklin', 'Georgetown', 'Madison', 'Arlington',
    'Centerville', 'Lebanon', 'Kingston', 'Fairview', 'Salem',
    'Bristol', 'Clinton', 'Jackson', 'Marion', 'Troy'
  ];

  final List<String> _states = [
    'CA', 'TX', 'FL', 'NY', 'PA', 'IL', 'OH', 'GA', 'NC', 'MI',
    'VA', 'WA', 'AZ', 'MA', 'TN', 'IN', 'MO', 'MD', 'WI', 'CO'
  ];

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

  /// Dynamically generate and seed patient data
  Future<void> _seedPatients() async {
    try {
      // Generate dynamic patient data instead of using hardcoded data
      final patients = <Patient>[];
      const patientCount = 50; // Generate more realistic number of patients
      
      for (int i = 1; i <= patientCount; i++) {
        final firstName = _firstNames[_random.nextInt(_firstNames.length)];
        final lastName = _lastNames[_random.nextInt(_lastNames.length)];
        final fullName = '$firstName $lastName';
        
        final age = 18 + _random.nextInt(65); // Age between 18-82
        final birthYear = DateTime.now().year - age;
        final birthMonth = 1 + _random.nextInt(12);
        final birthDay = 1 + _random.nextInt(28); // Keep it simple for valid dates
        
        final gender = _genders[_random.nextInt(_genders.length)];
        final bloodType = _bloodTypes[_random.nextInt(_bloodTypes.length)];
        
        final streetNumber = 100 + _random.nextInt(9900);
        final street = _streets[_random.nextInt(_streets.length)];
        final city = _cities[_random.nextInt(_cities.length)];
        final state = _states[_random.nextInt(_states.length)];
        final zipCode = 10000 + _random.nextInt(89999);
        
        // Generate dynamic email and phone
        final emailName = '${firstName.toLowerCase()}.${lastName.toLowerCase()}';
        final domains = ['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'];
        final email = '$emailName@${domains[_random.nextInt(domains.length)]}';
        
        final areaCode = 200 + _random.nextInt(799);
        final phoneMiddle = 100 + _random.nextInt(899);
        final phoneLast = 1000 + _random.nextInt(8999);
        final phone = '+1-$areaCode-$phoneMiddle-$phoneLast';
        
        final patient = Patient(
          name: fullName,
          age: age,
          medicalRecordNumber: 'MRN${i.toString().padLeft(6, '0')}',
          dateOfBirth: DateTime(birthYear, birthMonth, birthDay),
          gender: gender,
          bloodType: bloodType,
          phone: phone,
          email: email,
          address: '$streetNumber $street, $city, $state $zipCode',
        );
        
        patients.add(patient);
      }

      await _patientDao.createMultiplePatients(patients);
      debugPrint('✅ Dynamically generated and seeded ${patients.length} patients');
    } catch (e) {
      debugPrint('❌ Failed to seed patients: $e');
      rethrow;
    }
  }

  /// Dynamically generate and seed specialist data
  Future<void> _seedSpecialists() async {
    try {
      // Generate dynamic specialist data instead of using hardcoded data
      final specialists = <Specialist>[];
      const specialistCount = 30; // Generate realistic number of specialists
      
      final credentials = ['MD', 'MD, PhD', 'MD, FACP', 'MD, FACS', 'MD, FACOG'];
      final languages = [
        ['English'],
        ['English', 'Spanish'],
        ['English', 'French'],
        ['English', 'Mandarin'],
        ['English', 'Portuguese'],
        ['English', 'German'],
        ['English', 'Italian'],
        ['English', 'Korean'],
        ['English', 'Arabic'],
        ['English', 'Russian'],
      ];
      
      final insuranceOptions = [
        ['Blue Cross', 'Aetna', 'Medicare'],
        ['United Healthcare', 'Cigna', 'Medicare'],
        ['All Major Insurance', 'Medicare', 'Medicaid'],
        ['Kaiser Permanente', 'Medicare'],
        ['Humana', 'Medicare', 'Medicaid'],
      ];
      
      final networks = [
        'City Health Network',
        'Metro Health System',
        'University Health System',
        'Regional Medical Network',
        'Community Health Alliance',
      ];
      
      for (int i = 0; i < specialistCount; i++) {
        final firstName = _firstNames[_random.nextInt(_firstNames.length)];
        final lastName = _lastNames[_random.nextInt(_lastNames.length)];
        final fullName = 'Dr. $firstName $lastName';
        
        final specialty = _specialties[_random.nextInt(_specialties.length)];
        final hospital = _hospitals[_random.nextInt(_hospitals.length)];
        final credential = credentials[_random.nextInt(credentials.length)];
        final languageList = languages[_random.nextInt(languages.length)];
        final insuranceList = insuranceOptions[_random.nextInt(insuranceOptions.length)];
        final network = networks[_random.nextInt(networks.length)];
        
        // Generate realistic ratings and success rates
        final rating = 4.0 + (_random.nextDouble() * 1.0); // 4.0 - 5.0
        final successRate = 0.80 + (_random.nextDouble() * 0.18); // 0.80 - 0.98
        
        // Generate coordinates for different locations (simulating different cities)
        final baseLatitude = 40.7128 + (_random.nextDouble() - 0.5) * 0.5; // NYC area variation
        final baseLongitude = -74.0060 + (_random.nextDouble() - 0.5) * 0.5;
        
        final specialist = Specialist(
          name: fullName,
          credentials: credential,
          specialty: specialty,
          hospital: hospital,
          rating: double.parse(rating.toStringAsFixed(1)),
          successRate: double.parse(successRate.toStringAsFixed(2)),
          languages: languageList,
          insurance: insuranceList,
          hospitalNetwork: network,
          latitude: double.parse(baseLatitude.toStringAsFixed(4)),
          longitude: double.parse(baseLongitude.toStringAsFixed(4)),
        );
        
        specialists.add(specialist);
      }

      await _specialistDao.createMultipleSpecialists(specialists);
      debugPrint('✅ Dynamically generated and seeded ${specialists.length} specialists');
    } catch (e) {
      debugPrint('❌ Failed to seed specialists: $e');
      rethrow;
    }
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: patients[0].id,
        bloodPressureSystolic: 120.0,
        bloodPressureDiastolic: 80.0,
        heartRate: 72.0,
        temperature: 98.6,
        oxygenSaturation: 98.0,
        weight: 75.0,
        height: 175.0,
        bmi: 24.5,
        timestamp: DateTime.now(),
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
