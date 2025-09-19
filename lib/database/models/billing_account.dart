import 'subscription.dart';

enum BillingCycle { monthly, yearly }

class BillingAccount {
  final String id;
  final String tenantId;
  final String status; // active, suspended, closed
  final String billingName;
  final String billingEmail;
  final String billingAddress;
  final String billingCity;
  final String billingState;
  final String billingZip;
  final String billingCountry;
  final String paymentMethod; // credit_card, bank_transfer, etc.
  final Map<String, dynamic> paymentDetails;
  final double balance;
  final DateTime lastPaymentDate;
  final double lastPaymentAmount;
  final DateTime nextBillingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BillingAccount({
    required this.id,
    required this.tenantId,
    required this.status,
    required this.billingName,
    required this.billingEmail,
    required this.billingAddress,
    required this.billingCity,
    required this.billingState,
    required this.billingZip,
    required this.billingCountry,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.balance,
    required this.lastPaymentDate,
    required this.lastPaymentAmount,
    required this.nextBillingDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'status': status,
      'billingName': billingName,
      'billingEmail': billingEmail,
      'billingAddress': billingAddress,
      'billingCity': billingCity,
      'billingState': billingState,
      'billingZip': billingZip,
      'billingCountry': billingCountry,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'balance': balance,
      'lastPaymentDate': lastPaymentDate.toIso8601String(),
      'lastPaymentAmount': lastPaymentAmount,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BillingAccount.fromMap(Map<String, dynamic> map) {
    return BillingAccount(
      id: map['id'],
      tenantId: map['tenantId'],
      status: map['status'],
      billingName: map['billingName'],
      billingEmail: map['billingEmail'],
      billingAddress: map['billingAddress'],
      billingCity: map['billingCity'],
      billingState: map['billingState'],
      billingZip: map['billingZip'],
      billingCountry: map['billingCountry'],
      paymentMethod: map['paymentMethod'],
      paymentDetails: map['paymentDetails'],
      balance: map['balance'],
      lastPaymentDate: DateTime.parse(map['lastPaymentDate']),
      lastPaymentAmount: map['lastPaymentAmount'],
      nextBillingDate: DateTime.parse(map['nextBillingDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}