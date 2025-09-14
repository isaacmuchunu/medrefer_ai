import 'base_model.dart';

enum ConsentStatus { active, revoked, expired, pending }
enum ConsentType { dataSharing, telemedicine, research, treatment, billing }

class Consent extends BaseModel {
  final String patientId;
  final ConsentType consentType;
  ConsentStatus status;
  final String? grantedBy;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final List<String> scope;
  String? revocationReason;
  final String? notes;

  Consent({
    super.id,
    required this.patientId,
    required this.consentType,
    this.status = ConsentStatus.active,
    this.grantedBy,
    DateTime? grantedAt,
    this.expiresAt,
    this.scope = const [],
    this.revocationReason,
    this.notes,
    super.createdAt,
    super.updatedAt,
  }) : grantedAt = grantedAt ?? DateTime.now();

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'consent_type': consentType.name,
      'status': status.name,
      'granted_by': grantedBy,
      'granted_at': grantedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'scope': BaseModel.stringListToJson(scope),
      'revocation_reason': revocationReason,
      'notes': notes,
    });
    return map;
  }

  factory Consent.fromMap(Map<String, dynamic> map) {
    return Consent(
      id: map['id'],
      patientId: map['patient_id'],
      consentType: ConsentType.values.firstWhere(
        (e) => e.name == (map['consent_type'] ?? 'dataSharing'),
        orElse: () => ConsentType.dataSharing,
      ),
      status: ConsentStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => ConsentStatus.active,
      ),
      grantedBy: map['granted_by'],
      grantedAt: BaseModel.parseDateTime(map['granted_at']),
      expiresAt: BaseModel.parseDateTime(map['expires_at']),
      scope: BaseModel.parseStringList(map['scope']),
      revocationReason: map['revocation_reason'],
      notes: map['notes'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }
}

