import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/models/wallet.dart';
import 'package:road_rescue/models/wallet_transaction.dart';

void main() {
  group('Wallet', () {
    group('fromJson', () {
      test('parses wallet data correctly', () {
        final json = {
          'walletId': 'wallet-001',
          'balance': 50000.0,
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.walletId, 'wallet-001');
        expect(wallet.balance, 50000.0);
      });

      test('handles integer balance', () {
        final json = {
          'walletId': 'wallet-002',
          'balance': 25000,
        };

        final wallet = Wallet.fromJson(json);

        expect(wallet.balance, 25000.0);
        expect(wallet.balance, isA<double>());
      });

      test('handles zero balance', () {
        final json = {
          'walletId': 'wallet-003',
          'balance': 0,
        };

        final wallet = Wallet.fromJson(json);
        expect(wallet.balance, 0.0);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final wallet = Wallet(walletId: 'wallet-001', balance: 15000.0);

        final json = wallet.toJson();

        expect(json['walletId'], 'wallet-001');
        expect(json['balance'], 15000.0);
      });
    });
  });

  group('WalletTransaction', () {
    group('fromJson', () {
      test('parses a credit transaction', () {
        final json = {
          'id': 'txn-001',
          'type': 'CREDIT',
          'source': 'TOP_UP',
          'amount': 10000.0,
          'description': 'Wallet top-up',
          'referenceId': 'ref-001',
          'createdAt': '2026-03-15T10:00:00.000Z',
        };

        final txn = WalletTransaction.fromJson(json);

        expect(txn.id, 'txn-001');
        expect(txn.type, 'CREDIT');
        expect(txn.source, 'TOP_UP');
        expect(txn.amount, 10000.0);
        expect(txn.description, 'Wallet top-up');
        expect(txn.referenceId, 'ref-001');
        expect(txn.createdAt.year, 2026);
      });

      test('parses a debit transaction', () {
        final json = {
          'id': 'txn-002',
          'type': 'DEBIT',
          'source': 'PAYMENT',
          'amount': 5000.0,
          'description': 'Service payment',
          'createdAt': '2026-03-14T15:30:00.000Z',
        };

        final txn = WalletTransaction.fromJson(json);

        expect(txn.type, 'DEBIT');
        expect(txn.source, 'PAYMENT');
        expect(txn.referenceId, isNull);
      });

      test('handles missing fields gracefully', () {
        final json = {
          'amount': 1000,
        };

        final txn = WalletTransaction.fromJson(json);

        expect(txn.id, '');
        expect(txn.type, '');
        expect(txn.source, '');
        expect(txn.amount, 1000.0);
        expect(txn.description, '');
      });

      test('handles integer amount', () {
        final json = {
          'id': 'txn-003',
          'type': 'CREDIT',
          'source': 'TOP_UP',
          'amount': 20000,
          'description': 'Top up',
          'createdAt': '2026-03-15T12:00:00.000Z',
        };

        final txn = WalletTransaction.fromJson(json);
        expect(txn.amount, 20000.0);
        expect(txn.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('serializes and round-trips correctly', () {
        final original = WalletTransaction(
          id: 'txn-001',
          type: 'CREDIT',
          source: 'TOP_UP',
          amount: 5000.0,
          description: 'Test top-up',
          referenceId: 'ref-123',
          createdAt: DateTime.parse('2026-03-15T10:00:00.000Z'),
        );

        final json = original.toJson();
        final restored = WalletTransaction.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.source, original.source);
        expect(restored.amount, original.amount);
        expect(restored.description, original.description);
        expect(restored.referenceId, original.referenceId);
      });
    });
  });

  group('TransactionResponse', () {
    test('parses paginated response', () {
      final json = {
        'transactions': [
          {
            'id': 'txn-001',
            'type': 'CREDIT',
            'source': 'TOP_UP',
            'amount': 10000.0,
            'description': 'Top up',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
          {
            'id': 'txn-002',
            'type': 'DEBIT',
            'source': 'PAYMENT',
            'amount': 5000.0,
            'description': 'Payment',
            'createdAt': '2026-03-14T15:00:00.000Z',
          },
        ],
        'total': 10,
        'page': 1,
        'limit': 10,
      };

      final response = TransactionResponse.fromJson(json);

      expect(response.transactions.length, 2);
      expect(response.total, 10);
      expect(response.page, 1);
      expect(response.limit, 10);
      expect(response.transactions[0].type, 'CREDIT');
      expect(response.transactions[1].type, 'DEBIT');
    });

    test('handles empty transactions list', () {
      final json = {
        'transactions': [],
        'total': 0,
        'page': 1,
        'limit': 10,
      };

      final response = TransactionResponse.fromJson(json);

      expect(response.transactions, isEmpty);
      expect(response.total, 0);
    });

    test('handles null transactions field', () {
      final json = <String, dynamic>{
        'total': 0,
        'page': 1,
        'limit': 10,
      };

      final response = TransactionResponse.fromJson(json);
      expect(response.transactions, isEmpty);
    });
  });
}
