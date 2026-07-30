import 'package:pure_weight/features/weight/domain/weight_error_type.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Localized error message helpers for [WeightErrorType].
extension WeightErrorTypeX on WeightErrorType {
  /// Returns a user-facing error message for this error type using [l10n].
  String localizedMessage(AppLocalizations l10n) {
    return switch (this) {
      WeightErrorType.streamError => l10n.errorStream,
      WeightErrorType.heightNotSet => l10n.errorHeightNotSet,
      WeightErrorType.addEntryFailed => l10n.errorAddEntryFailed,
      WeightErrorType.deleteEntryFailed => l10n.errorDeleteEntryFailed,
      WeightErrorType.readFailed => l10n.errorReadFailed,
      WeightErrorType.writeFailed => l10n.errorWriteFailed,
      WeightErrorType.wipeFailed => l10n.errorWipeFailed,
    };
  }
}
