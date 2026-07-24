import 'package:local_auth/local_auth.dart';

/// Service for checking biometric hardware availability and authenticating
/// the user with Face ID / Touch ID / fingerprint.
class BiometricService {
  BiometricService._();

  /// The single shared instance of [BiometricService].
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _authentication = LocalAuthentication();

  /// Whether the device has biometric hardware and the user has enrolled
  /// at least one credential.
  Future<bool> isAvailable() async {
    try {
      return await _authentication.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Returns whether biometric authentication is supported on the device.
  Future<bool> isSupported() async {
    try {
      final available = await isAvailable();
      if (!available) return false;
      return await _authentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  ///
  /// Returns `true` if the user was successfully authenticated.
  /// Returns `false` if the user cancelled, failed, or the device doesn't
  /// support biometrics.
  Future<bool> authenticate({
    required String localizedReason,
    bool opsRequired = false,
  }) async {
    try {
      final supported = await isSupported();
      if (!supported) return false;

      return await _authentication.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
