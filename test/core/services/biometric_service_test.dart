import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:pure_weight/core/services/biometric_service.dart';

/// Test double for [LocalAuthPlatform] that inherits the platform token via
/// `extends`, so [LocalAuthPlatform.instance] accepts it.
class FakeLocalAuthPlatform extends LocalAuthPlatform {
  FakeLocalAuthPlatform({
    this.supportsBiometrics = true,
    this.deviceSupported = true,
    this.enrolledBiometrics = const [BiometricType.fingerprint],
    this.authenticateHandler,
  });

  final bool supportsBiometrics;
  final bool deviceSupported;
  final List<BiometricType> enrolledBiometrics;
  final Future<bool> Function()? authenticateHandler;

  @override
  Future<bool> deviceSupportsBiometrics() async => supportsBiometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async =>
      enrolledBiometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    final handler = authenticateHandler;
    return handler != null ? await handler() : true;
  }
}

void main() {
  late FakeLocalAuthPlatform platform;

  setUp(() {
    platform = FakeLocalAuthPlatform();
    LocalAuthPlatform.instance = platform;
    BiometricService.resetForTesting();
  });

  tearDown(() {
    LocalAuthPlatform.instance = FakeLocalAuthPlatform();
  });

  group('BiometricService.isAvailable', () {
    test(
      'returns true when hardware exists and credentials are enrolled',
      () async {
        expect(await BiometricService.instance.isAvailable(), isTrue);
      },
    );

    test('returns false when no biometrics are enrolled', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: true,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.isAvailable(), isFalse);
    });

    test('returns false when the device lacks biometric hardware', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.isAvailable(), isFalse);
    });

    test('returns false when the platform check throws', () async {
      LocalAuthPlatform.instance = _ThrowingAvailabilityPlatform();

      expect(await BiometricService.instance.isAvailable(), isFalse);
    });
  });

  group('BiometricService.authenticate', () {
    test('returns success and broadcasts the authentication signal', () async {
      final signals = <void>[];
      final subscription = BiometricService.instance.authenticationSuccesses
          .listen((_) {
            signals.add(null);
          });

      final result = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );
      await pumpEventQueue();

      expect(result, BiometricAuthResult.success);
      expect(signals, hasLength(1));
      await subscription.cancel();
    });

    test('returns canceled when the OS prompt rejects the attempt', () async {
      platform = FakeLocalAuthPlatform(authenticateHandler: () async => false);
      LocalAuthPlatform.instance = platform;

      final result = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );

      expect(result, BiometricAuthResult.canceled);
    });

    test('returns notAvailable when the device is not supported', () async {
      platform = FakeLocalAuthPlatform(deviceSupported: false);
      LocalAuthPlatform.instance = platform;

      final result = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );

      expect(result, BiometricAuthResult.notAvailable);
    });

    group('maps LocalAuthException codes', () {
      Future<BiometricAuthResult> authenticateWith(LocalAuthException e) {
        final throwingPlatform = FakeLocalAuthPlatform(
          authenticateHandler: () async => throw e,
        );
        LocalAuthPlatform.instance = throwingPlatform;
        return BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );
      }

      test('noBiometricsEnrolled to notEnrolled', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.noBiometricsEnrolled,
            ),
          ),
          BiometricAuthResult.notEnrolled,
        );
      });

      test('noCredentialsSet to passcodeNotSet', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.noCredentialsSet,
            ),
          ),
          BiometricAuthResult.passcodeNotSet,
        );
      });

      test('temporaryLockout to lockedOut', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.temporaryLockout,
            ),
          ),
          BiometricAuthResult.lockedOut,
        );
      });

      test('biometricLockout to permanentlyLockedOut', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.biometricLockout,
            ),
          ),
          BiometricAuthResult.permanentlyLockedOut,
        );
      });

      test('noBiometricHardware to notAvailable', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.noBiometricHardware,
            ),
          ),
          BiometricAuthResult.notAvailable,
        );
      });

      test('userCanceled to canceled', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(code: LocalAuthExceptionCode.userCanceled),
          ),
          BiometricAuthResult.canceled,
        );
      });

      test('unknownError to error', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(code: LocalAuthExceptionCode.unknownError),
          ),
          BiometricAuthResult.error,
        );
      });
    });

    group('maps legacy PlatformException codes', () {
      Future<BiometricAuthResult> authenticateWith(String code) {
        final throwingPlatform = FakeLocalAuthPlatform(
          authenticateHandler: () async =>
              throw PlatformException(code: code, message: 'Mock error'),
        );
        LocalAuthPlatform.instance = throwingPlatform;
        return BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );
      }

      test('NotEnrolled to notEnrolled', () async {
        expect(
          await authenticateWith('NotEnrolled'),
          BiometricAuthResult.notEnrolled,
        );
      });

      test('LockedOut to lockedOut', () async {
        expect(
          await authenticateWith('LockedOut'),
          BiometricAuthResult.lockedOut,
        );
      });

      test('PermanentlyLockedOut to permanentlyLockedOut', () async {
        expect(
          await authenticateWith('PermanentlyLockedOut'),
          BiometricAuthResult.permanentlyLockedOut,
        );
      });

      test('PasscodeNotSet to passcodeNotSet', () async {
        expect(
          await authenticateWith('PasscodeNotSet'),
          BiometricAuthResult.passcodeNotSet,
        );
      });

      test('NotAvailable to notAvailable', () async {
        expect(
          await authenticateWith('NotAvailable'),
          BiometricAuthResult.notAvailable,
        );
      });

      test('unknown code to error', () async {
        expect(
          await authenticateWith('UnknownError'),
          BiometricAuthResult.error,
        );
      });
    });

    test('returns error when an unexpected exception is thrown', () async {
      final throwingPlatform = FakeLocalAuthPlatform(
        authenticateHandler: () async =>
            throw StateError('Unexpected platform failure'),
      );
      LocalAuthPlatform.instance = throwingPlatform;

      final result = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );

      expect(result, BiometricAuthResult.error);
    });
  });

  group('BiometricService.isTerminalFailure', () {
    test('treats enrollment and availability failures as terminal', () {
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.notEnrolled),
        isTrue,
      );
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.notAvailable),
        isTrue,
      );
      expect(
        BiometricService.isTerminalFailure(
          BiometricAuthResult.permanentlyLockedOut,
        ),
        isTrue,
      );
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.passcodeNotSet),
        isTrue,
      );
    });

    test('treats retryable outcomes as non-terminal', () {
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.success),
        isFalse,
      );
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.canceled),
        isFalse,
      );
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.lockedOut),
        isFalse,
      );
      expect(
        BiometricService.isTerminalFailure(BiometricAuthResult.error),
        isFalse,
      );
    });
  });
}

/// Platform stub whose availability checks always throw.
class _ThrowingAvailabilityPlatform extends FakeLocalAuthPlatform {
  @override
  Future<bool> deviceSupportsBiometrics() async {
    throw PlatformException(code: 'availabilityError');
  }
}
