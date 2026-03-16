import 'package:flutter_test/flutter_test.dart';
import 'package:road_rescue/services/exceptions.dart';

void main() {
  group('Custom Exceptions', () {
    group('ApiException', () {
      test('stores message and produces correct toString', () {
        final exception = ApiException('Something went wrong');

        expect(exception.message, 'Something went wrong');
        expect(exception.toString(), 'ApiException: Something went wrong');
      });

      test('is catchable as Exception', () {
        expect(
          () => throw ApiException('Test error'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('UnauthorizedException', () {
      test('stores message and produces correct toString', () {
        final exception = UnauthorizedException('Invalid token');

        expect(exception.message, 'Invalid token');
        expect(
          exception.toString(),
          'UnauthorizedException: Invalid token',
        );
      });

      test('is catchable as Exception', () {
        expect(
          () => throw UnauthorizedException('No token'),
          throwsA(isA<UnauthorizedException>()),
        );
      });
    });

    group('ValidationException', () {
      test('stores multiple messages', () {
        final exception = ValidationException([
          'Email is required',
          'Password must be at least 8 characters',
        ]);

        expect(exception.messages.length, 2);
        expect(exception.messages[0], 'Email is required');
        expect(exception.messages[1], 'Password must be at least 8 characters');
      });

      test('produces comma-separated toString', () {
        final exception = ValidationException([
          'Field A is invalid',
          'Field B is required',
        ]);

        expect(
          exception.toString(),
          'ValidationException: Field A is invalid, Field B is required',
        );
      });

      test('handles single message', () {
        final exception = ValidationException(['Email already exists']);

        expect(exception.messages.length, 1);
        expect(
          exception.toString(),
          'ValidationException: Email already exists',
        );
      });

      test('is catchable as Exception', () {
        expect(
          () => throw ValidationException(['error']),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('NotFoundException', () {
      test('stores message and produces correct toString', () {
        final exception = NotFoundException('Provider not found');

        expect(exception.message, 'Provider not found');
        expect(
          exception.toString(),
          'NotFoundException: Provider not found',
        );
      });

      test('is catchable as Exception', () {
        expect(
          () => throw NotFoundException('Not found'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('Exception hierarchy', () {
      test('all custom exceptions implement Exception', () {
        expect(ApiException('test'), isA<Exception>());
        expect(UnauthorizedException('test'), isA<Exception>());
        expect(ValidationException(['test']), isA<Exception>());
        expect(NotFoundException('test'), isA<Exception>());
      });

      test('custom exceptions are distinct types', () {
        final api = ApiException('test');
        final unauth = UnauthorizedException('test');
        final validation = ValidationException(['test']);
        final notFound = NotFoundException('test');

        expect(api, isNot(isA<UnauthorizedException>()));
        expect(unauth, isNot(isA<ApiException>()));
        expect(validation, isNot(isA<NotFoundException>()));
        expect(notFound, isNot(isA<ValidationException>()));
      });
    });
  });
}
