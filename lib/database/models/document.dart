import 'base_model.dart';

class Document extends BaseModel {
  String? patientId;
  String? referralId;
  String name;
  String type; // Lab, Image, Prescription, PDF
  String category;
  String? filePath;
  String? fileUrl;
  String? thumbnailUrl;
  int? fileSize;
  DateTime uploadDate;

  Document({
    super.id,
    this.patientId,
    this.referralId,
    required this.name,
    required this.type,
    required this.category,
    this.filePath,
    this.fileUrl,
    this.thumbnailUrl,
    this.fileSize,
    DateTime? uploadDate,
    super.createdAt,
    super.updatedAt,
  }) : uploadDate = uploadDate ?? DateTime.now();

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      patientId: map['patient_id'],
      referralId: map['referral_id'],
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      filePath: map['file_path'],
      fileUrl: map['file_url'],
      thumbnailUrl: map['thumbnail_url'],
      fileSize: map['file_size'],
      uploadDate: BaseModel.parseDateTime(map['upload_date']),
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = baseToMap();
    map.addAll({
      'patient_id': patientId,
      'referral_id': referralId,
      'name': name,
      'type': type,
      'category': category,
      'file_path': filePath,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'file_size': fileSize,
      'upload_date': uploadDate.toIso8601String(),
    });
    return map;
  }

  Document copyWith({
    String? patientId,
    String? referralId,
    String? name,
    String? type,
    String? category,
    String? filePath,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSize,
    DateTime? uploadDate,
  }) {
    return Document(
      id: id,
      patientId: patientId ?? this.patientId,
      referralId: referralId ?? this.referralId,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadDate: uploadDate ?? this.uploadDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods for type checking
  bool get isLabReport => type.toLowerCase() == 'lab';
  bool get isImage => type.toLowerCase() == 'image';
  bool get isPrescription => type.toLowerCase() == 'prescription';
  bool get isPdf => type.toLowerCase() == 'pdf';

  // Helper method for file size formatting
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown size';
    
    if (fileSize! < 1024) {
      return '${fileSize} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'Document{id: $id, name: $name, type: $type, category: $category}';
  }
}
