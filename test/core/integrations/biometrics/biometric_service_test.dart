import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/l10n/app_localizations.dart';

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

  /// The [AuthenticationOptions] passed to the last [authenticate] call.
  AuthenticationOptions? lastAuthOptions;

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
    lastAuthOptions = options;
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

  group('BiometricService.canAuthenticate', () {
    test(
      'returns true when device supports biometrics or device credentials',
      () async {
        expect(await BiometricService.instance.canAuthenticate(), isTrue);
      },
    );

    test('returns true for a PIN-only device without biometrics', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        deviceSupported: true,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.canAuthenticate(), isTrue);
    });

    test('returns false when no credentials can be presented', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        deviceSupported: false,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.canAuthenticate(), isFalse);
    });

    test('returns false when the platform check throws', () async {
      LocalAuthPlatform.instance = _ThrowingAvailabilityPlatform();

      expect(await BiometricService.instance.canAuthenticate(), isFalse);
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

    test(
      'passes biometricOnly false with sticky auth and error dialogs enabled',
      () async {
        await BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );

        final options = platform.lastAuthOptions;
        expect(options, isNotNull);
        expect(options!.biometricOnly, isFalse);
        expect(options.stickyAuth, isTrue);
        expect(options.useErrorDialogs, isTrue);
      },
    );

    test(
      'succeeds with device credential fallback on a PIN-only device',
      () async {
        platform = FakeLocalAuthPlatform(
          supportsBiometrics: false,
          deviceSupported: true,
          enrolledBiometrics: const [],
          authenticateHandler: () async => true,
        );
        LocalAuthPlatform.instance = platform;

        final result = await BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );

        expect(result, BiometricAuthResult.success);
        expect(platform.lastAuthOptions!.biometricOnly, isFalse);
      },
    );

    test('returns canceled when the OS prompt rejects the attempt', () async {
      platform = FakeLocalAuthPlatform(authenticateHandler: () async => false);
      LocalAuthPlatform.instance = platform;

      final result = await BiometricService.instance.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );

      expect(result, BiometricAuthResult.canceled);
    });

    test('returns notAvailable when the device has no credentials', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        deviceSupported: false,
        enrolledBiometrics: const [],
      );
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

      test('systemCanceled to canceled', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.systemCanceled,
            ),
          ),
          BiometricAuthResult.canceled,
        );
      });

      test('userRequestedFallback to canceled', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.userRequestedFallback,
            ),
          ),
          BiometricAuthResult.canceled,
        );
      });

      test('timeout to canceled', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(code: LocalAuthExceptionCode.timeout),
          ),
          BiometricAuthResult.canceled,
        );
      });

      test('biometricHardwareTemporarilyUnavailable to notAvailable', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode
                  .biometricHardwareTemporarilyUnavailable,
            ),
          ),
          BiometricAuthResult.notAvailable,
        );
      });

      test('authInProgress to error', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.authInProgress,
            ),
          ),
          BiometricAuthResult.error,
        );
      });

      test('uiUnavailable to error', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(
              code: LocalAuthExceptionCode.uiUnavailable,
            ),
          ),
          BiometricAuthResult.error,
        );
      });

      test('deviceError to error', () async {
        expect(
          await authenticateWith(
            const LocalAuthException(code: LocalAuthExceptionCode.deviceError),
          ),
          BiometricAuthResult.error,
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

      test('NotAuthenticated to canceled', () async {
        expect(
          await authenticateWith('NotAuthenticated'),
          BiometricAuthResult.canceled,
        );
      });

      test('UserCanceled to canceled', () async {
        expect(
          await authenticateWith('UserCanceled'),
          BiometricAuthResult.canceled,
        );
      });

      test('unknown code to error', () async {
        expect(
          await authenticateWith('UnknownError'),
          BiometricAuthResult.error,
        );
      });

      test('SystemCanceled to canceled', () async {
        expect(
          await authenticateWith('SystemCanceled'),
          BiometricAuthResult.canceled,
        );
      });

      test('AuthenticationCanceled to canceled', () async {
        expect(
          await authenticateWith('AuthenticationCanceled'),
          BiometricAuthResult.canceled,
        );
      });

      test('user_canceled to canceled', () async {
        expect(
          await authenticateWith('user_canceled'),
          BiometricAuthResult.canceled,
        );
      });

      test('canceled to canceled', () async {
        expect(
          await authenticateWith('canceled'),
          BiometricAuthResult.canceled,
        );
      });

      test('auth_in_progress to error', () async {
        expect(
          await authenticateWith('auth_in_progress'),
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

  group('BiometricService.isSupported', () {
    test('returns true when the device supports biometrics', () async {
      expect(await BiometricService.instance.isSupported(), isTrue);
    });

    test('returns false when the device lacks biometric support', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        deviceSupported: false,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.isSupported(), isFalse);
    });

    test('returns false for a device that cannot check biometrics', () async {
      platform = FakeLocalAuthPlatform(
        supportsBiometrics: false,
        deviceSupported: true,
        enrolledBiometrics: const [],
      );
      LocalAuthPlatform.instance = platform;

      expect(await BiometricService.instance.isSupported(), isFalse);
    });

    test('returns false when the platform check throws', () async {
      LocalAuthPlatform.instance = _ThrowingAvailabilityPlatform();

      expect(await BiometricService.instance.isSupported(), isFalse);
    });
  });

  group('BiometricService state getters', () {
    test('isAuthenticating tracks the active authentication future', () async {
      final service = BiometricService.instance;

      expect(service.isAuthenticating, isFalse);

      final future = service.authenticate(
        localizedReason: 'Unlock to view your weight data',
      );
      expect(service.isAuthenticating, isTrue);

      await future;
      expect(service.isAuthenticating, isFalse);
    });

    test(
      'wasAuthenticatingRecently is true right after authentication',
      () async {
        final service = BiometricService.instance;

        await service.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );

        expect(service.wasAuthenticatingRecently, isTrue);
      },
    );

    test(
      'wasAuthenticatingRecently is false before any authentication or after reset',
      () async {
        final service = BiometricService.instance;

        expect(service.wasAuthenticatingRecently, isFalse);

        await service.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );
        expect(service.wasAuthenticatingRecently, isTrue);

        BiometricService.resetForTesting();
        expect(service.wasAuthenticatingRecently, isFalse);
      },
    );

    test(
      'reuses the in-flight future for concurrent authentication calls',
      () async {
        final signals = <void>[];
        final subscription = BiometricService.instance.authenticationSuccesses
            .listen((_) {
              signals.add(null);
            });

        final first = BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );
        final second = BiometricService.instance.authenticate(
          localizedReason: 'Unlock to view your weight data',
        );

        expect(await first, BiometricAuthResult.success);
        expect(await second, BiometricAuthResult.success);
        await pumpEventQueue();
        expect(signals, hasLength(1));
        await subscription.cancel();
      },
    );
  });

  group('BiometricService lifecycle', () {
    test('dispose closes the authentication success stream', () async {
      final service = BiometricService.instance;

      expect(service.dispose(), completes);
    });
  });

  group('BiometricService.createAuthMessages', () {
    test('builds one message set per platform', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      final messages = BiometricService.createAuthMessages(l10n);

      expect(messages, hasLength(2));
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
