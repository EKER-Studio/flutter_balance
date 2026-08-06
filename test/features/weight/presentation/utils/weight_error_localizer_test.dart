import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  group('WeightErrorTypeX.localizedMessage', () {
    test('maps streamError to the stream error string', () {
      expect(
        WeightErrorType.streamError.localizedMessage(l10n),
        l10n.errorStream,
      );
    });

    test('maps heightNotSet to the height not set string', () {
      expect(
        WeightErrorType.heightNotSet.localizedMessage(l10n),
        l10n.errorHeightNotSet,
      );
    });

    test('maps addEntryFailed to the add entry failed string', () {
      expect(
        WeightErrorType.addEntryFailed.localizedMessage(l10n),
        l10n.errorAddEntryFailed,
      );
    });

    test('maps deleteEntryFailed to the delete entry failed string', () {
      expect(
        WeightErrorType.deleteEntryFailed.localizedMessage(l10n),
        l10n.errorDeleteEntryFailed,
      );
    });

    test('maps readFailed to the read failed string', () {
      expect(
        WeightErrorType.readFailed.localizedMessage(l10n),
        l10n.errorReadFailed,
      );
    });

    test('maps writeFailed to the write failed string', () {
      expect(
        WeightErrorType.writeFailed.localizedMessage(l10n),
        l10n.errorWriteFailed,
      );
    });

    test('maps wipeFailed to the wipe failed string', () {
      expect(
        WeightErrorType.wipeFailed.localizedMessage(l10n),
        l10n.errorWipeFailed,
      );
    });

    test('returns distinct messages for distinct error types', () {
      final messages = WeightErrorType.values
          .map((type) => type.localizedMessage(l10n))
          .toSet();
      expect(messages.length, WeightErrorType.values.length);
    });
  });

  group('WeightRepositoryException', () {
    test('exposes type, message, and source error', () {
      final exception = WeightRepositoryException(
        type: WeightErrorType.readFailed,
        message: 'boom',
        sourceError: StateError('origin'),
      );
      expect(exception.type, WeightErrorType.readFailed);
      expect(exception.message, 'boom');
      expect(exception.sourceError, isA<StateError>());
    });

    test('source error defaults to null', () {
      const exception = WeightRepositoryException(
        type: WeightErrorType.writeFailed,
        message: 'sad',
      );
      expect(exception.sourceError, isNull);
    });

    test('toString includes type and message', () {
      const exception = WeightRepositoryException(
        type: WeightErrorType.addEntryFailed,
        message: 'nope',
      );
      expect(
        exception.toString(),
        'WeightRepositoryException(WeightErrorType.addEntryFailed): nope',
      );
    });
  });
}
