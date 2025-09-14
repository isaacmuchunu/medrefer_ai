import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/database/models/clinical_decision.dart';

void main() {
  group('ClinicalDecision', () {
    late ClinicalDecision decision;

    setUp(() {
      decision = ClinicalDecision(
        id: 'test-id',
        patientId: 'patient-1',
        specialistId: 'specialist-1',
        conditionId: 'condition-1',
        decisionType: 'diagnosis',
        title: 'Test Decision',
        description: 'Test Description',
        rationale: 'Test Rationale',
        confidence: 'high',
        evidence: ['evidence1', 'evidence2'],
        recommendations: ['recommendation1'],
        contraindications: ['contraindication1'],
        status: 'pending',
        priority: 'high',
        createdAt: DateTime.now(),
        metadata: {'key': 'value'},
        isActive: true,
      );
    });

    test('should create clinical decision instance', () {
      expect(decision, isNotNull);
      expect(decision.id, equals('test-id'));
      expect(decision.patientId, equals('patient-1'));
      expect(decision.specialistId, equals('specialist-1'));
      expect(decision.decisionType, equals('diagnosis'));
      expect(decision.title, equals('Test Decision'));
      expect(decision.status, equals('pending'));
      expect(decision.priority, equals('high'));
      expect(decision.confidence, equals('high'));
      expect(decision.isActive, isTrue);
    });

    test('should convert to map', () {
      final map = decision.toMap();
      
      expect(map, isA<Map<String, dynamic>>());
      expect(map['id'], equals('test-id'));
      expect(map['patient_id'], equals('patient-1'));
      expect(map['specialist_id'], equals('specialist-1'));
      expect(map['decision_type'], equals('diagnosis'));
      expect(map['title'], equals('Test Decision'));
      expect(map['status'], equals('pending'));
      expect(map['priority'], equals('high'));
      expect(map['confidence'], equals('high'));
      expect(map['is_active'], equals(1));
      expect(map['evidence'], equals('evidence1,evidence2'));
      expect(map['recommendations'], equals('recommendation1'));
      expect(map['contraindications'], equals('contraindication1'));
    });

    test('should create from map', () {
      final map = {
        'id': 'test-id',
        'patient_id': 'patient-1',
        'specialist_id': 'specialist-1',
        'condition_id': 'condition-1',
        'decision_type': 'diagnosis',
        'title': 'Test Decision',
        'description': 'Test Description',
        'rationale': 'Test Rationale',
        'confidence': 'high',
        'evidence': 'evidence1,evidence2',
        'recommendations': 'recommendation1',
        'contraindications': 'contraindication1',
        'status': 'pending',
        'priority': 'high',
        'created_at': DateTime.now().toIso8601String(),
        'metadata': '{"key": "value"}',
        'is_active': 1,
      };

      final createdDecision = ClinicalDecision.fromMap(map);
      
      expect(createdDecision.id, equals('test-id'));
      expect(createdDecision.patientId, equals('patient-1'));
      expect(createdDecision.specialistId, equals('specialist-1'));
      expect(createdDecision.decisionType, equals('diagnosis'));
      expect(createdDecision.title, equals('Test Decision'));
      expect(createdDecision.status, equals('pending'));
      expect(createdDecision.priority, equals('high'));
      expect(createdDecision.confidence, equals('high'));
      expect(createdDecision.isActive, isTrue);
      expect(createdDecision.evidence, equals(['evidence1', 'evidence2']));
      expect(createdDecision.recommendations, equals(['recommendation1']));
      expect(createdDecision.contraindications, equals(['contraindication1']));
    });

    test('should copy with new values', () {
      final copiedDecision = decision.copyWith(
        status: 'approved',
        priority: 'medium',
        reviewedBy: 'reviewer-1',
        reviewNotes: 'Approved for implementation',
      );

      expect(copiedDecision.id, equals(decision.id));
      expect(copiedDecision.patientId, equals(decision.patientId));
      expect(copiedDecision.specialistId, equals(decision.specialistId));
      expect(copiedDecision.status, equals('approved'));
      expect(copiedDecision.priority, equals('medium'));
      expect(copiedDecision.reviewedBy, equals('reviewer-1'));
      expect(copiedDecision.reviewNotes, equals('Approved for implementation'));
    });

    test('should handle empty evidence, recommendations, and contraindications', () {
      final decisionWithEmptyLists = ClinicalDecision(
        id: 'test-id',
        patientId: 'patient-1',
        specialistId: 'specialist-1',
        conditionId: 'condition-1',
        decisionType: 'diagnosis',
        title: 'Test Decision',
        description: 'Test Description',
        rationale: 'Test Rationale',
        confidence: 'high',
        evidence: [],
        recommendations: [],
        contraindications: [],
        status: 'pending',
        priority: 'high',
        createdAt: DateTime.now(),
        metadata: {},
        isActive: true,
      );

      final map = decisionWithEmptyLists.toMap();
      expect(map['evidence'], equals(''));
      expect(map['recommendations'], equals(''));
      expect(map['contraindications'], equals(''));

      final createdDecision = ClinicalDecision.fromMap(map);
      expect(createdDecision.evidence, equals([]));
      expect(createdDecision.recommendations, equals([]));
      expect(createdDecision.contraindications, equals([]));
    });

    test('should handle null optional fields', () {
      final map = {
        'id': 'test-id',
        'patient_id': 'patient-1',
        'specialist_id': 'specialist-1',
        'condition_id': 'condition-1',
        'decision_type': 'diagnosis',
        'title': 'Test Decision',
        'description': 'Test Description',
        'rationale': 'Test Rationale',
        'confidence': 'high',
        'evidence': '',
        'recommendations': '',
        'contraindications': '',
        'status': 'pending',
        'priority': 'high',
        'created_at': DateTime.now().toIso8601String(),
        'metadata': '{}',
        'is_active': 1,
      };

      final createdDecision = ClinicalDecision.fromMap(map);
      
      expect(createdDecision.reviewedAt, isNull);
      expect(createdDecision.reviewedBy, isNull);
      expect(createdDecision.reviewNotes, isNull);
      expect(createdDecision.expiresAt, isNull);
    });
  });
}