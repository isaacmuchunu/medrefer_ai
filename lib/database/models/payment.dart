import 'base_model.dart';

class Payment extends BaseModel {
  final String? patientId;
  final String? referralId;
  final String? appointmentId;
  final double? amount;
  final String? currency;
  final String? paymentMethod;
  final String? status;
  final String? transactionId;
  final DateTime? paymentDate;
  final String? description;
  final String? invoiceNumber;

  Payment({
    super.id,
    this.patientId,
    this.referralId,
    this.appointmentId,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.status,
    this.transactionId,
    this.paymentDate,
    this.description,
    this.invoiceNumber,
    super.createdAt,
    super.updatedAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String?,
      patientId: map['patientId'] as String?,
      referralId: map['referralId'] as String?,
      appointmentId: map['appointmentId'] as String?,
      amount: (map['amount'] as num?)?.toDouble(),
      currency: map['currency'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      status: map['status'] as String?,
      transactionId: map['transactionId'] as String?,
      paymentDate: map['paymentDate'] != null 
          ? DateTime.parse(map['paymentDate'] as String) 
          : null,
      description: map['description'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : null,
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'referralId': referralId,
      'appointmentId': appointmentId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionId': transactionId,
      'paymentDate': paymentDate?.toIso8601String(),
      'description': description,
      'invoiceNumber': invoiceNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? patientId,
    String? referralId,
    String? appointmentId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? status,
    String? transactionId,
    DateTime? paymentDate,
    String? description,
    String? invoiceNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      referralId: referralId ?? this.referralId,
      appointmentId: appointmentId ?? this.appointmentId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      description: description ?? this.description,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}