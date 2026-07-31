import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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
class BiometricService {
  BiometricService._();

  /// The single shared instance of [BiometricService].
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _authentication = LocalAuthentication();

  /// Checks whether the device has active biometric hardware and enrolled credentials.
  ///
  /// Returns a [Future] resolving to `true` if biometric sensors can be checked and
  /// credentials are enrolled, `false` otherwise.
  /// Catches hardware or platform exceptions safely and logs errors.
  Future<bool> isAvailable() async {
    try {
      return await _authentication.canCheckBiometrics;
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
      final available = await isAvailable();
      if (!available) return false;
      return await _authentication.isDeviceSupported();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] isSupported error: $e\n$stack');
      }
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  ///
  /// Takes a mandatory [localizedReason] string explaining the authentication request.
  /// Returns a [Future] resolving to a [BiometricAuthResult] describing the outcome.
  /// Terminal failures ([BiometricAuthResult.notEnrolled], [BiometricAuthResult.notAvailable],
  /// [BiometricAuthResult.permanentlyLockedOut], [BiometricAuthResult.passcodeNotSet])
  /// mean the user cannot authenticate with biometrics until the device state changes.
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
  }) async {
    try {
      final supported = await isSupported();
      if (!supported) return BiometricAuthResult.notAvailable;

      final ok = await _authentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
      return ok ? BiometricAuthResult.success : BiometricAuthResult.canceled;
    } on PlatformException catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
          '[BiometricService] PlatformException (${e.code}): ${e.message}\n$stack',
        );
      }
      return switch (e.code) {
        'LockedOut' => BiometricAuthResult.lockedOut,
        'PermanentlyLockedOut' => BiometricAuthResult.permanentlyLockedOut,
        'NotEnrolled' => BiometricAuthResult.notEnrolled,
        'PasscodeNotSet' => BiometricAuthResult.passcodeNotSet,
        'NotAvailable' => BiometricAuthResult.notAvailable,
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
}
