import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/mpesa_config.dart';

/// M-Pesa payment service for handling mobile money transactions
class MpesaService extends ChangeNotifier {
  factory MpesaService() => _instance;
  _MpesaService();

  static final MpesaService _instance = _MpesaService();

  // M-Pesa API Configuration using MpesaConfig
  static String get _baseUrl => MpesaConfig.baseUrl;
  static String get _consumerKey => MpesaConfig.consumerKey;
  static String get _consumerSecret => MpesaConfig.consumerSecret;
  static String get _businessShortCode => MpesaConfig.businessShortCode;
  static String get _passkey => MpesaConfig.passkey;
  static String get _callbackUrl => MpesaConfig.callbackUrl;

  // Payment state
  final Map<String, MpesaTransaction> _transactions = {};
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Getters
  Map<String, MpesaTransaction> get transactions => Map.unmodifiable(_transactions);

  /// Initialize M-Pesa service
  Future<void> initialize() async {
    try {
      if (!MpesaConfig.isConfigured) {
        if (kDebugMode) {
          debugPrint('MpesaService: Warning - M-Pesa credentials not configured');
        }
        return;
      }
      
      await _getAccessToken();
      
      if (kDebugMode) {
        debugPrint('MpesaService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MpesaService: Initialization failed: $e');
      }
      // Don't rethrow to prevent app crash if M-Pesa is not configured
    }
  }

  /// Get OAuth access token
  Future<void> _getAccessToken() async {
    try {
      final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
      
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: int.parse(data['expires_in'])));
        
        if (kDebugMode) {
          debugPrint('MpesaService: Access token obtained');
        }
      } else {
        throw Exception('Failed to get access token: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MpesaService: Error getting access token: $e');
      }
      rethrow;
    }
  }

  /// Check if access token is valid
  bool _isTokenValid() {
    return _accessToken != null && 
           _tokenExpiry != null && 
           DateTime.now().isBefore(_tokenExpiry!);
  }

  /// Ensure we have a valid access token
  Future<void> _ensureValidToken() async {
    if (!_isTokenValid()) {
      await _getAccessToken();
    }
  }

  /// Initiate STK Push payment
  Future<MpesaPaymentResult> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      if (!MpesaConfig.isConfigured) {
        return MpesaPaymentResult(
          success: false,
          message: 'M-Pesa service not configured',
        );
      }

      await _ensureValidToken();

      // Generate transaction ID
      final transactionId = const Uuid().v4();
      
      // Format phone number (remove + and ensure it starts with 254)
      var formattedPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }

      // Generate timestamp
      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^\d]'), '').substring(0, 14);
      
      // Generate password
      final password = base64Encode(utf8.encode('$_businessShortCode$_passkey$timestamp'));

      final requestBody = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt(),
        'PartyA': formattedPhone,
        'PartyB': _businessShortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': _callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['ResponseCode'] == '0') {
        // Create transaction record
        final transaction = MpesaTransaction(
          id: transactionId,
          checkoutRequestId: responseData['CheckoutRequestID'],
          merchantRequestId: responseData['MerchantRequestID'],
          phoneNumber: formattedPhone,
          amount: amount,
          accountReference: accountReference,
          transactionDesc: transactionDesc,
          status: MpesaTransactionStatus.pending,
          timestamp: DateTime.now(),
        );

        _transactions[transactionId] = transaction;
        notifyListeners();

        // Start polling for transaction status
        _pollTransactionStatus(transactionId);

        return MpesaPaymentResult(
          success: true,
          transactionId: transactionId,
          checkoutRequestId: responseData['CheckoutRequestID'],
          message: responseData['CustomerMessage'] ?? 'Payment request sent successfully',
        );
      } else {
        final errorCode = responseData['errorCode']?.toString();
        final errorMessage = errorCode != null
            ? MpesaConfig.getErrorMessage(errorCode)
            : responseData['errorMessage'] ?? 'Payment request failed';
            
        return MpesaPaymentResult(
          success: false,
          message: errorMessage,
          errorCode: errorCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MpesaService: STK Push error: $e');
      }
      return MpesaPaymentResult(
        success: false,
        message: 'Payment request failed: $e',
      );
    }
  }

  /// Poll transaction status
  Future<void> _pollTransactionStatus(String transactionId) async {
    final transaction = _transactions[transactionId];
    if (transaction == null) return;

    // Poll for up to 2 minutes
    var attempts = 0;
    const maxAttempts = 24; // 2 minutes with 5-second intervals

    Timer.periodic(Duration(seconds: 5), (timer) async {
      attempts++;
      
      if (attempts > maxAttempts) {
        timer.cancel();
        _updateTransactionStatus(transactionId, MpesaTransactionStatus.timeout);
        return;
      }

      try {
        final status = await _queryTransactionStatus(transaction.checkoutRequestId);
        
        if (status != MpesaTransactionStatus.pending) {
          timer.cancel();
          _updateTransactionStatus(transactionId, status);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('MpesaService: Error polling transaction status: $e');
        }
      }
    });
  }

  /// Query transaction status
  Future<MpesaTransactionStatus> _queryTransactionStatus(String checkoutRequestId) async {
    try {
      await _ensureValidToken();

      final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^\d]'), '').substring(0, 14);
      final password = base64Encode(utf8.encode('$_businessShortCode$_passkey$timestamp'));

      final requestBody = {
        'BusinessShortCode': _businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final resultCode = responseData['ResultCode']?.toString();
        
        switch (resultCode) {
          case '0':
            return MpesaTransactionStatus.completed;
          case '1032':
            return MpesaTransactionStatus.cancelled;
          case '1037':
            return MpesaTransactionStatus.timeout;
          case '1':
            return MpesaTransactionStatus.failed;
          default:
            return MpesaTransactionStatus.pending;
        }
      } else {
        return MpesaTransactionStatus.pending;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MpesaService: Error querying transaction status: $e');
      }
      return MpesaTransactionStatus.pending;
    }
  }

  /// Update transaction status
  void _updateTransactionStatus(String transactionId, MpesaTransactionStatus status) {
    final transaction = _transactions[transactionId];
    if (transaction != null) {
      _transactions[transactionId] = transaction.copyWith(status: status);
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('MpesaService: Transaction $transactionId status updated to ${status.name}');
      }
    }
  }

  /// Get transaction by ID
  MpesaTransaction? getTransaction(String transactionId) {
    return _transactions[transactionId];
  }

  /// Get transaction status
  MpesaTransactionStatus? getTransactionStatus(String transactionId) {
    return _transactions[transactionId]?.status;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Kenyan number
    if (digitsOnly.length == 9 && digitsOnly.startsWith('7')) {
      return true; // 7XXXXXXXX format
    } else if (digitsOnly.length == 10 && digitsOnly.startsWith('07')) {
      return true; // 07XXXXXXXX format
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('254')) {
      return true; // 254XXXXXXXXX format
    } else if (digitsOnly.length == 13 && digitsOnly.startsWith('2547')) {
      return true; // 2547XXXXXXXX format
    }
    
    return false;
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length >= 9) {
      if (digitsOnly.startsWith('254')) {
        return '+${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
      } else if (digitsOnly.startsWith('07')) {
        return '+254 ${digitsOnly.substring(1, 4)} ${digitsOnly.substring(4)}';
      } else if (digitsOnly.startsWith('7')) {
        return '+254 ${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
      }
    }
    
    return phoneNumber;
  }

  /// Clear completed transactions
  void clearCompletedTransactions() {
    _transactions.removeWhere((key, transaction) =>
      transaction.status == MpesaTransactionStatus.completed ||
      transaction.status == MpesaTransactionStatus.failed ||
      transaction.status == MpesaTransactionStatus.cancelled ||
      transaction.status == MpesaTransactionStatus.timeout
    );
    notifyListeners();
  }


}

/// M-Pesa transaction model
class MpesaTransaction {
  factory MpesaTransaction({
    required String id,
    required String checkoutRequestId,
    required String merchantRequestId,
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
    required MpesaTransactionStatus status,
    required DateTime timestamp,
    String? mpesaReceiptNumber,
  }) {
    return MpesaTransaction._internal(
      id: id,
      checkoutRequestId: checkoutRequestId,
      merchantRequestId: merchantRequestId,
      phoneNumber: phoneNumber,
      amount: amount,
      accountReference: accountReference,
      transactionDesc: transactionDesc,
      status: status,
      timestamp: timestamp,
      mpesaReceiptNumber: mpesaReceiptNumber,
    );
  }
  MpesaTransaction._internal({
    required this.id,
    required this.checkoutRequestId,
    required this.merchantRequestId,
    required this.phoneNumber,
    required this.amount,
    required this.accountReference,
    required this.transactionDesc,
    required this.status,
    required this.timestamp,
    this.mpesaReceiptNumber,
  });
  final String id;
  final String checkoutRequestId;
  final String merchantRequestId;
  final String phoneNumber;
  final double amount;
  final String accountReference;
  final String transactionDesc;
  final MpesaTransactionStatus status;
  final DateTime timestamp;
  final String? mpesaReceiptNumber;

  MpesaTransaction copyWith({
    MpesaTransactionStatus? status,
    String? mpesaReceiptNumber,
  }) {
    return MpesaTransaction(
      id: id,
      checkoutRequestId: checkoutRequestId,
      merchantRequestId: merchantRequestId,
      phoneNumber: phoneNumber,
      amount: amount,
      accountReference: accountReference,
      transactionDesc: transactionDesc,
      status: status ?? this.status,
      timestamp: timestamp,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
    );
  }
}

/// M-Pesa payment result
class MpesaPaymentResult {
  factory MpesaPaymentResult({
    required bool success,
    String? transactionId,
    String? checkoutRequestId,
    required String message,
    String? errorCode,
  }) {
    return MpesaPaymentResult._internal(
      success: success,
      transactionId: transactionId,
      checkoutRequestId: checkoutRequestId,
      message: message,
      errorCode: errorCode,
    );
  }
  MpesaPaymentResult._internal({
    required this.success,
    this.transactionId,
    this.checkoutRequestId,
    required this.message,
    this.errorCode,
  });
  final bool success;
  final String? transactionId;
  final String? checkoutRequestId;
  final String message;
  final String? errorCode;
}

/// M-Pesa transaction status
enum MpesaTransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  timeout,
}
