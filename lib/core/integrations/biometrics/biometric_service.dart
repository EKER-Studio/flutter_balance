import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Represents the outcome of a biometric authentication attempt.
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

/// A singleton service that authenticates users via Face ID, Touch ID, fingerprint, or the OS lock screen (PIN/pattern/password) as fallback.
class BiometricService {
  BiometricService._();

  /// The single shared instance of [BiometricService].
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _authentication = LocalAuthentication();

  /// A broadcast stream emitting an event after every successful authentication.
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
  /// Returns `true` if the device supports biometric sensors and at least one
  /// credential is enrolled; catches hardware or platform exceptions and returns `false`.
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
  /// Returns `true` if biometrics are both available and supported by OS
  /// hardware abstractions; catches platform exceptions and returns `false`.
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

  /// Checks whether the device can present any OS credential prompt.
  ///
  /// Returns `true` if the device supports biometric checks or can fall over
  /// to the OS lock screen (PIN, pattern, or password), so devices with only a
  /// system PIN can still use the app lock; catches platform exceptions and
  /// returns `false`.
  Future<bool> canAuthenticate() async {
    try {
      final deviceSupported = await _authentication.isDeviceSupported();
      if (kDebugMode) {
        debugPrint('[BiometricService] isDeviceSupported: $deviceSupported');
      }
      final canCheck = await _authentication.canCheckBiometrics;
      if (kDebugMode) {
        debugPrint('[BiometricService] canCheckBiometrics: $canCheck');
      }
      return deviceSupported || canCheck;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[BiometricService] canAuthenticate error: $e\n$stack');
      }
      return false;
    }
  }

  Future<BiometricAuthResult>? _activeAuthFuture;
  DateTime? _lastAuthCompletionTime;

  /// Whether biometric authentication is currently in progress.
  bool get isAuthenticating => _activeAuthFuture != null;

  /// Whether biometric authentication finished very recently (within 1 second).
  ///
  /// Useful to prevent app lifecycle observers from instantly re-triggering logic
  /// when returning from the native biometric dialog.
  bool get wasAuthenticatingRecently =>
      _lastAuthCompletionTime != null &&
      DateTime.now().difference(_lastAuthCompletionTime!) <
          const Duration(seconds: 1);

  /// Prompts the user for device credential authentication.
  ///
  /// Uses biometrics with automatic fallback to the OS PIN/pattern/password
  /// prompt. Takes a mandatory [localizedReason] string explaining the request.
  /// Optional [authMessages] can customize dialog strings per locale.
  /// Concurrent calls while authentication is in progress await the same active
  /// operation rather than launching overlapping native dialogs.
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

  /// Runs the platform authentication flow and maps every outcome to a [BiometricAuthResult].
  ///
  /// With `biometricOnly: false` the OS falls back to the system PIN/pattern/password
  /// prompt when biometrics are unavailable, disabled, or fail.
  Future<BiometricAuthResult> _performAuthentication({
    required String localizedReason,
    Iterable<AuthMessages>? authMessages,
  }) async {
    try {
      final canAuth = await canAuthenticate();
      if (kDebugMode) {
        debugPrint(
          '[BiometricService] authenticate -> canAuthenticate: $canAuth',
        );
      }
      if (!canAuth) return BiometricAuthResult.notAvailable;

      final ok = await LocalAuthPlatform.instance.authenticate(
        localizedReason: localizedReason,
        authMessages: authMessages ?? const <AuthMessages>[],
        // Constructed explicitly because the `LocalAuthentication` wrapper of
        // local_auth 3.x hardcodes `useErrorDialogs: false` and derives
        // `stickyAuth` from `persistAcrossBackgrounding`, exposing neither.
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
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
        'NotAuthenticated' ||
        'UserCanceled' ||
        'SystemCanceled' ||
        'AuthenticationCanceled' ||
        'user_canceled' ||
        'canceled' => BiometricAuthResult.canceled,
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

  /// Creates localized AuthMessages based on [AppLocalizations].
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
