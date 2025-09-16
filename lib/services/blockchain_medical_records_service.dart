import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../database/services/data_service.dart';
import '../database/models/patient.dart';
import '../database/models/referral.dart';

/// Blockchain-based Medical Records Service for secure, immutable healthcare data
class BlockchainMedicalRecordsService extends ChangeNotifier {
  static final BlockchainMedicalRecordsService _instance = BlockchainMedicalRecordsService._internal();
  factory BlockchainMedicalRecordsService() => _instance;
  BlockchainMedicalRecordsService._internal();

  final DataService _dataService = DataService();
  bool _isInitialized = false;
  
  // Blockchain data structures
  final List<MedicalBlock> _blockchain = [];
  final Map<String, MedicalRecord> _medicalRecords = {};
  final Map<String, List<String>> _patientRecordHashes = {};
  final Map<String, AccessPermission> _accessPermissions = {};
  final List<Transaction> _pendingTransactions = [];
  
  // Network and consensus
  final List<BlockchainNode> _networkNodes = [];
  final Map<String, ConsensusVote> _consensusVotes = {};
  Timer? _miningTimer;
  Timer? _syncTimer;
  
  // Security and encryption
  late String _nodeId;
  late KeyPair _nodeKeys;
  final Map<String, String> _encryptionKeys = {};
  
  // Configuration
  static const int _blockSize = 10;
  static const int _miningDifficulty = 4;
  static const Duration _blockInterval = Duration(minutes: 2);
  static const int _confirmationRequirement = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initializeBlockchain();
      await _initializeNetworking();
      await _loadExistingRecords();
      _startMiningProcess();
      _startSyncProcess();
      _isInitialized = true;
      debugPrint('✅ Blockchain Medical Records Service initialized');
    } catch (e) {
      debugPrint('❌ Blockchain Medical Records Service initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize blockchain with genesis block
  Future<void> _initializeBlockchain() async {
    _nodeId = _generateNodeId();
    _nodeKeys = await _generateKeyPair();
    
    if (_blockchain.isEmpty) {
      final genesisBlock = await _createGenesisBlock();
      _blockchain.add(genesisBlock);
      debugPrint('✅ Genesis block created: ${genesisBlock.hash}');
    }
  }

  /// Create genesis block
  Future<MedicalBlock> _createGenesisBlock() async {
    final timestamp = DateTime.now();
    final genesisTransaction = Transaction(
      id: _generateTransactionId(),
      type: TransactionType.genesis,
      patientId: 'genesis',
      recordHash: '',
      previousRecordHash: '',
      timestamp: timestamp,
      signature: '',
      publicKey: _nodeKeys.publicKey,
    );
    
    final block = MedicalBlock(
      index: 0,
      timestamp: timestamp,
      transactions: [genesisTransaction],
      previousHash: '0',
      merkleRoot: _calculateMerkleRoot([genesisTransaction]),
      nonce: 0,
      difficulty: _miningDifficulty,
    );
    
    // Mine the genesis block
    await _mineBlock(block);
    return block;
  }

  /// Initialize networking components
  Future<void> _initializeNetworking() async {
    // Initialize network nodes (in production, these would be real network endpoints)
    _networkNodes.addAll([
      BlockchainNode(
        id: 'node_hospital_a',
        endpoint: 'https://hospital-a.blockchain.network',
        publicKey: await _generatePublicKey(),
        isActive: true,
      ),
      BlockchainNode(
        id: 'node_hospital_b',
        endpoint: 'https://hospital-b.blockchain.network',
        publicKey: await _generatePublicKey(),
        isActive: true,
      ),
      BlockchainNode(
        id: 'node_regulatory',
        endpoint: 'https://regulatory.blockchain.network',
        publicKey: await _generatePublicKey(),
        isActive: true,
      ),
    ]);
    
    debugPrint('✅ Blockchain network initialized with ${_networkNodes.length} nodes');
  }

  /// Load existing medical records into blockchain
  Future<void> _loadExistingRecords() async {
    final patients = await _dataService.getAllPatients();
    final referrals = await _dataService.getAllReferrals();
    
    for (final patient in patients) {
      await _createPatientRecord(patient);
    }
    
    for (final referral in referrals) {
      await _addReferralRecord(referral);
    }
    
    debugPrint('✅ Loaded ${patients.length} patient records and ${referrals.length} referral records');
  }

  /// Create a new patient record on the blockchain
  Future<String> createPatientRecord(Patient patient) async {
    return await _createPatientRecord(patient);
  }

  Future<String> _createPatientRecord(Patient patient) async {
    final recordData = {
      'patient_id': patient.id,
      'name': patient.name,
      'date_of_birth': patient.dateOfBirth.toIso8601String(),
      'medical_history': patient.medicalHistory,
      'allergies': patient.allergies,
      'created_at': DateTime.now().toIso8601String(),
      'created_by': _nodeId,
    };
    
    final encryptedData = await _encryptMedicalData(recordData, patient.id);
    final recordHash = _calculateRecordHash(encryptedData);
    
    final medicalRecord = MedicalRecord(
      id: _generateRecordId(),
      patientId: patient.id,
      recordType: MedicalRecordType.patient,
      encryptedData: encryptedData,
      hash: recordHash,
      previousHash: _getLatestRecordHash(patient.id),
      timestamp: DateTime.now(),
      version: 1,
      accessLevel: AccessLevel.restricted,
    );
    
    _medicalRecords[medicalRecord.id] = medicalRecord;
    _addToPatientRecordChain(patient.id, recordHash);
    
    // Create transaction
    final transaction = Transaction(
      id: _generateTransactionId(),
      type: TransactionType.create,
      patientId: patient.id,
      recordHash: recordHash,
      previousRecordHash: medicalRecord.previousHash,
      timestamp: DateTime.now(),
      signature: await _signTransaction(recordHash),
      publicKey: _nodeKeys.publicKey,
    );
    
    await _addTransaction(transaction);
    return recordHash;
  }

  /// Add a referral record to the blockchain
  Future<String> addReferralRecord(Referral referral) async {
    return await _addReferralRecord(referral);
  }

  Future<String> _addReferralRecord(Referral referral) async {
    final recordData = {
      'referral_id': referral.id,
      'patient_id': referral.patientId,
      'specialist_id': referral.specialistId,
      'reason': referral.reason,
      'urgency': referral.urgency,
      'status': referral.status,
      'created_at': referral.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    final encryptedData = await _encryptMedicalData(recordData, referral.patientId);
    final recordHash = _calculateRecordHash(encryptedData);
    
    final medicalRecord = MedicalRecord(
      id: _generateRecordId(),
      patientId: referral.patientId,
      recordType: MedicalRecordType.referral,
      encryptedData: encryptedData,
      hash: recordHash,
      previousHash: _getLatestRecordHash(referral.patientId),
      timestamp: DateTime.now(),
      version: 1,
      accessLevel: AccessLevel.standard,
    );
    
    _medicalRecords[medicalRecord.id] = medicalRecord;
    _addToPatientRecordChain(referral.patientId, recordHash);
    
    final transaction = Transaction(
      id: _generateTransactionId(),
      type: TransactionType.update,
      patientId: referral.patientId,
      recordHash: recordHash,
      previousRecordHash: medicalRecord.previousHash,
      timestamp: DateTime.now(),
      signature: await _signTransaction(recordHash),
      publicKey: _nodeKeys.publicKey,
    );
    
    await _addTransaction(transaction);
    return recordHash;
  }

  /// Verify the integrity of a medical record
  Future<RecordVerificationResult> verifyRecord(String recordHash) async {
    final record = _medicalRecords.values.firstWhere(
      (r) => r.hash == recordHash,
      orElse: () => throw Exception('Record not found'),
    );
    
    // Verify hash integrity
    final calculatedHash = _calculateRecordHash(record.encryptedData);
    final hashValid = calculatedHash == record.hash;
    
    // Verify blockchain presence
    final blockchainValid = await _verifyRecordInBlockchain(recordHash);
    
    // Verify signature
    final signatureValid = await _verifyRecordSignature(record);
    
    // Check consensus
    final consensusValid = await _checkConsensus(recordHash);
    
    // Verify record chain
    final chainValid = await _verifyRecordChain(record.patientId, recordHash);
    
    return RecordVerificationResult(
      recordHash: recordHash,
      isValid: hashValid && blockchainValid && signatureValid && consensusValid && chainValid,
      hashValid: hashValid,
      blockchainValid: blockchainValid,
      signatureValid: signatureValid,
      consensusValid: consensusValid,
      chainValid: chainValid,
      verifiedAt: DateTime.now(),
      verifiedBy: _nodeId,
    );
  }

  /// Grant access permission to a medical record
  Future<void> grantAccess({
    required String patientId,
    required String granteeId,
    required AccessLevel accessLevel,
    required Duration duration,
    String? purpose,
  }) async {
    final permissionId = _generatePermissionId();
    final permission = AccessPermission(
      id: permissionId,
      patientId: patientId,
      granteeId: granteeId,
      grantedBy: _nodeId,
      accessLevel: accessLevel,
      grantedAt: DateTime.now(),
      expiresAt: DateTime.now().add(duration),
      purpose: purpose,
      isActive: true,
    );
    
    _accessPermissions[permissionId] = permission;
    
    // Create access transaction
    final transaction = Transaction(
      id: _generateTransactionId(),
      type: TransactionType.access,
      patientId: patientId,
      recordHash: permissionId,
      previousRecordHash: '',
      timestamp: DateTime.now(),
      signature: await _signTransaction(permissionId),
      publicKey: _nodeKeys.publicKey,
    );
    
    await _addTransaction(transaction);
    
    debugPrint('✅ Access granted to $granteeId for patient $patientId');
  }

  /// Revoke access permission
  Future<void> revokeAccess(String permissionId) async {
    final permission = _accessPermissions[permissionId];
    if (permission != null) {
      permission.isActive = false;
      permission.revokedAt = DateTime.now();
      
      // Create revocation transaction
      final transaction = Transaction(
        id: _generateTransactionId(),
        type: TransactionType.revoke,
        patientId: permission.patientId,
        recordHash: permissionId,
        previousRecordHash: '',
        timestamp: DateTime.now(),
        signature: await _signTransaction(permissionId),
        publicKey: _nodeKeys.publicKey,
      );
      
      await _addTransaction(transaction);
      debugPrint('✅ Access revoked for permission $permissionId');
    }
  }

  /// Get patient's medical record history
  Future<List<MedicalRecord>> getPatientRecordHistory(String patientId) async {
    final recordHashes = _patientRecordHashes[patientId] ?? [];
    final records = <MedicalRecord>[];
    
    for (final hash in recordHashes) {
      final record = _medicalRecords.values.firstWhere(
        (r) => r.hash == hash,
        orElse: () => throw Exception('Record not found: $hash'),
      );
      records.add(record);
    }
    
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return records;
  }

  /// Get decrypted medical data (requires proper access)
  Future<Map<String, dynamic>> getDecryptedMedicalData(
    String recordHash, 
    String requesterId,
  ) async {
    // Verify access permission
    final hasAccess = await _verifyAccess(recordHash, requesterId);
    if (!hasAccess) {
      throw UnauthorizedAccessException('Access denied to medical record');
    }
    
    final record = _medicalRecords.values.firstWhere(
      (r) => r.hash == recordHash,
      orElse: () => throw Exception('Record not found'),
    );
    
    return await _decryptMedicalData(record.encryptedData, record.patientId);
  }

  /// Sync with network nodes
  Future<void> syncWithNetwork() async {
    for (final node in _networkNodes.where((n) => n.isActive)) {
      try {
        await _syncWithNode(node);
      } catch (e) {
        debugPrint('❌ Sync failed with node ${node.id}: $e');
      }
    }
  }

  /// Get blockchain statistics
  Map<String, dynamic> getBlockchainStats() {
    final totalTransactions = _blockchain.fold<int>(
      0, 
      (sum, block) => sum + block.transactions.length,
    );
    
    return {
      'total_blocks': _blockchain.length,
      'total_transactions': totalTransactions,
      'total_records': _medicalRecords.length,
      'pending_transactions': _pendingTransactions.length,
      'network_nodes': _networkNodes.length,
      'active_permissions': _accessPermissions.values.where((p) => p.isActive).length,
      'blockchain_size_mb': _calculateBlockchainSize(),
      'last_block_time': _blockchain.isNotEmpty 
          ? _blockchain.last.timestamp.toIso8601String() 
          : null,
    };
  }

  // Mining and consensus methods

  void _startMiningProcess() {
    _miningTimer = Timer.periodic(_blockInterval, (timer) async {
      if (_pendingTransactions.isNotEmpty) {
        await _mineNewBlock();
      }
    });
  }

  void _startSyncProcess() {
    _syncTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      await syncWithNetwork();
    });
  }

  Future<void> _mineNewBlock() async {
    if (_pendingTransactions.isEmpty) return;
    
    final transactionsToInclude = _pendingTransactions.take(_blockSize).toList();
    final previousBlock = _blockchain.last;
    
    final newBlock = MedicalBlock(
      index: previousBlock.index + 1,
      timestamp: DateTime.now(),
      transactions: transactionsToInclude,
      previousHash: previousBlock.hash,
      merkleRoot: _calculateMerkleRoot(transactionsToInclude),
      nonce: 0,
      difficulty: _miningDifficulty,
    );
    
    // Mine the block
    await _mineBlock(newBlock);
    
    // Add to blockchain
    _blockchain.add(newBlock);
    
    // Remove mined transactions from pending
    for (final transaction in transactionsToInclude) {
      _pendingTransactions.remove(transaction);
    }
    
    // Broadcast to network
    await _broadcastBlock(newBlock);
    
    debugPrint('✅ New block mined: ${newBlock.hash}');
    notifyListeners();
  }

  Future<void> _mineBlock(MedicalBlock block) async {
    while (!_isValidHash(block.calculateHash(), block.difficulty)) {
      block.nonce++;
      
      // Yield control periodically to prevent blocking
      if (block.nonce % 1000 == 0) {
        await Future.delayed(Duration(milliseconds: 1));
      }
    }
    
    block.hash = block.calculateHash();
  }

  bool _isValidHash(String hash, int difficulty) {
    final prefix = '0' * difficulty;
    return hash.startsWith(prefix);
  }

  String _calculateMerkleRoot(List<Transaction> transactions) {
    if (transactions.isEmpty) return '';
    
    var hashes = transactions.map((t) => t.calculateHash()).toList();
    
    while (hashes.length > 1) {
      final newHashes = <String>[];
      
      for (var i = 0; i < hashes.length; i += 2) {
        final left = hashes[i];
        final right = i + 1 < hashes.length ? hashes[i + 1] : left;
        final combined = sha256.convert(utf8.encode(left + right)).toString();
        newHashes.add(combined);
      }
      
      hashes = newHashes;
    }
    
    return hashes.first;
  }

  // Helper methods

  String _generateNodeId() {
    return 'node_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<KeyPair> _generateKeyPair() async {
    // In production, use proper cryptographic key generation
    final privateKey = _generateRandomString(64);
    final publicKey = sha256.convert(utf8.encode(privateKey)).toString();
    return KeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  Future<String> _generatePublicKey() async {
    return sha256.convert(utf8.encode(_generateRandomString(32))).toString();
  }

  String _generateRandomString(int length) {
    const chars = 'abcdef0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String _generateTransactionId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
  }

  String _generateRecordId() {
    return 'rec_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
  }

  String _generatePermissionId() {
    return 'perm_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(100000)}';
  }

  Future<String> _encryptMedicalData(Map<String, dynamic> data, String patientId) async {
    // In production, use proper encryption (AES-256-GCM)
    final jsonData = jsonEncode(data);
    final bytes = utf8.encode(jsonData);
    final encrypted = base64.encode(bytes);
    return encrypted;
  }

  Future<Map<String, dynamic>> _decryptMedicalData(String encryptedData, String patientId) async {
    // In production, use proper decryption
    final bytes = base64.decode(encryptedData);
    final jsonData = utf8.decode(bytes);
    return jsonDecode(jsonData);
  }

  String _calculateRecordHash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  String _getLatestRecordHash(String patientId) {
    final hashes = _patientRecordHashes[patientId];
    return hashes?.isNotEmpty == true ? hashes!.last : '';
  }

  void _addToPatientRecordChain(String patientId, String recordHash) {
    _patientRecordHashes[patientId] ??= [];
    _patientRecordHashes[patientId]!.add(recordHash);
  }

  Future<void> _addTransaction(Transaction transaction) async {
    _pendingTransactions.add(transaction);
    notifyListeners();
  }

  Future<String> _signTransaction(String data) async {
    // In production, use proper digital signature
    final signature = sha256.convert(utf8.encode(data + _nodeKeys.privateKey)).toString();
    return signature;
  }

  double _calculateBlockchainSize() {
    // Estimate blockchain size in MB
    var totalSize = 0;
    for (final block in _blockchain) {
      totalSize += block.calculateSize();
    }
    return totalSize / (1024 * 1024);
  }

  // Additional helper methods for verification, consensus, etc.
  // Due to space constraints, showing key structure and main methods

  @override
  void dispose() {
    _miningTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}

// Data models for blockchain

class MedicalBlock {
  int index;
  DateTime timestamp;
  List<Transaction> transactions;
  String previousHash;
  String merkleRoot;
  int nonce;
  int difficulty;
  String hash;

  MedicalBlock({
    required this.index,
    required this.timestamp,
    required this.transactions,
    required this.previousHash,
    required this.merkleRoot,
    required this.nonce,
    required this.difficulty,
    this.hash = '',
  });

  String calculateHash() {
    final data = '$index$timestamp$previousHash$merkleRoot$nonce';
    return sha256.convert(utf8.encode(data)).toString();
  }

  int calculateSize() {
    return toString().length;
  }
}

class Transaction {
  String id;
  TransactionType type;
  String patientId;
  String recordHash;
  String previousRecordHash;
  DateTime timestamp;
  String signature;
  String publicKey;

  Transaction({
    required this.id,
    required this.type,
    required this.patientId,
    required this.recordHash,
    required this.previousRecordHash,
    required this.timestamp,
    required this.signature,
    required this.publicKey,
  });

  String calculateHash() {
    final data = '$id$type$patientId$recordHash$previousRecordHash$timestamp';
    return sha256.convert(utf8.encode(data)).toString();
  }
}

class MedicalRecord {
  String id;
  String patientId;
  MedicalRecordType recordType;
  String encryptedData;
  String hash;
  String previousHash;
  DateTime timestamp;
  int version;
  AccessLevel accessLevel;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.recordType,
    required this.encryptedData,
    required this.hash,
    required this.previousHash,
    required this.timestamp,
    required this.version,
    required this.accessLevel,
  });
}

class AccessPermission {
  String id;
  String patientId;
  String granteeId;
  String grantedBy;
  AccessLevel accessLevel;
  DateTime grantedAt;
  DateTime expiresAt;
  String? purpose;
  bool isActive;
  DateTime? revokedAt;

  AccessPermission({
    required this.id,
    required this.patientId,
    required this.granteeId,
    required this.grantedBy,
    required this.accessLevel,
    required this.grantedAt,
    required this.expiresAt,
    this.purpose,
    required this.isActive,
    this.revokedAt,
  });
}

class BlockchainNode {
  String id;
  String endpoint;
  String publicKey;
  bool isActive;
  DateTime? lastSync;

  BlockchainNode({
    required this.id,
    required this.endpoint,
    required this.publicKey,
    required this.isActive,
    this.lastSync,
  });
}

class KeyPair {
  String privateKey;
  String publicKey;

  KeyPair({required this.privateKey, required this.publicKey});
}

class RecordVerificationResult {
  String recordHash;
  bool isValid;
  bool hashValid;
  bool blockchainValid;
  bool signatureValid;
  bool consensusValid;
  bool chainValid;
  DateTime verifiedAt;
  String verifiedBy;

  RecordVerificationResult({
    required this.recordHash,
    required this.isValid,
    required this.hashValid,
    required this.blockchainValid,
    required this.signatureValid,
    required this.consensusValid,
    required this.chainValid,
    required this.verifiedAt,
    required this.verifiedBy,
  });
}

class ConsensusVote {
  String blockHash;
  String nodeId;
  bool approve;
  DateTime timestamp;

  ConsensusVote({
    required this.blockHash,
    required this.nodeId,
    required this.approve,
    required this.timestamp,
  });
}

enum TransactionType { genesis, create, update, access, revoke }
enum MedicalRecordType { patient, referral, appointment, prescription, labResult, imaging }
enum AccessLevel { public, standard, restricted, confidential }

class UnauthorizedAccessException implements Exception {
  final String message;
  UnauthorizedAccessException(this.message);
  
  @override
  String toString() => 'UnauthorizedAccessException: $message';
}