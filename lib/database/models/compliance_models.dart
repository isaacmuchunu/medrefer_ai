import 'package:medrefer_ai/core/app_export.dart';

/// Audit log model for compliance tracking
class AuditLog extends BaseModel {
  final String id;
  final String userId;
  final String? organizationId;
  final String action;
  final String resource;
  final String resourceId;
  final String eventType; // create, read, update, delete, login, logout, access
  final String severity; // low, medium, high, critical
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final String? deviceId;
  final Map<String, dynamic> details;
  final Map<String, dynamic> metadata;
  final String? result; // success, failure, error
  final String? errorMessage;
  final DateTime timestamp;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    this.organizationId,
    required this.action,
    required this.resource,
    required this.resourceId,
    required this.eventType,
    required this.severity,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.deviceId,
    this.details = const {},
    this.metadata = const {},
    this.result,
    this.errorMessage,
    required this.timestamp,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'action': action,
      'resource': resource,
      'resource_id': resourceId,
      'event_type': eventType,
      'severity': severity,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'device_id': deviceId,
      'details': jsonEncode(details),
      'metadata': jsonEncode(metadata),
      'result': result,
      'error_message': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      organizationId: map['organization_id'],
      action: map['action'] ?? '',
      resource: map['resource'] ?? '',
      resourceId: map['resource_id'] ?? '',
      eventType: map['event_type'] ?? '',
      severity: map['severity'] ?? 'low',
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      location: map['location'],
      deviceId: map['device_id'],
      details: map['details'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['details'])) 
          : {},
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      result: map['result'],
      errorMessage: map['error_message'],
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Compliance policy model
class CompliancePolicy extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String category; // hipaa, gdpr, sox, pci, iso27001
  final String version;
  final String status; // draft, active, retired
  final String? organizationId;
  final String? departmentId;
  final List<String> requirements;
  final Map<String, dynamic> controls;
  final List<String> applicableRoles;
  final List<String> applicableUsers;
  final DateTime effectiveDate;
  final DateTime? expirationDate;
  final String? policyOwner;
  final String? approvalAuthority;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompliancePolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.version,
    required this.status,
    this.organizationId,
    this.departmentId,
    this.requirements = const [],
    this.controls = const {},
    this.applicableRoles = const [],
    this.applicableUsers = const [],
    required this.effectiveDate,
    this.expirationDate,
    this.policyOwner,
    this.approvalAuthority,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'version': version,
      'status': status,
      'organization_id': organizationId,
      'department_id': departmentId,
      'requirements': jsonEncode(requirements),
      'controls': jsonEncode(controls),
      'applicable_roles': jsonEncode(applicableRoles),
      'applicable_users': jsonEncode(applicableUsers),
      'effective_date': effectiveDate.toIso8601String(),
      'expiration_date': expirationDate?.toIso8601String(),
      'policy_owner': policyOwner,
      'approval_authority': approvalAuthority,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CompliancePolicy.fromMap(Map<String, dynamic> map) {
    return CompliancePolicy(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      version: map['version'] ?? '1.0',
      status: map['status'] ?? 'draft',
      organizationId: map['organization_id'],
      departmentId: map['department_id'],
      requirements: map['requirements'] != null 
          ? List<String>.from(jsonDecode(map['requirements'])) 
          : [],
      controls: map['controls'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['controls'])) 
          : {},
      applicableRoles: map['applicable_roles'] != null 
          ? List<String>.from(jsonDecode(map['applicable_roles'])) 
          : [],
      applicableUsers: map['applicable_users'] != null 
          ? List<String>.from(jsonDecode(map['applicable_users'])) 
          : [],
      effectiveDate: DateTime.parse(map['effective_date'] ?? DateTime.now().toIso8601String()),
      expirationDate: map['expiration_date'] != null 
          ? DateTime.parse(map['expiration_date']) 
          : null,
      policyOwner: map['policy_owner'],
      approvalAuthority: map['approval_authority'],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Compliance assessment model
class ComplianceAssessment extends BaseModel {
  final String id;
  final String policyId;
  final String name;
  final String description;
  final String assessmentType; // self, internal, external
  final String status; // planned, in_progress, completed, failed
  final String? organizationId;
  final String? assessorId;
  final String? assessorName;
  final String? assessorCompany;
  final List<AssessmentControl> controls;
  final Map<String, dynamic> findings;
  final String? overallScore;
  final String? riskLevel; // low, medium, high, critical
  final List<String> recommendations;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? dueDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplianceAssessment({
    required this.id,
    required this.policyId,
    required this.name,
    required this.description,
    required this.assessmentType,
    required this.status,
    this.organizationId,
    this.assessorId,
    this.assessorName,
    this.assessorCompany,
    this.controls = const [],
    this.findings = const {},
    this.overallScore,
    this.riskLevel,
    this.recommendations = const [],
    required this.startDate,
    this.endDate,
    this.dueDate,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'policy_id': policyId,
      'name': name,
      'description': description,
      'assessment_type': assessmentType,
      'status': status,
      'organization_id': organizationId,
      'assessor_id': assessorId,
      'assessor_name': assessorName,
      'assessor_company': assessorCompany,
      'controls': jsonEncode(controls.map((c) => c.toMap()).toList()),
      'findings': jsonEncode(findings),
      'overall_score': overallScore,
      'risk_level': riskLevel,
      'recommendations': jsonEncode(recommendations),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ComplianceAssessment.fromMap(Map<String, dynamic> map) {
    return ComplianceAssessment(
      id: map['id'] ?? '',
      policyId: map['policy_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      assessmentType: map['assessment_type'] ?? '',
      status: map['status'] ?? '',
      organizationId: map['organization_id'],
      assessorId: map['assessor_id'],
      assessorName: map['assessor_name'],
      assessorCompany: map['assessor_company'],
      controls: map['controls'] != null 
          ? (jsonDecode(map['controls']) as List)
              .map((c) => AssessmentControl.fromMap(c))
              .toList()
          : [],
      findings: map['findings'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['findings'])) 
          : {},
      overallScore: map['overall_score'],
      riskLevel: map['risk_level'],
      recommendations: map['recommendations'] != null 
          ? List<String>.from(jsonDecode(map['recommendations'])) 
          : [],
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date']) 
          : null,
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date']) 
          : null,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Assessment control model
class AssessmentControl extends BaseModel {
  final String id;
  final String controlId;
  final String name;
  final String description;
  final String controlType; // administrative, physical, technical
  final String status; // implemented, partially_implemented, not_implemented, not_applicable
  final String? evidence;
  final String? notes;
  final String? assessorComments;
  final String? riskLevel;
  final List<String> gaps;
  final List<String> recommendations;
  final DateTime assessedAt;
  final String? assessedBy;

  AssessmentControl({
    required this.id,
    required this.controlId,
    required this.name,
    required this.description,
    required this.controlType,
    required this.status,
    this.evidence,
    this.notes,
    this.assessorComments,
    this.riskLevel,
    this.gaps = const [],
    this.recommendations = const [],
    required this.assessedAt,
    this.assessedBy,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'control_id': controlId,
      'name': name,
      'description': description,
      'control_type': controlType,
      'status': status,
      'evidence': evidence,
      'notes': notes,
      'assessor_comments': assessorComments,
      'risk_level': riskLevel,
      'gaps': jsonEncode(gaps),
      'recommendations': jsonEncode(recommendations),
      'assessed_at': assessedAt.toIso8601String(),
      'assessed_by': assessedBy,
    };
  }

  factory AssessmentControl.fromMap(Map<String, dynamic> map) {
    return AssessmentControl(
      id: map['id'] ?? '',
      controlId: map['control_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      controlType: map['control_type'] ?? '',
      status: map['status'] ?? '',
      evidence: map['evidence'],
      notes: map['notes'],
      assessorComments: map['assessor_comments'],
      riskLevel: map['risk_level'],
      gaps: map['gaps'] != null 
          ? List<String>.from(jsonDecode(map['gaps'])) 
          : [],
      recommendations: map['recommendations'] != null 
          ? List<String>.from(jsonDecode(map['recommendations'])) 
          : [],
      assessedAt: DateTime.parse(map['assessed_at'] ?? DateTime.now().toIso8601String()),
      assessedBy: map['assessed_by'],
    );
  }
}

/// Compliance violation model
class ComplianceViolation extends BaseModel {
  final String id;
  final String policyId;
  final String violationType; // breach, violation, incident, non_compliance
  final String severity; // low, medium, high, critical
  final String status; // open, investigating, resolved, closed
  final String? organizationId;
  final String? departmentId;
  final String reportedBy;
  final String? assignedTo;
  final String description;
  final String? rootCause;
  final String? impact;
  final String? remediation;
  final List<String> affectedUsers;
  final List<String> affectedData;
  final DateTime discoveredAt;
  final DateTime? resolvedAt;
  final DateTime? dueDate;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplianceViolation({
    required this.id,
    required this.policyId,
    required this.violationType,
    required this.severity,
    required this.status,
    this.organizationId,
    this.departmentId,
    required this.reportedBy,
    this.assignedTo,
    required this.description,
    this.rootCause,
    this.impact,
    this.remediation,
    this.affectedUsers = const [],
    this.affectedData = const [],
    required this.discoveredAt,
    this.resolvedAt,
    this.dueDate,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'policy_id': policyId,
      'violation_type': violationType,
      'severity': severity,
      'status': status,
      'organization_id': organizationId,
      'department_id': departmentId,
      'reported_by': reportedBy,
      'assigned_to': assignedTo,
      'description': description,
      'root_cause': rootCause,
      'impact': impact,
      'remediation': remediation,
      'affected_users': jsonEncode(affectedUsers),
      'affected_data': jsonEncode(affectedData),
      'discovered_at': discoveredAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ComplianceViolation.fromMap(Map<String, dynamic> map) {
    return ComplianceViolation(
      id: map['id'] ?? '',
      policyId: map['policy_id'] ?? '',
      violationType: map['violation_type'] ?? '',
      severity: map['severity'] ?? '',
      status: map['status'] ?? '',
      organizationId: map['organization_id'],
      departmentId: map['department_id'],
      reportedBy: map['reported_by'] ?? '',
      assignedTo: map['assigned_to'],
      description: map['description'] ?? '',
      rootCause: map['root_cause'],
      impact: map['impact'],
      remediation: map['remediation'],
      affectedUsers: map['affected_users'] != null 
          ? List<String>.from(jsonDecode(map['affected_users'])) 
          : [],
      affectedData: map['affected_data'] != null 
          ? List<String>.from(jsonDecode(map['affected_data'])) 
          : [],
      discoveredAt: DateTime.parse(map['discovered_at'] ?? DateTime.now().toIso8601String()),
      resolvedAt: map['resolved_at'] != null 
          ? DateTime.parse(map['resolved_at']) 
          : null,
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date']) 
          : null,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Compliance report model
class ComplianceReport extends BaseModel {
  final String id;
  final String name;
  final String description;
  final String reportType; // audit, assessment, violation, summary
  final String? organizationId;
  final String? policyId;
  final String? assessmentId;
  final String period; // monthly, quarterly, yearly, custom
  final DateTime startDate;
  final DateTime endDate;
  final String status; // draft, generated, approved, distributed
  final String? generatedBy;
  final String? approvedBy;
  final DateTime? generatedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic> data;
  final String? filePath;
  final String? fileFormat; // pdf, excel, csv, json
  final List<String> recipients;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplianceReport({
    required this.id,
    required this.name,
    required this.description,
    required this.reportType,
    this.organizationId,
    this.policyId,
    this.assessmentId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.generatedBy,
    this.approvedBy,
    this.generatedAt,
    this.approvedAt,
    this.data = const {},
    this.filePath,
    this.fileFormat,
    this.recipients = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'report_type': reportType,
      'organization_id': organizationId,
      'policy_id': policyId,
      'assessment_id': assessmentId,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'generated_by': generatedBy,
      'approved_by': approvedBy,
      'generated_at': generatedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'data': jsonEncode(data),
      'file_path': filePath,
      'file_format': fileFormat,
      'recipients': jsonEncode(recipients),
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ComplianceReport.fromMap(Map<String, dynamic> map) {
    return ComplianceReport(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      reportType: map['report_type'] ?? '',
      organizationId: map['organization_id'],
      policyId: map['policy_id'],
      assessmentId: map['assessment_id'],
      period: map['period'] ?? '',
      startDate: DateTime.parse(map['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['end_date'] ?? DateTime.now().toIso8601String()),
      status: map['status'] ?? 'draft',
      generatedBy: map['generated_by'],
      approvedBy: map['approved_by'],
      generatedAt: map['generated_at'] != null 
          ? DateTime.parse(map['generated_at']) 
          : null,
      approvedAt: map['approved_at'] != null 
          ? DateTime.parse(map['approved_at']) 
          : null,
      data: map['data'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['data'])) 
          : {},
      filePath: map['file_path'],
      fileFormat: map['file_format'],
      recipients: map['recipients'] != null 
          ? List<String>.from(jsonDecode(map['recipients'])) 
          : [],
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['metadata'])) 
          : {},
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}