import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/models/service_request.dart';
import 'package:road_rescue/models/request_status.dart';

void main() {
  group('ServiceRequest', () {
    group('fromJson', () {
      test('parses a complete JSON payload', () {
        final json = {
          'id': 'req-001',
          'status': 'ACCEPTED',
          'serviceType': 'FLAT_TIRE',
          'description': 'Flat tire on highway',
          'location': '123 Main Street',
          'latitude': 6.5244,
          'longitude': 3.3792,
          'driverId': 'drv-001',
          'driverName': 'John Doe',
          'driverPhone': '+2348012345678',
          'providerId': 'prv-001',
          'providerName': 'Quick Fix Auto',
          'providerPhone': '+2348098765432',
          'providerLatitude': 6.5300,
          'providerLongitude': 3.3800,
          'distanceKm': 2.5,
          'assignedAt': '2026-03-15T10:00:00.000Z',
          'createdAt': '2026-03-15T09:55:00.000Z',
          'updatedAt': '2026-03-15T10:00:00.000Z',
        };

        final request = ServiceRequest.fromJson(json);

        expect(request.id, 'req-001');
        expect(request.status, RequestStatus.ACCEPTED);
        expect(request.serviceType, 'FLAT_TIRE');
        expect(request.description, 'Flat tire on highway');
        expect(request.location, '123 Main Street');
        expect(request.latitude, 6.5244);
        expect(request.longitude, 3.3792);
        expect(request.driverId, 'drv-001');
        expect(request.driverName, 'John Doe');
        expect(request.driverPhone, '+2348012345678');
        expect(request.providerId, 'prv-001');
        expect(request.providerName, 'Quick Fix Auto');
        expect(request.providerPhone, '+2348098765432');
        expect(request.providerLatitude, 6.5300);
        expect(request.providerLongitude, 3.3800);
        expect(request.distanceKm, 2.5);
        expect(request.assignedAt, isNotNull);
        expect(request.createdAt, isNotNull);
        expect(request.updatedAt, isNotNull);
      });

      test('handles minimal JSON with missing optional fields', () {
        final json = {
          'id': 'req-002',
          'status': 'PENDING',
          'description': 'Engine trouble',
          'location': 'Lekki Phase 1',
          'latitude': 6.4300,
          'longitude': 3.4700,
        };

        final request = ServiceRequest.fromJson(json);

        expect(request.id, 'req-002');
        expect(request.status, RequestStatus.PENDING);
        expect(request.description, 'Engine trouble');
        expect(request.driverName, 'Unknown Driver');
        expect(request.providerId, isNull);
        expect(request.providerName, isNull);
        expect(request.providerLatitude, isNull);
        expect(request.distanceKm, isNull);
        expect(request.assignedAt, isNull);
        expect(request.quotation, isNull);
      });

      test('handles _id field (MongoDB style)', () {
        final json = {
          '_id': 'mongo-id-123',
          'description': 'Battery issue',
          'location': 'VI',
          'latitude': 6.42,
          'longitude': 3.42,
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.id, 'mongo-id-123');
      });

      test('parses string coordinates correctly', () {
        final json = {
          'id': 'req-003',
          'description': 'Lockout',
          'location': 'Ikeja',
          'latitude': '6.6018',
          'longitude': '3.3515',
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.latitude, 6.6018);
        expect(request.longitude, 3.3515);
      });

      test('parses integer coordinates correctly', () {
        final json = {
          'id': 'req-004',
          'description': 'Tow needed',
          'location': 'Ikoyi',
          'latitude': 6,
          'longitude': 3,
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.latitude, 6.0);
        expect(request.longitude, 3.0);
      });

      test('defaults to 0.0 for null coordinates', () {
        final json = {
          'id': 'req-005',
          'description': 'Unknown location',
          'location': 'Unknown',
          'latitude': null,
          'longitude': null,
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.latitude, 0.0);
        expect(request.longitude, 0.0);
      });

      test('handles embedded quotation', () {
        final json = {
          'id': 'req-006',
          'description': 'Brake issue',
          'location': 'Surulere',
          'latitude': 6.5,
          'longitude': 3.35,
          'quotation': {
            'id': 'quot-001',
            'description': 'Brake pad replacement',
            'items': [
              {
                'description': 'Brake pads',
                'type': 'PART',
                'quantity': 2,
                'unit': 'pcs',
                'unitPrice': 5000.0,
              },
            ],
            'totalAmount': 10000.0,
            'status': 'PENDING',
          },
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.quotation, isNotNull);
        expect(request.quotation!.id, 'quot-001');
        expect(request.quotation!.items.length, 1);
        expect(request.quotation!.totalAmount, 10000.0);
      });

      test('falls back to mechanicLatitude/mechanicLongitude', () {
        final json = {
          'id': 'req-007',
          'description': 'Test fallback',
          'location': 'Test',
          'latitude': 6.5,
          'longitude': 3.3,
          'mechanicLatitude': 6.55,
          'mechanicLongitude': 3.35,
        };

        final request = ServiceRequest.fromJson(json);
        expect(request.providerLatitude, 6.55);
        expect(request.providerLongitude, 3.35);
      });
    });

    group('copyWith', () {
      test('creates a copy with updated fields', () {
        final original = ServiceRequest(
          id: 'req-001',
          status: RequestStatus.PENDING,
          description: 'Flat tire',
          location: '123 Main St',
          latitude: 6.5,
          longitude: 3.3,
          driverName: 'John',
        );

        final updated = original.copyWith(
          status: RequestStatus.ACCEPTED,
          providerId: 'prv-001',
          providerName: 'Quick Fix',
        );

        expect(updated.id, 'req-001');
        expect(updated.status, RequestStatus.ACCEPTED);
        expect(updated.description, 'Flat tire');
        expect(updated.providerId, 'prv-001');
        expect(updated.providerName, 'Quick Fix');
        expect(updated.driverName, 'John');
      });

      test('preserves all fields when no updates are specified', () {
        final original = ServiceRequest(
          id: 'req-001',
          status: RequestStatus.ARRIVED,
          description: 'Battery dead',
          location: 'Ajah',
          latitude: 6.47,
          longitude: 3.57,
          driverName: 'Jane',
          providerId: 'prv-002',
        );

        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.status, original.status);
        expect(copy.description, original.description);
        expect(copy.location, original.location);
        expect(copy.latitude, original.latitude);
        expect(copy.longitude, original.longitude);
        expect(copy.driverName, original.driverName);
        expect(copy.providerId, original.providerId);
      });
    });
  });
}
