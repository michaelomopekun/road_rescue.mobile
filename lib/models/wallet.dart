class Wallet {
  final String walletId;
  final double balance;

  Wallet({required this.walletId, required this.balance});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      walletId: json['walletId'] as String,
      // Parse to double handling int values
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'walletId': walletId, 'balance': balance};
  }
}
