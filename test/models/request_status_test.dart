import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/models/request_status.dart';

void main() {
  group('RequestStatus', () {
    group('fromString', () {
      test('parses valid status strings correctly', () {
        expect(RequestStatus.fromString('PENDING'), RequestStatus.PENDING);
        expect(RequestStatus.fromString('ACCEPTED'), RequestStatus.ACCEPTED);
        expect(RequestStatus.fromString('ARRIVED'), RequestStatus.ARRIVED);
        expect(RequestStatus.fromString('QUOTED'), RequestStatus.QUOTED);
        expect(
          RequestStatus.fromString('IN_PROGRESS'),
          RequestStatus.IN_PROGRESS,
        );
        expect(RequestStatus.fromString('COMPLETED'), RequestStatus.COMPLETED);
        expect(RequestStatus.fromString('PAID'), RequestStatus.PAID);
        expect(RequestStatus.fromString('CANCELLED'), RequestStatus.CANCELLED);
        expect(
          RequestStatus.fromString('NO_PROVIDER_FOUND'),
          RequestStatus.NO_PROVIDER_FOUND,
        );
      });

      test('is case-insensitive', () {
        expect(RequestStatus.fromString('pending'), RequestStatus.PENDING);
        expect(RequestStatus.fromString('Accepted'), RequestStatus.ACCEPTED);
        expect(
          RequestStatus.fromString('in_progress'),
          RequestStatus.IN_PROGRESS,
        );
      });

      test('defaults to PENDING for unknown status', () {
        expect(RequestStatus.fromString('UNKNOWN'), RequestStatus.PENDING);
        expect(RequestStatus.fromString(''), RequestStatus.PENDING);
        expect(RequestStatus.fromString('foo'), RequestStatus.PENDING);
      });
    });

    group('driverLabel', () {
      test('returns correct driver-facing labels', () {
        expect(RequestStatus.PENDING.driverLabel, 'Searching Mechanics');
        expect(RequestStatus.ACCEPTED.driverLabel, 'Mechanic Accepted');
        expect(RequestStatus.ARRIVED.driverLabel, 'Mechanic Arrived');
        expect(RequestStatus.QUOTED.driverLabel, 'Quotation Received');
        expect(RequestStatus.IN_PROGRESS.driverLabel, 'Service In Progress');
        expect(RequestStatus.COMPLETED.driverLabel, 'Service Completed');
        expect(RequestStatus.PAID.driverLabel, 'Paid');
        expect(RequestStatus.CANCELLED.driverLabel, 'Cancelled');
        expect(
          RequestStatus.NO_PROVIDER_FOUND.driverLabel,
          'No Mechanics Available',
        );
      });
    });

    group('mechanicLabel', () {
      test('returns correct mechanic-facing labels', () {
        expect(RequestStatus.PENDING.mechanicLabel, 'New Request');
        expect(RequestStatus.ACCEPTED.mechanicLabel, 'Accepted');
        expect(RequestStatus.ARRIVED.mechanicLabel, 'Arrived');
        expect(RequestStatus.QUOTED.mechanicLabel, 'Waiting Approval');
        expect(RequestStatus.IN_PROGRESS.mechanicLabel, 'In Progress');
        expect(RequestStatus.COMPLETED.mechanicLabel, 'Waiting Payment');
        expect(RequestStatus.PAID.mechanicLabel, 'Paid');
        expect(RequestStatus.CANCELLED.mechanicLabel, 'Cancelled');
        expect(
          RequestStatus.NO_PROVIDER_FOUND.mechanicLabel,
          'Missed Request',
        );
      });
    });

    group('isValidTransition', () {
      test('PENDING can only transition to ACCEPTED', () {
        expect(RequestStatus.PENDING.isValidTransition(RequestStatus.ACCEPTED),
            true);
        expect(RequestStatus.PENDING.isValidTransition(RequestStatus.ARRIVED),
            false);
        expect(
          RequestStatus.PENDING.isValidTransition(RequestStatus.COMPLETED),
          false,
        );
      });

      test('ACCEPTED can only transition to ARRIVED', () {
        expect(RequestStatus.ACCEPTED.isValidTransition(RequestStatus.ARRIVED),
            true);
        expect(
          RequestStatus.ACCEPTED.isValidTransition(RequestStatus.COMPLETED),
          false,
        );
        expect(RequestStatus.ACCEPTED.isValidTransition(RequestStatus.PENDING),
            false);
      });

      test('ARRIVED can only transition to QUOTED', () {
        expect(
          RequestStatus.ARRIVED.isValidTransition(RequestStatus.QUOTED),
          true,
        );
        expect(
          RequestStatus.ARRIVED.isValidTransition(RequestStatus.IN_PROGRESS),
          false,
        );
      });

      test('QUOTED can only transition to IN_PROGRESS', () {
        expect(
          RequestStatus.QUOTED.isValidTransition(RequestStatus.IN_PROGRESS),
          true,
        );
        expect(
          RequestStatus.QUOTED.isValidTransition(RequestStatus.COMPLETED),
          false,
        );
      });

      test('IN_PROGRESS can only transition to COMPLETED', () {
        expect(
          RequestStatus.IN_PROGRESS
              .isValidTransition(RequestStatus.COMPLETED),
          true,
        );
        expect(
          RequestStatus.IN_PROGRESS.isValidTransition(RequestStatus.PAID),
          false,
        );
      });

      test('COMPLETED can only transition to PAID', () {
        expect(
          RequestStatus.COMPLETED.isValidTransition(RequestStatus.PAID),
          true,
        );
        expect(
          RequestStatus.COMPLETED.isValidTransition(RequestStatus.ACCEPTED),
          false,
        );
      });

      test('PAID is a terminal state', () {
        expect(
          RequestStatus.PAID.isValidTransition(RequestStatus.PENDING),
          false,
        );
        expect(
          RequestStatus.PAID.isValidTransition(RequestStatus.COMPLETED),
          false,
        );
      });

      test('CANCELLED is a terminal state', () {
        expect(
          RequestStatus.CANCELLED.isValidTransition(RequestStatus.PENDING),
          false,
        );
        expect(
          RequestStatus.CANCELLED.isValidTransition(RequestStatus.ACCEPTED),
          false,
        );
      });

      test('NO_PROVIDER_FOUND is a terminal state', () {
        expect(
          RequestStatus.NO_PROVIDER_FOUND
              .isValidTransition(RequestStatus.PENDING),
          false,
        );
      });

      test('can cancel from any non-terminal state', () {
        expect(
          RequestStatus.PENDING.isValidTransition(RequestStatus.CANCELLED),
          true,
        );
        expect(
          RequestStatus.ACCEPTED.isValidTransition(RequestStatus.CANCELLED),
          true,
        );
        expect(
          RequestStatus.ARRIVED.isValidTransition(RequestStatus.CANCELLED),
          true,
        );
        expect(
          RequestStatus.QUOTED.isValidTransition(RequestStatus.CANCELLED),
          true,
        );
        expect(
          RequestStatus.IN_PROGRESS
              .isValidTransition(RequestStatus.CANCELLED),
          true,
        );
        expect(
          RequestStatus.COMPLETED.isValidTransition(RequestStatus.CANCELLED),
          true,
        );
      });
    });
  });
}
