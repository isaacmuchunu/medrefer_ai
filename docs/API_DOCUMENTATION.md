# MedRefer AI - API Documentation

## Overview
This document provides comprehensive API documentation for the MedRefer AI healthcare referral system.

## Base URL
- **Development**: `https://dev-api.medrefer.com/v1`
- **Production**: `https://api.medrefer.com/v1`

## Authentication
All API endpoints require authentication using JWT tokens.

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": "user_id",
    "email": "user@example.com",
    "role": "doctor"
  }
}
```

## Sync API Endpoints

### Sync Patient Data
```http
POST /sync/patients
Authorization: Bearer {token}
Content-Type: application/json

{
  "operation": "CREATE",
  "data": {
    "id": "patient_id",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "dateOfBirth": "1990-01-01",
    "medicalHistory": []
  }
}
```

### Sync Referral Data
```http
POST /sync/referrals
Authorization: Bearer {token}
Content-Type: application/json

{
  "operation": "UPDATE",
  "data": {
    "id": "referral_id",
    "patientId": "patient_id",
    "specialistId": "specialist_id",
    "status": "approved",
    "notes": "Updated referral notes"
  }
}
```

## Error Handling

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "email",
      "reason": "Invalid email format"
    }
  }
}
```

### Error Codes
- `AUTHENTICATION_ERROR`: Invalid credentials
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `VALIDATION_ERROR`: Invalid input data
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Resource already exists
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error

## Patient Management API

### Get Patients
```http
GET /patients
Authorization: Bearer {token}
```

### Create Patient
```http
POST /patients
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "dateOfBirth": "1990-01-01",
  "address": {
    "street": "123 Main St",
    "city": "Anytown",
    "state": "ST",
    "zipCode": "12345"
  }
}
```

### Update Patient
```http
PUT /patients/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Doe Updated",
  "email": "john.updated@example.com"
}
```

## Specialist Management API

### Get Specialists
```http
GET /specialists
Authorization: Bearer {token}
```

### Search Specialists
```http
GET /specialists/search?specialty=cardiology&location=city
Authorization: Bearer {token}
```

## Referral Management API

### Create Referral
```http
POST /referrals
Authorization: Bearer {token}
Content-Type: application/json

{
  "patientId": "patient_id",
  "specialistId": "specialist_id",
  "reason": "Chest pain evaluation",
  "urgency": "routine",
  "notes": "Patient reports intermittent chest pain"
}
```

### Update Referral Status
```http
PATCH /referrals/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "approved",
  "notes": "Referral approved by specialist"
}
```

## Messaging API

### Send Message
```http
POST /messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "recipientId": "user_id",
  "subject": "Patient Update",
  "content": "Patient is responding well to treatment",
  "priority": "normal"
}
```

### Get Messages
```http
GET /messages
Authorization: Bearer {token}
```

## Notification API

### Get Notifications
```http
GET /notifications
Authorization: Bearer {token}
```

### Mark Notification as Read
```http
PATCH /notifications/{id}/read
Authorization: Bearer {token}
```

## File Upload API

### Upload Document
```http
POST /documents
Authorization: Bearer {token}
Content-Type: multipart/form-data

file: [binary data]
patientId: patient_id
documentType: medical_record
```

## Analytics API

### Get Dashboard Metrics
```http
GET /analytics/dashboard
Authorization: Bearer {token}
```

**Response:**
```json
{
  "totalPatients": 150,
  "activeReferrals": 25,
  "completedReferrals": 200,
  "pendingMessages": 5
}
```

## Rate Limiting
- **Standard endpoints**: 100 requests per minute
- **Upload endpoints**: 10 requests per minute
- **Authentication endpoints**: 5 requests per minute

## Pagination
All list endpoints support pagination:

```http
GET /patients?page=1&limit=20
```

**Response:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

## Webhooks
Configure webhooks to receive real-time updates:

### Referral Status Change
```json
{
  "event": "referral.status_changed",
  "data": {
    "referralId": "referral_id",
    "oldStatus": "pending",
    "newStatus": "approved",
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

## SDK Integration
Use the official MedRefer AI Flutter SDK for easy integration:

```dart
import 'package:medrefer_ai_sdk/medrefer_ai_sdk.dart';

final client = MedReferClient(
  baseUrl: 'https://api.medrefer.com/v1',
  apiKey: 'your_api_key',
);

// Create patient
final patient = await client.patients.create(
  name: 'John Doe',
  email: 'john@example.com',
);
```

## Testing
Use the sandbox environment for testing:
- **Base URL**: `https://sandbox-api.medrefer.com/v1`
- **Test credentials**: Provided in developer portal

---

**Last Updated**: December 2024
**Version**: 1.0.0
**Maintainer**: MedRefer AI Development Team
