import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Document security service for handling secure document operations
class DocumentSecurityService {
  static final DocumentSecurityService _instance = DocumentSecurityService._internal();
  factory DocumentSecurityService() => _instance;
  DocumentSecurityService._internal();

  // Security configuration
  static const String _encryptionKey = 'medrefer_ai_doc_key_2024'; // In production, use secure key management
  static const int _maxFileSize = 50 * 1024 * 1024; // 50MB max file size
  static const List<String> _allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
  
  // Access control
  final Map<String, DocumentAccess> _documentAccess = {};
  final Map<String, List<String>> _documentViewers = {}; // Track who viewed what
  
  /// Validate document before upload
  Future<DocumentValidationResult> validateDocument(File file) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > _maxFileSize) {
        return DocumentValidationResult(
          isValid: false,
          error: 'File size exceeds maximum allowed size (50MB)',
        );
      }
      
      // Check file extension
      final fileName = file.path.toLowerCase();
      final hasValidExtension = _allowedExtensions.any((ext) => fileName.endsWith(ext));
      if (!hasValidExtension) {
        return DocumentValidationResult(
          isValid: false,
          error: 'File type not allowed. Supported types: ${_allowedExtensions.join(', ')}',
        );
      }
      
      // Check for malicious content (basic check)
      final bytes = await file.readAsBytes();
      if (await _containsMaliciousContent(bytes)) {
        return DocumentValidationResult(
          isValid: false,
          error: 'File contains potentially malicious content',
        );
      }
      
      return DocumentValidationResult(
        isValid: true,
        fileSize: fileSize,
        mimeType: _getMimeType(fileName),
      );
    } catch (e) {
      return DocumentValidationResult(
        isValid: false,
        error: 'Error validating document: $e',
      );
    }
  }

  /// Encrypt document for secure storage
  Future<File> encryptDocument(File originalFile, String documentId) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final encryptedBytes = _encryptBytes(bytes);
      
      final appDir = await getApplicationDocumentsDirectory();
      final encryptedFile = File('${appDir.path}/encrypted_docs/$documentId.enc');
      
      // Ensure directory exists
      await encryptedFile.parent.create(recursive: true);
      
      await encryptedFile.writeAsBytes(encryptedBytes);
      
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Document encrypted - $documentId');
      }
      
      return encryptedFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Encryption failed: $e');
      }
      rethrow;
    }
  }

  /// Decrypt document for viewing
  Future<File> decryptDocument(String documentId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final encryptedFile = File('${appDir.path}/encrypted_docs/$documentId.enc');
      
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted document not found');
      }
      
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = _decryptBytes(encryptedBytes);
      
      final tempDir = await getTemporaryDirectory();
      final decryptedFile = File('${tempDir.path}/temp_docs/$documentId');
      
      // Ensure directory exists
      await decryptedFile.parent.create(recursive: true);
      
      await decryptedFile.writeAsBytes(decryptedBytes);
      
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Document decrypted - $documentId');
      }
      
      return decryptedFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Decryption failed: $e');
      }
      rethrow;
    }
  }

  /// Check if user has access to document
  bool hasDocumentAccess(String documentId, String userId, DocumentPermission permission) {
    final access = _documentAccess[documentId];
    if (access == null) return false;
    
    // Check if user is owner
    if (access.ownerId == userId) return true;
    
    // Check specific permissions
    final userPermissions = access.userPermissions[userId];
    if (userPermissions == null) return false;
    
    return userPermissions.contains(permission);
  }

  /// Grant document access to user
  void grantDocumentAccess(
    String documentId,
    String userId,
    List<DocumentPermission> permissions, {
    DateTime? expiresAt,
  }) {
    if (!_documentAccess.containsKey(documentId)) {
      _documentAccess[documentId] = DocumentAccess(
        documentId: documentId,
        ownerId: userId,
        userPermissions: {},
        createdAt: DateTime.now(),
      );
    }
    
    _documentAccess[documentId]!.userPermissions[userId] = permissions;
    
    if (kDebugMode) {
      debugPrint('DocumentSecurity: Access granted to $userId for $documentId');
    }
  }

  /// Revoke document access from user
  void revokeDocumentAccess(String documentId, String userId) {
    final access = _documentAccess[documentId];
    if (access != null) {
      access.userPermissions.remove(userId);
      
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Access revoked from $userId for $documentId');
      }
    }
  }

  /// Log document access for audit trail
  Future<void> logDocumentAccess(
    String documentId,
    String userId,
    DocumentAccessType accessType, {
    Map<String, dynamic>? metadata,
  }) async {
    final logEntry = DocumentAccessLog(
      documentId: documentId,
      userId: userId,
      accessType: accessType,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    // Track viewers
    if (accessType == DocumentAccessType.view) {
      if (!_documentViewers.containsKey(documentId)) {
        _documentViewers[documentId] = [];
      }
      if (!_documentViewers[documentId]!.contains(userId)) {
        _documentViewers[documentId]!.add(userId);
      }
    }
    
    // In production, save to secure audit log database
    if (kDebugMode) {
      debugPrint('DocumentSecurity: Access logged - ${logEntry.toJson()}');
    }
  }

  /// Get document access statistics
  DocumentAccessStats getDocumentStats(String documentId) {
    final viewers = _documentViewers[documentId] ?? [];
    final access = _documentAccess[documentId];
    
    return DocumentAccessStats(
      documentId: documentId,
      totalViewers: viewers.length,
      uniqueViewers: viewers,
      hasAccess: access != null,
      createdAt: access?.createdAt,
    );
  }

  /// Clean up temporary decrypted files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempDocsDir = Directory('${tempDir.path}/temp_docs');
      
      if (await tempDocsDir.exists()) {
        await tempDocsDir.delete(recursive: true);
        
        if (kDebugMode) {
          debugPrint('DocumentSecurity: Temporary files cleaned up');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DocumentSecurity: Cleanup failed: $e');
      }
    }
  }

  /// Basic encryption (in production, use proper encryption library)
  List<int> _encryptBytes(List<int> bytes) {
    final key = utf8.encode(_encryptionKey);
    final encrypted = <int>[];
    
    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ key[i % key.length]);
    }
    
    return encrypted;
  }

  /// Basic decryption (in production, use proper decryption library)
  List<int> _decryptBytes(List<int> encryptedBytes) {
    return _encryptBytes(encryptedBytes); // XOR is symmetric
  }

  /// Check for malicious content (basic implementation)
  Future<bool> _containsMaliciousContent(List<int> bytes) async {
    // Basic check for suspicious patterns
    final content = String.fromCharCodes(bytes.take(1024)); // Check first 1KB
    
    final suspiciousPatterns = [
      '<script',
      'javascript:',
      'vbscript:',
      'onload=',
      'onerror=',
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (content.toLowerCase().contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }

  /// Get MIME type from file extension
  String _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.doc')) return 'application/msword';
    if (fileName.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }
}

/// Document validation result
class DocumentValidationResult {
  final bool isValid;
  final String? error;
  final int? fileSize;
  final String? mimeType;

  DocumentValidationResult({
    required this.isValid,
    this.error,
    this.fileSize,
    this.mimeType,
  });
}

/// Document access control
class DocumentAccess {
  final String documentId;
  final String ownerId;
  final Map<String, List<DocumentPermission>> userPermissions;
  final DateTime createdAt;
  DateTime? expiresAt;

  DocumentAccess({
    required this.documentId,
    required this.ownerId,
    required this.userPermissions,
    required this.createdAt,
    this.expiresAt,
  });
}

/// Document permissions
enum DocumentPermission {
  view,
  download,
  share,
  annotate,
  delete,
}

/// Document access types for logging
enum DocumentAccessType {
  view,
  download,
  share,
  annotate,
  delete,
  upload,
}

/// Document access log entry
class DocumentAccessLog {
  final String documentId;
  final String userId;
  final DocumentAccessType accessType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  DocumentAccessLog({
    required this.documentId,
    required this.userId,
    required this.accessType,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'userId': userId,
      'accessType': accessType.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Document access statistics
class DocumentAccessStats {
  final String documentId;
  final int totalViewers;
  final List<String> uniqueViewers;
  final bool hasAccess;
  final DateTime? createdAt;

  DocumentAccessStats({
    required this.documentId,
    required this.totalViewers,
    required this.uniqueViewers,
    required this.hasAccess,
    this.createdAt,
  });
}
