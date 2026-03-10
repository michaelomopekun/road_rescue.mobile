class WalletTransaction {
  final String id;
  final String type; // 'CREDIT' or 'DEBIT'
  final String source; // 'TOP_UP', 'PAYMENT', etc.
  final double amount;
  final String description;
  final String? referenceId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      source: json['source'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      referenceId: json['referenceId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'source': source,
      'amount': amount,
      'description': description,
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TransactionResponse {
  final List<WalletTransaction> transactions;
  final int total;
  final int page;
  final int limit;

  TransactionResponse({
    required this.transactions,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    var list = json['transactions'] as List? ?? [];
    List<WalletTransaction> transactionList = list
        .map((i) => WalletTransaction.fromJson(i))
        .toList();

    return TransactionResponse(
      transactions: transactionList,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }
}
