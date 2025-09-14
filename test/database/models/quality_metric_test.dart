import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/database/models/quality_metric.dart';

void main() {
  group('QualityMetric', () {
    late QualityMetric metric;

    setUp(() {
      metric = QualityMetric(
        id: 'test-id',
        metricType: 'patient_satisfaction',
        title: 'Test Metric',
        description: 'Test Description',
        category: 'clinical',
        measurement: 'percentage',
        targetValue: 90.0,
        currentValue: 85.0,
        unit: '%',
        period: 'monthly',
        measurementDate: DateTime.now(),
        breakdown: {'key': 'value'},
        tags: ['tag1', 'tag2'],
        status: 'good',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
    });

    test('should create quality metric instance', () {
      expect(metric, isNotNull);
      expect(metric.id, equals('test-id'));
      expect(metric.metricType, equals('patient_satisfaction'));
      expect(metric.title, equals('Test Metric'));
      expect(metric.category, equals('clinical'));
      expect(metric.targetValue, equals(90.0));
      expect(metric.currentValue, equals(85.0));
      expect(metric.unit, equals('%'));
      expect(metric.period, equals('monthly'));
      expect(metric.status, equals('good'));
      expect(metric.isActive, isTrue);
    });

    test('should calculate performance percentage correctly', () {
      expect(metric.performancePercentage, equals(94.44)); // 85/90 * 100
    });

    test('should determine if target is met', () {
      expect(metric.isTargetMet, isFalse); // 85 < 90
      
      final metricWithTargetMet = metric.copyWith(currentValue: 95.0);
      expect(metricWithTargetMet.isTargetMet, isTrue);
    });

    test('should determine performance status', () {
      expect(metric.performanceStatus, equals('good')); // 94.44% >= 80
      
      final excellentMetric = metric.copyWith(currentValue: 95.0);
      expect(excellentMetric.performanceStatus, equals('excellent'));
      
      final fairMetric = metric.copyWith(currentValue: 70.0);
      expect(fairMetric.performanceStatus, equals('fair'));
      
      final poorMetric = metric.copyWith(currentValue: 50.0);
      expect(poorMetric.performanceStatus, equals('poor'));
    });

    test('should convert to map', () {
      final map = metric.toMap();
      
      expect(map, isA<Map<String, dynamic>>());
      expect(map['id'], equals('test-id'));
      expect(map['metric_type'], equals('patient_satisfaction'));
      expect(map['title'], equals('Test Metric'));
      expect(map['category'], equals('clinical'));
      expect(map['target_value'], equals(90.0));
      expect(map['current_value'], equals(85.0));
      expect(map['unit'], equals('%'));
      expect(map['period'], equals('monthly'));
      expect(map['status'], equals('good'));
      expect(map['is_active'], equals(1));
      expect(map['tags'], equals('tag1,tag2'));
    });

    test('should create from map', () {
      final map = {
        'id': 'test-id',
        'metric_type': 'patient_satisfaction',
        'title': 'Test Metric',
        'description': 'Test Description',
        'category': 'clinical',
        'measurement': 'percentage',
        'target_value': 90.0,
        'current_value': 85.0,
        'unit': '%',
        'period': 'monthly',
        'measurement_date': DateTime.now().toIso8601String(),
        'breakdown': '{"key": "value"}',
        'tags': 'tag1,tag2',
        'status': 'good',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      };

      final createdMetric = QualityMetric.fromMap(map);
      
      expect(createdMetric.id, equals('test-id'));
      expect(createdMetric.metricType, equals('patient_satisfaction'));
      expect(createdMetric.title, equals('Test Metric'));
      expect(createdMetric.category, equals('clinical'));
      expect(createdMetric.targetValue, equals(90.0));
      expect(createdMetric.currentValue, equals(85.0));
      expect(createdMetric.unit, equals('%'));
      expect(createdMetric.period, equals('monthly'));
      expect(createdMetric.status, equals('good'));
      expect(createdMetric.isActive, isTrue);
      expect(createdMetric.tags, equals(['tag1', 'tag2']));
    });

    test('should copy with new values', () {
      final copiedMetric = metric.copyWith(
        currentValue: 95.0,
        status: 'excellent',
        notes: 'Updated notes',
      );

      expect(copiedMetric.id, equals(metric.id));
      expect(copiedMetric.metricType, equals(metric.metricType));
      expect(copiedMetric.title, equals(metric.title));
      expect(copiedMetric.currentValue, equals(95.0));
      expect(copiedMetric.status, equals('excellent'));
      expect(copiedMetric.notes, equals('Updated notes'));
    });

    test('should handle empty tags', () {
      final metricWithEmptyTags = QualityMetric(
        id: 'test-id',
        metricType: 'patient_satisfaction',
        title: 'Test Metric',
        description: 'Test Description',
        category: 'clinical',
        measurement: 'percentage',
        targetValue: 90.0,
        currentValue: 85.0,
        unit: '%',
        period: 'monthly',
        measurementDate: DateTime.now(),
        breakdown: {},
        tags: [],
        status: 'good',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final map = metricWithEmptyTags.toMap();
      expect(map['tags'], equals(''));

      final createdMetric = QualityMetric.fromMap(map);
      expect(createdMetric.tags, equals([]));
    });

    test('should handle null optional fields', () {
      final map = {
        'id': 'test-id',
        'metric_type': 'patient_satisfaction',
        'title': 'Test Metric',
        'description': 'Test Description',
        'category': 'clinical',
        'measurement': 'percentage',
        'target_value': 90.0,
        'current_value': 85.0,
        'unit': '%',
        'period': 'monthly',
        'measurement_date': DateTime.now().toIso8601String(),
        'breakdown': '{}',
        'tags': '',
        'status': 'good',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_active': 1,
      };

      final createdMetric = QualityMetric.fromMap(map);
      
      expect(createdMetric.departmentId, isNull);
      expect(createdMetric.specialistId, isNull);
      expect(createdMetric.facilityId, isNull);
      expect(createdMetric.notes, isNull);
    });

    test('should handle zero target value', () {
      final metricWithZeroTarget = metric.copyWith(targetValue: 0.0);
      expect(metricWithZeroTarget.performancePercentage, equals(0.0));
    });
  });
}