import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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
  /// Takes an optional [opsRequired] boolean flag for OS requirement configuration.
  /// Returns a [Future] resolving to `true` if authentication succeeded, `false` if
  /// cancelled, rejected, or unsupported.
  /// Catches platform lockout or security exceptions safely and logs errors.
  Future<bool> authenticate({
    required String localizedReason,
    bool opsRequired = false,
  }) async {
    try {
      final supported = await isSupported();
      if (!supported) return false;

      return await _authentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: false,
      );
    } on PlatformException catch (e, stack) {
      if (kDebugMode) {
        switch (e.code) {
          case 'LockedOut':
            debugPrint(
              '[BiometricService] Biometric authentication locked out: ${e.message}',
            );
          case 'PermanentlyLockedOut':
            debugPrint(
              '[BiometricService] Biometric authentication permanently locked out: ${e.message}',
            );
          case 'NotEnrolled':
            debugPrint(
              '[BiometricService] No biometric credentials enrolled: ${e.message}',
            );
          case 'PasscodeNotSet':
            debugPrint(
              '[BiometricService] Passcode not set on device: ${e.message}',
            );
          case 'NotAvailable':
            debugPrint(
              '[BiometricService] Biometrics not available: ${e.message}',
            );
          default:
            debugPrint(
              '[BiometricService] PlatformException (${e.code}): ${e.message}\n$stack',
            );
        }
      }
      return false;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] authenticate error: $e\n$stack');
      }
      return false;
    }
  }
}
