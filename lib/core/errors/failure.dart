import 'package:equatable/equatable.dart';

/// Base sealed class representing any domain-level failure in the application.
///
/// Follows Clean Architecture domain failure patterns, ensuring UI layers
/// receive user-safe error messages while preserving technical context for logs.
sealed class Failure extends Equatable {
  /// The user-friendly error message, safe for display in UI.
  final String userMessage;

  /// The technical error details, stack trace, or cause for logging.
  final String? technicalDetails;

  const Failure({required this.userMessage, this.technicalDetails});

  @override
  List<Object?> get props => [userMessage, technicalDetails];
}

/// Failure occurring during database read, write, transaction, or corruption events.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.userMessage, super.technicalDetails});
}

/// Failure occurring during input validation or business constraint violations.
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.userMessage, super.technicalDetails});
}

/// Failure occurring during Apple Health or Health Connect synchronization.
final class HealthSyncFailure extends Failure {
  const HealthSyncFailure({required super.userMessage, super.technicalDetails});
}

/// Failure occurring during CSV file reading, header parsing, or row conversion.
final class CsvImportFailure extends Failure {
  final int? failedRowIndex;

  const CsvImportFailure({
    required super.userMessage,
    super.technicalDetails,
    this.failedRowIndex,
  });

  @override
  List<Object?> get props => [userMessage, technicalDetails, failedRowIndex];
}

/// Failure occurring during biometric authentication or hardware availability checks.
final class BiometricFailure extends Failure {
  const BiometricFailure({required super.userMessage, super.technicalDetails});
}

/// Failure occurring during network communication or remote endpoint errors.
final class NetworkFailure extends Failure {
  final int? statusCode;

  const NetworkFailure({
    required super.userMessage,
    super.technicalDetails,
    this.statusCode,
  });

  @override
  List<Object?> get props => [userMessage, technicalDetails, statusCode];
}
