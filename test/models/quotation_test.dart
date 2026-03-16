import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/models/quotation.dart';

void main() {
  group('Quotation', () {
    group('fromJson', () {
      test('parses a complete quotation', () {
        final json = {
          'id': 'quot-001',
          'description': 'Engine repair quotation',
          'totalAmount': 25000.0,
          'status': 'PENDING',
          'items': [
            {
              'id': 'item-001',
              'description': 'Spark plugs',
              'type': 'PART',
              'quantity': 4,
              'unit': 'pcs',
              'unitPrice': 2500.0,
              'totalPrice': 10000.0,
            },
            {
              'id': 'item-002',
              'description': 'Labor charge',
              'type': 'LABOR',
              'quantity': 1,
              'unit': 'hr',
              'unitPrice': 15000.0,
              'totalPrice': 15000.0,
            },
          ],
        };

        final quotation = Quotation.fromJson(json);

        expect(quotation.id, 'quot-001');
        expect(quotation.description, 'Engine repair quotation');
        expect(quotation.totalAmount, 25000.0);
        expect(quotation.status, 'PENDING');
        expect(quotation.items.length, 2);
      });

      test('handles missing items list', () {
        final json = {
          'id': 'quot-002',
          'description': 'Empty quotation',
          'totalAmount': 0,
        };

        final quotation = Quotation.fromJson(json);

        expect(quotation.items, isEmpty);
        expect(quotation.totalAmount, 0.0);
      });

      test('handles null/missing fields gracefully', () {
        final json = <String, dynamic>{};

        final quotation = Quotation.fromJson(json);

        expect(quotation.id, '');
        expect(quotation.description, '');
        expect(quotation.totalAmount, 0.0);
        expect(quotation.status, isNull);
        expect(quotation.items, isEmpty);
      });

      test('handles _id field (MongoDB style)', () {
        final json = {
          '_id': 'mongo-quot-123',
          'description': 'Test',
          'items': [],
        };

        final quotation = Quotation.fromJson(json);
        expect(quotation.id, 'mongo-quot-123');
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final quotation = Quotation(
          id: 'quot-001',
          description: 'Test quotation',
          items: [
            QuotationItem(
              description: 'Brake pads',
              type: 'PART',
              quantity: 2,
              unit: 'pcs',
              unitPrice: 5000.0,
            ),
          ],
        );

        final json = quotation.toJson();

        expect(json['id'], 'quot-001');
        expect(json['description'], 'Test quotation');
        expect(json['items'], isA<List>());
        expect((json['items'] as List).length, 1);
      });

      test('omits empty id from JSON', () {
        final quotation = Quotation(
          description: 'New quotation',
          items: [],
        );

        final json = quotation.toJson();

        expect(json.containsKey('id'), false);
      });
    });
  });

  group('QuotationItem', () {
    group('fromJson', () {
      test('parses a complete item', () {
        final json = {
          'id': 'item-001',
          'description': 'Oil filter',
          'type': 'PART',
          'quantity': 1,
          'unit': 'pcs',
          'unitPrice': 3000.0,
          'totalPrice': 3000.0,
        };

        final item = QuotationItem.fromJson(json);

        expect(item.id, 'item-001');
        expect(item.description, 'Oil filter');
        expect(item.type, 'PART');
        expect(item.quantity, 1);
        expect(item.unit, 'pcs');
        expect(item.unitPrice, 3000.0);
        expect(item.totalPrice, 3000.0);
      });

      test('handles missing optional fields', () {
        final json = <String, dynamic>{};

        final item = QuotationItem.fromJson(json);

        expect(item.id, isNull);
        expect(item.description, '');
        expect(item.type, '');
        expect(item.quantity, 1);
        expect(item.unit, '');
        expect(item.unitPrice, 0.0);
        expect(item.totalPrice, isNull);
      });
    });

    group('total', () {
      test('returns totalPrice when available', () {
        final item = QuotationItem(
          description: 'Labor',
          type: 'LABOR',
          quantity: 2,
          unit: 'hr',
          unitPrice: 5000.0,
          totalPrice: 10000.0,
        );

        expect(item.total, 10000.0);
      });

      test('calculates total from quantity × unitPrice when totalPrice is null',
          () {
        final item = QuotationItem(
          description: 'Bolts',
          type: 'PART',
          quantity: 4,
          unit: 'pcs',
          unitPrice: 500.0,
        );

        expect(item.total, 2000.0);
      });
    });

    group('toJson', () {
      test('serializes correctly with id', () {
        final item = QuotationItem(
          id: 'item-001',
          description: 'Brake fluid',
          type: 'PART',
          quantity: 1,
          unit: 'ltr',
          unitPrice: 4000.0,
        );

        final json = item.toJson();

        expect(json['id'], 'item-001');
        expect(json['description'], 'Brake fluid');
        expect(json['type'], 'PART');
        expect(json['quantity'], 1);
        expect(json['unit'], 'ltr');
        expect(json['unitPrice'], 4000.0);
      });

      test('omits null id from JSON', () {
        final item = QuotationItem(
          description: 'New part',
          type: 'PART',
          quantity: 1,
          unit: 'pcs',
          unitPrice: 1000.0,
        );

        final json = item.toJson();

        expect(json.containsKey('id'), false);
      });
    });
  });
}
