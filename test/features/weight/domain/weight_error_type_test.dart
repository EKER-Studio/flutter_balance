import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightErrorType', () {
    test('has exactly seven values', () {
      expect(WeightErrorType.values.length, 7);
    });

    test('contains all expected failure categories', () {
      expect(WeightErrorType.values, [
        WeightErrorType.streamError,
        WeightErrorType.heightNotSet,
        WeightErrorType.addEntryFailed,
        WeightErrorType.deleteEntryFailed,
        WeightErrorType.readFailed,
        WeightErrorType.writeFailed,
        WeightErrorType.wipeFailed,
      ]);
    });
  });

  group('WeightRepositoryException', () {
    test('stores type, message, and source error', () {
      final source = StateError('disk full');
      final exception = WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'Could not persist entry',
        sourceError: source,
      );

      expect(exception.type, WeightErrorType.writeFailed);
      expect(exception.message, 'Could not persist entry');
      expect(exception.sourceError, same(source));
    });

    test('allows a null source error', () {
      final exception = WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'Could not read entries',
      );

      expect(exception.sourceError, isNull);
    });

    test('toString includes the type and message', () {
      final exception = WeightRepositoryException(
        type: WeightErrorType.deleteEntryFailed,
        message: 'Delete failed',
      );

      expect(
        exception.toString(),
        'WeightRepositoryException(WeightErrorType.deleteEntryFailed): '
        'Delete failed',
      );
    });

    test('implements Exception', () {
      final exception = WeightRepositoryException(
        type: WeightErrorType.addEntryFailed,
        message: 'Add failed',
      );

      expect(exception, isA<Exception>());
    });
  });

  group('WeightDatabaseFailure', () {
    test('is an alias for WeightRepositoryException', () {
      const failure = WeightDatabaseFailure(
        type: WeightErrorType.wipeFailed,
        message: 'Wipe failed',
      );

      expect(failure, isA<WeightRepositoryException>());
      expect(failure.type, WeightErrorType.wipeFailed);
    });
  });
}
