import 'base_model.dart';

class PharmacyDrug extends BaseModel {
  final String name;
  final String genericName;
  final String description;
  final String category;
  final String manufacturer;
  final double price;
  final String dosage;
  final String form; // tablet, capsule, syrup, injection, etc.
  final String strength;
  final bool requiresPrescription;
  final String imageUrl;
  final int stockQuantity;
  final bool isAvailable;
  final List<String> sideEffects;
  final List<String> contraindications;
  final String instructions;
  final DateTime? expiryDate;
  final double rating;
  final int reviewCount;
  final bool isPopular;
  final double discount;

  PharmacyDrug({
    required String id,
    required this.name,
    required this.genericName,
    required this.description,
    required this.category,
    required this.manufacturer,
    required this.price,
    required this.dosage,
    required this.form,
    required this.strength,
    required this.requiresPrescription,
    required this.imageUrl,
    required this.stockQuantity,
    required this.isAvailable,
    required this.sideEffects,
    required this.contraindications,
    required this.instructions,
    this.expiryDate,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isPopular = false,
    this.discount = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

  factory PharmacyDrug.fromMap(Map<String, dynamic> map) {
    return PharmacyDrug(
      id: map['id'],
      name: map['name'] ?? '',
      genericName: map['generic_name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      dosage: map['dosage'] ?? '',
      form: map['form'] ?? '',
      strength: map['strength'] ?? '',
      requiresPrescription: (map['requires_prescription'] ?? 0) == 1,
      imageUrl: map['image_url'] ?? '',
      stockQuantity: map['stock_quantity'] ?? 0,
      isAvailable: (map['is_available'] ?? 1) == 1,
      sideEffects: (map['side_effects'] ?? '').toString().split(',').where((s) => s.trim().isNotEmpty).toList(),
      contraindications: (map['contraindications'] ?? '').toString().split(',').where((s) => s.trim().isNotEmpty).toList(),
      instructions: map['instructions'] ?? '',
      expiryDate: map['expiry_date'] != null ? BaseModel.parseDateTime(map['expiry_date']) : null,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['review_count'] ?? 0,
      isPopular: (map['is_popular'] ?? 0) == 1,
      discount: (map['discount'] ?? 0.0).toDouble(),
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'generic_name': genericName,
      'description': description,
      'category': category,
      'manufacturer': manufacturer,
      'price': price,
      'dosage': dosage,
      'form': form,
      'strength': strength,
      'requires_prescription': requiresPrescription ? 1 : 0,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable ? 1 : 0,
      'side_effects': sideEffects.join(','),
      'contraindications': contraindications.join(','),
      'instructions': instructions,
      'expiry_date': expiryDate?.toIso8601String(),
      'rating': rating,
      'review_count': reviewCount,
      'is_popular': isPopular ? 1 : 0,
      'discount': discount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PharmacyDrug copyWith({
    String? name,
    String? genericName,
    String? description,
    String? category,
    String? manufacturer,
    double? price,
    String? dosage,
    String? form,
    String? strength,
    bool? requiresPrescription,
    String? imageUrl,
    int? stockQuantity,
    bool? isAvailable,
    List<String>? sideEffects,
    List<String>? contraindications,
    String? instructions,
    DateTime? expiryDate,
    double? rating,
    int? reviewCount,
    bool? isPopular,
    double? discount,
  }) {
    return PharmacyDrug(
      id: id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      description: description ?? this.description,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      price: price ?? this.price,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      strength: strength ?? this.strength,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      sideEffects: sideEffects ?? this.sideEffects,
      contraindications: contraindications ?? this.contraindications,
      instructions: instructions ?? this.instructions,
      expiryDate: expiryDate ?? this.expiryDate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isPopular: isPopular ?? this.isPopular,
      discount: discount ?? this.discount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double get discountedPrice => price - (price * discount / 100);
  bool get hasDiscount => discount > 0;
  bool get isInStock => stockQuantity > 0 && isAvailable;

  @override
  String toString() {
    return 'PharmacyDrug(id: $id, name: $name, price: \$${price.toStringAsFixed(2)}, category: $category)';
  }
}

class CartItem extends BaseModel {
  final String drugId;
  final String userId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? prescriptionId;

  CartItem({
    required String id,
    required this.drugId,
    required this.userId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.prescriptionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      drugId: map['drug_id'] ?? '',
      userId: map['user_id'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (map['total_price'] ?? 0.0).toDouble(),
      prescriptionId: map['prescription_id'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drug_id': drugId,
      'user_id': userId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'prescription_id': prescriptionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? drugId,
    String? userId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? prescriptionId,
  }) {
    return CartItem(
      id: id,
      drugId: drugId ?? this.drugId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PharmacyOrder extends BaseModel {
  final String userId;
  final String orderNumber;
  final List<String> cartItemIds;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double totalAmount;
  final OrderStatus status;
  final String deliveryAddress;
  final String? prescriptionId;
  final DateTime? deliveryDate;
  final String? trackingNumber;
  final String? notes;

  PharmacyOrder({
    required String id,
    required this.userId,
    required this.orderNumber,
    required this.cartItemIds,
    required this.subtotal,
    required this.deliveryFee,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.prescriptionId,
    this.deliveryDate,
    this.trackingNumber,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt ?? DateTime.now(),
        );

  factory PharmacyOrder.fromMap(Map<String, dynamic> map) {
    return PharmacyOrder(
      id: map['id'],
      userId: map['user_id'] ?? '',
      orderNumber: map['order_number'] ?? '',
      cartItemIds: (map['cart_item_ids'] ?? '').toString().split(',').where((s) => s.trim().isNotEmpty).toList(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      deliveryFee: (map['delivery_fee'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'pending'), orElse: () => OrderStatus.pending),
      deliveryAddress: map['delivery_address'] ?? '',
      prescriptionId: map['prescription_id'],
      deliveryDate: map['delivery_date'] != null ? BaseModel.parseDateTime(map['delivery_date']) : null,
      trackingNumber: map['tracking_number'],
      notes: map['notes'],
      createdAt: BaseModel.parseDateTime(map['created_at']),
      updatedAt: BaseModel.parseDateTime(map['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'cart_item_ids': cartItemIds.join(','),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'tax': tax,
      'total_amount': totalAmount,
      'status': status.name,
      'delivery_address': deliveryAddress,
      'prescription_id': prescriptionId,
      'delivery_date': deliveryDate?.toIso8601String(),
      'tracking_number': trackingNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}
