import 'dart:convert';
import 'package:road_rescue/models/wallet.dart';
import 'package:road_rescue/models/wallet_transaction.dart';
import 'package:road_rescue/services/api_client.dart';
import 'package:road_rescue/services/exceptions.dart';

class WalletService {
  /// Fetch the current wallet balance
  static Future<Wallet> getBalance() async {
    try {
      final response = await ApiClient.get(
        '/wallets/balance',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Wallet.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get wallet balance');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching wallet balance: ${e.toString()}');
    }
  }

  /// Fetch paginated transaction history
  static Future<TransactionResponse> getTransactions({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    try {
      String endpoint = '/wallets/transactions?page=$page&limit=$limit';
      if (type != null && type.isNotEmpty) {
        endpoint += '&type=$type';
      }

      final response = await ApiClient.get(endpoint, requiresAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TransactionResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Failed to get transactions');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error fetching transactions: ${e.toString()}');
    }
  }

  /// Top up the wallet
  static Future<Map<String, dynamic>> topUp(
    double amount, {
    String? idempotencyKey,
  }) async {
    try {
      final Map<String, dynamic> body = {'amount': amount};

      if (idempotencyKey != null) {
        body['idempotencyKey'] = idempotencyKey;
      }

      final response = await ApiClient.post(
        '/wallets/top-up',
        body: body,
        requiresAuth: true,
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        if (response.statusCode == 400 && error['message'] is List) {
          throw ApiException(error['message'].join(', '));
        }
        throw ApiException(error['message'] ?? 'Failed to top up wallet');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error topping up wallet: ${e.toString()}');
    }
  }
}
