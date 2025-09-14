# MedRefer AI Database Schema

This document outlines the database models, their fields, and relationships.

## Models

### Patient
- id: String
- firstName: String
- lastName: String
- dateOfBirth: DateTime
- gender: String
- contactNumber: String
- email: String
- address: String
- insuranceInfo: String?
- Relationships: Has many Referrals, MedicalHistories, Conditions, Medications, Documents, EmergencyContacts, VitalStatistics (via patientId)

### Specialist
- id: String
- name: String
- specialty: String
- contactInfo: String
- hospital: String
- Relationships: Receives Referrals

### Referral
- id: String
- patientId: String
- specialistId: String
- reason: String
- status: String
- urgency: String
- referralDate: DateTime
- Relationships: Belongs to Patient and Specialist; Has Documents (via referralId)

### Message
- id: String
- senderId: String
- receiverId: String
- content: String
- timestamp: DateTime
- type: String
- status: String
- Relationships: Between users (e.g., Patient and Specialist)

### MedicalHistory
- id: String
- patientId: String
- type: String
- title: String
- description: String?
- date: DateTime
- provider: String?
- location: String?
- icd10Code: String?
- Relationships: Belongs to Patient

### Condition
- id: String
- patientId: String
- name: String
- diagnosisDate: DateTime
- status: String
- severity: String?
- notes: String?
- Relationships: Belongs to Patient

### Medication
- id: String
- patientId: String
- name: String
- dosage: String
- frequency: String
- startDate: DateTime
- endDate: DateTime?
- prescribingDoctor: String?
- Relationships: Belongs to Patient

### Document
- id: String
- patientId: String
- referralId: String?
- type: String
- filePath: String
- uploadDate: DateTime
- description: String?
- Relationships: Belongs to Patient; Optionally to Referral

### EmergencyContact
- id: String
- patientId: String
- name: String
- relationship: String
- phone: String
- email: String?
- isPrimary: bool
- Relationships: Belongs to Patient

### VitalStatistics
- id: String
- patientId: String
- bloodPressure: String?
- heartRate: int?
- temperature: double?
- oxygenSaturation: int?
- weight: double?
- height: double?
- bmi: double?
- recordedDate: DateTime
- recordedBy: String?
- Relationships: Belongs to Patient

## Relationships Summary
- One-to-Many: Patient to Referral, MedicalHistory, Condition, Medication, Document, EmergencyContact, VitalStatistics
- Many-to-One: Referral to Specialist
- Optional: Document to Referral