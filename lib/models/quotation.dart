class Quotation {
  final String id;
  final List<QuotationItem> items;
  final String description;
  final double totalAmount;

  Quotation({
    this.id = '',
    required this.items,
    required this.description,
    required this.totalAmount,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'description': description,
      'totalAmount': totalAmount,
    };
  }
}

class QuotationItem {
  final String description;
  final String type;
  final int quantity;
  final String unit;
  final double unitPrice;

  QuotationItem({
    required this.description,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit']?.toString() ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'type': type,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
    };
  }
}
