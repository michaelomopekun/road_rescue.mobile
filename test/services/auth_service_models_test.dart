import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/services/auth_service.dart';
import 'package:road_rescue/services/driver_service.dart';
import 'package:road_rescue/services/mechanic_service.dart';

void main() {
  group('Auth Response Models', () {
    group('RegisterResponse', () {
      test('parses registration response', () {
        final json = {
          'id': 'user-001',
          'email': 'john@example.com',
          'role': 'DRIVER',
          'isActive': true,
          'createdAt': '2026-03-15T10:00:00.000Z',
        };

        final response = RegisterResponse.fromJson(json);

        expect(response.id, 'user-001');
        expect(response.email, 'john@example.com');
        expect(response.role, 'DRIVER');
        expect(response.isActive, true);
        expect(response.createdAt, '2026-03-15T10:00:00.000Z');
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'user-002',
          'email': 'mechanic@example.com',
          'role': 'PROVIDER',
        };

        final response = RegisterResponse.fromJson(json);

        expect(response.isActive, true);
        expect(response.createdAt, '');
      });
    });

    group('LoginResponse', () {
      test('parses login response', () {
        final json = {
          'accessToken': 'jwt-token-abc123',
          'userId': 'user-001',
          'phone': '+2348012345678',
          'email': 'john@example.com',
          'role': 'DRIVER',
        };

        final response = LoginResponse.fromJson(json);

        expect(response.accessToken, 'jwt-token-abc123');
        expect(response.userId, 'user-001');
        expect(response.phone, '+2348012345678');
        expect(response.email, 'john@example.com');
        expect(response.role, 'DRIVER');
      });

      test('handles null phone', () {
        final json = {
          'accessToken': 'jwt-token-xyz',
          'userId': 'user-002',
          'email': 'mechanic@example.com',
          'role': 'PROVIDER',
        };

        final response = LoginResponse.fromJson(json);
        expect(response.phone, isNull);
      });
    });

    group('EmailCheckResponse', () {
      test('parses existing email response', () {
        final json = {
          'exists': true,
          'email': 'john@example.com',
          'role': 'DRIVER',
        };

        final response = EmailCheckResponse.fromJson(json);

        expect(response.exists, true);
        expect(response.email, 'john@example.com');
        expect(response.role, 'DRIVER');
      });

      test('handles new email', () {
        final response = EmailCheckResponse(
          exists: false,
          email: 'new@example.com',
          role: null,
        );

        expect(response.exists, false);
        expect(response.role, isNull);
      });
    });

    group('CreateProviderResponse', () {
      test('parses provider creation response', () {
        final json = {
          'id': 'prv-001',
          'userId': 'user-002',
          'providerType': 'INDIVIDUAL',
          'businessName': 'Quick Fix Auto',
          'verificationStatus': 'NOT_VERIFIED',
          'createdAt': '2026-03-15T10:00:00.000Z',
        };

        final response = CreateProviderResponse.fromJson(json);

        expect(response.id, 'prv-001');
        expect(response.userId, 'user-002');
        expect(response.providerType, 'INDIVIDUAL');
        expect(response.businessName, 'Quick Fix Auto');
        expect(response.verificationStatus, 'NOT_VERIFIED');
      });
    });
  });

  group('Driver Service Models', () {
    group('ServiceRequestResponse', () {
      test('parses request with nearby providers', () {
        final json = {
          'id': 'req-001',
          'driverId': 'drv-001',
          'status': 'CREATED',
          'description': 'Flat tire',
          'location': 'Lekki',
          'latitude': 6.43,
          'longitude': 3.47,
          'createdAt': '2026-03-15T10:00:00.000Z',
          'nearbyProviders': [
            {
              'id': 'prv-001',
              'businessName': 'Quick Fix',
              'providerType': 'INDIVIDUAL',
              'businessPhone': '+2348012345',
              'businessAddress': 'Lekki Phase 1',
              'baseLatitude': 6.44,
              'baseLongitude': 3.48,
              'distanceKm': 1.5,
              'verificationStatus': 'APPROVED',
            },
          ],
        };

        final response = ServiceRequestResponse.fromJson(json);

        expect(response.id, 'req-001');
        expect(response.status, 'CREATED');
        expect(response.nearbyProviders.length, 1);
        expect(response.nearbyProviders[0].businessName, 'Quick Fix');
        expect(response.nearbyProviders[0].distanceKm, 1.5);
      });

      test('handles empty nearby providers', () {
        final json = {
          'id': 'req-002',
          'driverId': 'drv-001',
          'description': 'Battery issue',
          'location': 'VI',
          'latitude': 6.42,
          'longitude': 3.42,
          'createdAt': '2026-03-15T10:00:00.000Z',
        };

        final response = ServiceRequestResponse.fromJson(json);
        expect(response.nearbyProviders, isEmpty);
      });
    });

    group('NearbyProvider', () {
      test('parses with default values', () {
        final json = {
          'id': 'prv-001',
          'businessName': 'Test Workshop',
          'baseLatitude': 6.5,
          'baseLongitude': 3.3,
          'distanceKm': 3.0,
        };

        final provider = NearbyProvider.fromJson(json);

        expect(provider.providerType, 'INDIVIDUAL');
        expect(provider.businessPhone, '');
        expect(provider.businessAddress, '');
        expect(provider.verificationStatus, 'APPROVED');
      });
    });

    group('DriverHistoryRequest', () {
      test('generates correct service type labels', () {
        final base = {
          'id': 'req-001',
          'status': 'COMPLETED',
          'location': 'Test',
          'createdAt': '2026-03-15T10:00:00.000Z',
        };

        final flatTire = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'FLAT_TIRE',
        });
        expect(flatTire.serviceTypeLabel, 'Flat Tire');

        final tow = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'TOW',
        });
        expect(tow.serviceTypeLabel, 'Tow Request');

        final battery = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'BATTERY_JUMP',
        });
        expect(battery.serviceTypeLabel, 'Battery Jump');

        final lockout = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'LOCKOUT',
        });
        expect(lockout.serviceTypeLabel, 'Lockout Service');

        final fuel = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'FUEL_DELIVERY',
        });
        expect(fuel.serviceTypeLabel, 'Fuel Delivery');

        final engine = DriverHistoryRequest.fromJson({
          ...base,
          'serviceType': 'ENGINE',
        });
        expect(engine.serviceTypeLabel, 'Engine Check');
      });

      test('formats unknown service type with Title Case', () {
        final request = DriverHistoryRequest.fromJson({
          'id': 'req-001',
          'serviceType': 'CUSTOM_SERVICE_TYPE',
          'status': 'COMPLETED',
          'location': 'Test',
          'createdAt': '2026-03-15T10:00:00.000Z',
        });

        expect(request.serviceTypeLabel, 'Custom Service Type');
      });

      test('handles paginated response', () {
        final json = {
          'data': [
            {
              'id': 'req-001',
              'serviceType': 'FLAT_TIRE',
              'description': 'Flat tire',
              'status': 'COMPLETED',
              'providerName': 'Quick Fix',
              'amount': 15000.0,
              'location': 'Lekki',
              'completedAt': '2026-03-15T12:00:00.000Z',
              'createdAt': '2026-03-15T10:00:00.000Z',
            },
          ],
          'page': 1,
          'limit': 10,
          'total': 25,
          'totalPages': 3,
        };

        final response = DriverRequestHistoryPaginated.fromJson(json);

        expect(response.data.length, 1);
        expect(response.page, 1);
        expect(response.total, 25);
        expect(response.totalPages, 3);
        expect(response.data[0].providerName, 'Quick Fix');
        expect(response.data[0].amount, 15000.0);
      });
    });
  });

  group('Mechanic Service Models', () {
    group('ProviderVerificationStatus', () {
      test('parses approved provider', () {
        final json = {
          'id': 'prv-001',
          'businessName': 'Quick Fix Auto',
          'verificationStatus': 'APPROVED',
          'availabilityStatus': 'AVAILABLE',
          'verifiedAt': '2026-03-10T10:00:00.000Z',
          'createdAt': '2026-03-01T10:00:00.000Z',
          'updatedAt': '2026-03-10T10:00:00.000Z',
        };

        final status = ProviderVerificationStatus.fromJson(json);

        expect(status.verificationStatus, 'APPROVED');
        expect(status.availabilityStatus, 'AVAILABLE');
        expect(status.verifiedAt, isNotNull);
      });

      test('handles pending provider without verifiedAt', () {
        final json = {
          'id': 'prv-002',
          'businessName': 'New Workshop',
          'verificationStatus': 'PENDING',
          'createdAt': '2026-03-15T10:00:00.000Z',
          'updatedAt': '2026-03-15T10:00:00.000Z',
        };

        final status = ProviderVerificationStatus.fromJson(json);

        expect(status.verificationStatus, 'PENDING');
        expect(status.availabilityStatus, isNull);
        expect(status.verifiedAt, isNull);
      });
    });

    group('RecentJob', () {
      test('parses completed job', () {
        final json = {
          'id': 'job-001',
          'customerId': 'drv-001',
          'customerName': 'John Doe',
          'serviceType': 'Flat tire repair',
          'amount': 15000.0,
          'status': 'Paid',
          'completedAt': '2026-03-14T16:00:00.000Z',
          'avatarUrl': 'https://example.com/avatar.jpg',
        };

        final job = RecentJob.fromJson(json);

        expect(job.customerName, 'John Doe');
        expect(job.serviceType, 'Flat tire repair');
        expect(job.amount, 15000.0);
        expect(job.status, 'Paid');
        expect(job.avatarUrl, 'https://example.com/avatar.jpg');
      });

      test('handles null avatar', () {
        final json = {
          'id': 'job-002',
          'customerId': 'drv-002',
          'customerName': 'Jane Doe',
          'serviceType': 'Tow service',
          'amount': 25000.0,
          'completedAt': '2026-03-15T10:00:00.000Z',
        };

        final job = RecentJob.fromJson(json);
        expect(job.avatarUrl, isNull);
      });
    });

    group('ProviderDashboardData', () {
      test('calculates job count from recent jobs', () {
        final dashboard = ProviderDashboardData(
          businessName: 'Quick Fix Auto',
          verificationStatus: 'APPROVED',
          isAvailable: true,
          monthlyEarnings: 150000.0,
          recentJobs: [
            RecentJob(
              id: 'job-1',
              customerId: 'c1',
              customerName: 'Customer 1',
              serviceType: 'Repair',
              amount: 10000,
              status: 'Paid',
              completedAt: DateTime.now(),
            ),
            RecentJob(
              id: 'job-2',
              customerId: 'c2',
              customerName: 'Customer 2',
              serviceType: 'Tow',
              amount: 15000,
              status: 'Paid',
              completedAt: DateTime.now(),
            ),
          ],
        );

        expect(dashboard.jobCount, 2);
        expect(dashboard.totalEarnings, 150000.0);
        expect(dashboard.isAvailable, true);
      });

      test('returns zero job count when no jobs', () {
        final dashboard = ProviderDashboardData(
          businessName: 'New Workshop',
          verificationStatus: 'PENDING',
          isAvailable: false,
          monthlyEarnings: 0.0,
          recentJobs: [],
        );

        expect(dashboard.jobCount, 0);
        expect(dashboard.totalEarnings, 0.0);
      });
    });
  });
}
