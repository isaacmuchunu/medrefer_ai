import 'base_model.dart';

class InventoryItem extends BaseModel {
  @override
  final String id;
  final String name;
  final String description;
  final String category; // 'equipment', 'supplies', 'medications', 'consumables'
  final String subcategory;
  final String sku;
  final String barcode;
  final String manufacturer;
  final String? model;
  final String? serialNumber;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final String unit; // 'pieces', 'boxes', 'liters', 'grams'
  final double unitCost;
  final String currency;
  final String? supplier;
  final String? location;
  final String? departmentId;
  final String? facilityId;
  final DateTime? expiryDate;
  final String status; // 'active', 'inactive', 'discontinued', 'maintenance'
  final String condition; // 'new', 'good', 'fair', 'poor', 'damaged'
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final List<String> tags;
  final Map<String, dynamic> specifications;
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final bool isActive;
  final bool requiresMaintenance;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.sku,
    required this.barcode,
    required this.manufacturer,
    this.model,
    this.serialNumber,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.unit,
    required this.unitCost,
    required this.currency,
    this.supplier,
    this.location,
    this.departmentId,
    this.facilityId,
    this.expiryDate,
    required this.status,
    required this.condition,
    this.lastMaintenance,
    this.nextMaintenance,
    required this.tags,
    required this.specifications,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.requiresMaintenance,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'sku': sku,
      'barcode': barcode,
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'maximum_stock': maximumStock,
      'unit': unit,
      'unit_cost': unitCost,
      'currency': currency,
      'supplier': supplier,
      'location': location,
      'department_id': departmentId,
      'facility_id': facilityId,
      'expiry_date': expiryDate?.toIso8601String(),
      'status': status,
      'condition': condition,
      'last_maintenance': lastMaintenance?.toIso8601String(),
      'next_maintenance': nextMaintenance?.toIso8601String(),
      'tags': tags.join(','),
      'specifications': specifications.toString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'requires_maintenance': requiresMaintenance ? 1 : 0,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'],
      serialNumber: map['serial_number'],
      currentStock: map['current_stock'] ?? 0,
      minimumStock: map['minimum_stock'] ?? 0,
      maximumStock: map['maximum_stock'] ?? 0,
      unit: map['unit'] ?? '',
      unitCost: (map['unit_cost'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      supplier: map['supplier'],
      location: map['location'],
      departmentId: map['department_id'],
      facilityId: map['facility_id'],
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      status: map['status'] ?? '',
      condition: map['condition'] ?? '',
      lastMaintenance: map['last_maintenance'] != null ? DateTime.parse(map['last_maintenance']) : null,
      nextMaintenance: map['next_maintenance'] != null ? DateTime.parse(map['next_maintenance']) : null,
      tags: map['tags']?.split(',') ?? [],
      specifications: map['specifications'] != null ? Map<String, dynamic>.from(map['specifications']) : {},
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] ?? 0) == 1,
      requiresMaintenance: (map['requires_maintenance'] ?? 0) == 1,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? subcategory,
    String? sku,
    String? barcode,
    String? manufacturer,
    String? model,
    String? serialNumber,
    int? currentStock,
    int? minimumStock,
    int? maximumStock,
    String? unit,
    double? unitCost,
    String? currency,
    String? supplier,
    String? location,
    String? departmentId,
    String? facilityId,
    DateTime? expiryDate,
    String? status,
    String? condition,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? requiresMaintenance,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      currency: currency ?? this.currency,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      departmentId: departmentId ?? this.departmentId,
      facilityId: facilityId ?? this.facilityId,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      requiresMaintenance: requiresMaintenance ?? this.requiresMaintenance,
    );
  }

  bool get isLowStock => currentStock <= minimumStock;
  
  bool get isOutOfStock => currentStock <= 0;
  
  bool get isOverstocked => currentStock >= maximumStock;
  
  bool get isExpired => expiryDate != null && DateTime.now().isAfter(expiryDate!);
  
  bool get needsMaintenance => nextMaintenance != null && DateTime.now().isAfter(nextMaintenance!);
  
  double get stockPercentage => maximumStock > 0 ? (currentStock / maximumStock) * 100 : 0;
}