import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Outcome of a biometric authentication attempt.
enum BiometricAuthResult {
  /// Authentication succeeded.
  success,

  /// The user dismissed or rejected the prompt (retryable).
  canceled,

  /// Biometrics are temporarily locked out (retryable after the OS cool-down).
  lockedOut,

  /// Biometrics are permanently locked out until the user re-enrolls.
  permanentlyLockedOut,

  /// No biometric credentials are enrolled on this device.
  notEnrolled,

  /// No device passcode is set, so biometric-only authentication cannot work.
  passcodeNotSet,

  /// Biometrics are not available or unsupported on this device.
  notAvailable,

  /// Authentication failed for any other reason.
  error,
}

/// Singleton service for checking biometric hardware availability and authenticating
/// the user via Face ID, Touch ID, or fingerprint.
///
/// ```dart
/// final available = await BiometricService.instance.isAvailable();
/// if (available) {
///   final result = await BiometricService.instance.authenticate(
///     localizedReason: 'Unlock to view your weight data',
///   );
/// }
/// ```
class BiometricService {
  BiometricService._();

  /// The single shared instance of [BiometricService].
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _authentication = LocalAuthentication();

  /// Broadcast stream emitting an event after every successful authentication.
  ///
  /// Listeners such as the encrypted weight stream recovery use it to retry
  /// work that failed while the device keystore was locked.
  Stream<void> get authenticationSuccesses =>
      _authenticationSuccessController.stream;

  StreamController<void> _authenticationSuccessController =
      StreamController<void>.broadcast();

  /// Resets the internal stream controller state for test isolation.
  @visibleForTesting
  static void resetForTesting() {
    if (!instance._authenticationSuccessController.isClosed) {
      instance._authenticationSuccessController.close();
    }
    instance._authenticationSuccessController =
        StreamController<void>.broadcast();
  }

  /// Closes the authentication success stream controller.
  Future<void> dispose() async {
    if (!_authenticationSuccessController.isClosed) {
      await _authenticationSuccessController.close();
    }
  }

  /// Broadcasts an authentication success event to [authenticationSuccesses].
  void _notifyAuthenticationSuccess() {
    if (!_authenticationSuccessController.isClosed) {
      _authenticationSuccessController.add(null);
    }
  }

  /// Checks whether the device has active biometric hardware and enrolled credentials.
  ///
  /// Returns a [Future] resolving to `true` if the device supports biometric
  /// sensors and at least one credential is enrolled, `false` otherwise.
  /// Catches hardware or platform exceptions safely and logs errors.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _authentication.canCheckBiometrics;
      if (kDebugMode) {
        debugPrint('[BiometricService] canCheckBiometrics: $canCheck');
      }
      if (!canCheck) return false;
      final biometrics = await _authentication.getAvailableBiometrics();
      if (kDebugMode) {
        debugPrint('[BiometricService] getAvailableBiometrics: $biometrics');
      }
      return biometrics.isNotEmpty;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] isAvailable error: $e\n$stack');
      }
      return false;
    }
  }

  /// Checks whether biometric authentication is fully supported on the device.
  ///
  /// Returns a [Future] resolving to `true` if biometrics are both available and
  /// supported by OS hardware abstractions, `false` otherwise.
  /// Catches platform exceptions safely and logs errors.
  Future<bool> isSupported() async {
    try {
      final deviceSupported = await _authentication.isDeviceSupported();
      if (kDebugMode) {
        debugPrint('[BiometricService] isDeviceSupported: $deviceSupported');
      }
      if (!deviceSupported) return false;
      final canCheck = await _authentication.canCheckBiometrics;
      if (kDebugMode) {
        debugPrint('[BiometricService] canCheckBiometrics: $canCheck');
      }
      return canCheck;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] isSupported error: $e\n$stack');
      }
      return false;
    }
  }

  Future<BiometricAuthResult>? _activeAuthFuture;
  DateTime? _lastAuthCompletionTime;

  /// Whether biometric authentication is currently in progress.
  bool get isAuthenticating => _activeAuthFuture != null;

  /// Whether biometric authentication finished very recently (within 1 second).
  /// Useful to prevent app lifecycle observers from instantly re-triggering logic
  /// when returning from the native biometric dialog.
  bool get wasAuthenticatingRecently =>
      _lastAuthCompletionTime != null &&
      DateTime.now().difference(_lastAuthCompletionTime!) <
          const Duration(seconds: 1);

  /// Prompts the user for biometric authentication.
  ///
  /// Takes a mandatory [localizedReason] string explaining the authentication request.
  /// Optional [authMessages] can be provided to customize dialog strings per locale.
  /// Concurrent calls while authentication is in progress await the same active
  /// operation rather than launching overlapping native dialogs.
  /// Returns a [Future] resolving to a [BiometricAuthResult] describing the outcome.
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    Iterable<AuthMessages>? authMessages,
  }) async {
    if (_activeAuthFuture != null) {
      if (kDebugMode) {
        debugPrint(
          '[BiometricService] Authentication already in progress. Re-using active Future.',
        );
      }
      return await _activeAuthFuture!;
    }

    _activeAuthFuture = _performAuthentication(
      localizedReason: localizedReason,
      authMessages: authMessages,
    );

    try {
      return await _activeAuthFuture!;
    } finally {
      _activeAuthFuture = null;
      _lastAuthCompletionTime = DateTime.now();
    }
  }

  /// Runs the platform authentication flow and maps every outcome (including
  /// platform exceptions) to a [BiometricAuthResult].
  Future<BiometricAuthResult> _performAuthentication({
    required String localizedReason,
    Iterable<AuthMessages>? authMessages,
  }) async {
    try {
      final supported = await isSupported();
      if (kDebugMode) {
        debugPrint(
          '[BiometricService] authenticate -> isSupported: $supported',
        );
      }
      if (!supported) return BiometricAuthResult.notAvailable;

      final available = await isAvailable();
      if (kDebugMode) {
        debugPrint(
          '[BiometricService] authenticate -> isAvailable: $available',
        );
      }
      if (!available) return BiometricAuthResult.notAvailable;

      final ok = await _authentication.authenticate(
        localizedReason: localizedReason,
        authMessages: authMessages ?? const <AuthMessages>[],
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (kDebugMode) {
        debugPrint('[BiometricService] authenticate result: $ok');
      }
      if (ok) {
        _notifyAuthenticationSuccess();
        return BiometricAuthResult.success;
      }
      return BiometricAuthResult.canceled;
    } on LocalAuthException catch (e, stack) {
      if (kDebugMode) {
        debugPrint('=== BIOMETRIC LOCAL AUTH ERROR ===');
        debugPrint('Code: ${e.code.name}');
        debugPrint('Description: ${e.description}');
        debugPrint('Details: ${e.details}');
        debugPrint('StackTrace: $stack');
        debugPrint('==================================');
      }
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricAuthResult.canceled,
        LocalAuthExceptionCode.temporaryLockout =>
          BiometricAuthResult.lockedOut,
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthResult.permanentlyLockedOut,
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          BiometricAuthResult.notEnrolled,
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAuthResult.passcodeNotSet,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricAuthResult.notAvailable,
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.uiUnavailable ||
        LocalAuthExceptionCode.deviceError ||
        LocalAuthExceptionCode.unknownError => BiometricAuthResult.error,
      };
    } on PlatformException catch (e, stack) {
      if (kDebugMode) {
        debugPrint('=== BIOMETRIC PLATFORM ERROR ===');
        debugPrint('Code: ${e.code}');
        debugPrint('Message: ${e.message}');
        debugPrint('Details: ${e.details}');
        debugPrint('StackTrace: $stack');
        debugPrint('================================');
      }
      return switch (e.code) {
        'LockedOut' => BiometricAuthResult.lockedOut,
        'PermanentlyLockedOut' => BiometricAuthResult.permanentlyLockedOut,
        'NotEnrolled' => BiometricAuthResult.notEnrolled,
        'PasscodeNotSet' => BiometricAuthResult.passcodeNotSet,
        'NotAvailable' => BiometricAuthResult.notAvailable,
        'auth_in_progress' => BiometricAuthResult.error,
        _ => BiometricAuthResult.error,
      };
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] authenticate error: $e\n$stack');
      }
      return BiometricAuthResult.error;
    }
  }

  /// Whether [result] means the user cannot authenticate until the device
  /// biometric configuration changes.
  static bool isTerminalFailure(BiometricAuthResult result) {
    return switch (result) {
      BiometricAuthResult.notEnrolled ||
      BiometricAuthResult.notAvailable ||
      BiometricAuthResult.permanentlyLockedOut ||
      BiometricAuthResult.passcodeNotSet => true,
      _ => false,
    };
  }

  /// Creates localized [AuthMessages] based on [AppLocalizations].
  static List<AuthMessages> createAuthMessages(AppLocalizations l10n) {
    return [
      AndroidAuthMessages(
        signInTitle: l10n.biometricStepTitle,
        cancelButton: l10n.cancel,
        signInHint: '', // Hides the default "Verify identity" subtitle
      ),
      IOSAuthMessages(cancelButton: l10n.cancel),
    ];
  }
}
