import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/errors/failure.dart';

void main() {
  group('Failure taxonomy', () {
    test('DatabaseFailure supports value equality', () {
      const f1 = DatabaseFailure(
        userMessage: 'DB error',
        technicalDetails: 'Isar closed',
      );
      const f2 = DatabaseFailure(
        userMessage: 'DB error',
        technicalDetails: 'Isar closed',
      );
      const f3 = DatabaseFailure(userMessage: 'Different message');

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });

    test('ValidationFailure holds userMessage and technicalDetails', () {
      const failure = ValidationFailure(
        userMessage: 'Invalid weight',
        technicalDetails: 'Weight must be > 0',
      );

      expect(failure.userMessage, equals('Invalid weight'));
      expect(failure.technicalDetails, equals('Weight must be > 0'));
    });

    test('HealthSyncFailure supports equality', () {
      const failure = HealthSyncFailure(
        userMessage: 'Sync failed',
        technicalDetails: 'Permission not granted',
      );

      expect(failure.userMessage, equals('Sync failed'));
      expect(failure.technicalDetails, equals('Permission not granted'));
    });

    test('CsvImportFailure holds failedRowIndex', () {
      const failure = CsvImportFailure(
        userMessage: 'CSV error',
        failedRowIndex: 42,
      );

      expect(failure.userMessage, equals('CSV error'));
      expect(failure.failedRowIndex, equals(42));
    });

    test('BiometricFailure supports equality', () {
      const failure = BiometricFailure(userMessage: 'Auth failed');
      expect(failure.userMessage, equals('Auth failed'));
    });

    test('NetworkFailure holds statusCode', () {
      const failure = NetworkFailure(
        userMessage: 'Server unreachable',
        statusCode: 503,
      );

      expect(failure.statusCode, equals(503));
      expect(failure.userMessage, equals('Server unreachable'));
    });
  });
}
