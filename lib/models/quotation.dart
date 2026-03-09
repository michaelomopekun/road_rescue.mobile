class Quotation {
  final String id;
  final List<QuotationItem> items;
  final String description;
  final double totalAmount;
  final String? status;

  Quotation({
    this.id = '',
    required this.items,
    required this.description,
    this.totalAmount = 0.0,
    this.status,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return Quotation(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      items: itemsList
          .map((item) => QuotationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      description: json['description']?.toString() ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'description': description,
    };
  }
}

class QuotationItem {
  final String? id;
  final String description;
  final String type;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double? totalPrice;

  QuotationItem({
    this.id,
    required this.description,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.totalPrice,
  });

  double get total => totalPrice ?? (quantity * unitPrice);

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      id: json['id']?.toString(),
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit']?.toString() ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'type': type,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
    };
  }
}
