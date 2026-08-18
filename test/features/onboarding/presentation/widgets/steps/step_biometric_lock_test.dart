import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_biometric_lock.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

/// Test double for [LocalAuthPlatform] with mutable support flags so tests can
/// simulate the device capability changing between the initial check and the
/// toggle handler's re-check.
class MutableLocalAuthPlatform extends LocalAuthPlatform {
  bool deviceSupported = true;
  bool supportsBiometrics = true;
  Future<bool> Function()? authenticateHandler;
  int authenticateCalls = 0;

  @override
  Future<bool> deviceSupportsBiometrics() async => supportsBiometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => const [
    BiometricType.fingerprint,
  ];

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    authenticateCalls++;
    final handler = authenticateHandler;
    return handler != null ? await handler() : true;
  }
}

void main() {
  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    settingsBloc = AppSettingsBloc();
  });

  tearDown(() {
    settingsBloc.close();
  });

  Widget buildSubject({required VoidCallback onNext}) {
    return BlocProvider<AppSettingsBloc>.value(
      value: settingsBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StepBiometricLock(onNext: onNext)),
      ),
    );
  }

  group('StepBiometricLock Widget Tests', () {
    testWidgets('renders step title, description, switch, and next button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      expect(find.text('Biometric Protection'), findsNWidgets(2));
      expect(
        find.text(
          'Secure your measurements from prying eyes and unlock the app instantly using your face or fingerprint.',
        ),
        findsOneWidget,
      );
      expect(find.text('Additional app security'), findsOneWidget);
      expect(find.byKey(const Key('biometric_step_switch')), findsOneWidget);
      expect(
        find.byKey(const Key('biometric_step_next_button')),
        findsOneWidget,
      );
    });

    testWidgets('invokes onNext when next button is pressed', (tester) async {
      int nextCount = 0;
      await tester.pumpWidget(buildSubject(onNext: () => nextCount++));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('biometric_step_next_button')));
      await tester.pumpAndSettle();
      expect(nextCount, equals(1));
    });
  });

  group('StepBiometricLock biometric flows', () {
    late MutableLocalAuthPlatform platform;

    setUp(() {
      platform = MutableLocalAuthPlatform();
      LocalAuthPlatform.instance = platform;
      BiometricService.resetForTesting();
    });

    testWidgets('disables the switch when biometrics are unavailable', (
      tester,
    ) async {
      platform.deviceSupported = false;
      platform.supportsBiometrics = false;

      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('biometric_step_switch')),
      );
      expect(switchTile.onChanged, isNull);
      expect(
        find.text('Biometrics not available on this device'),
        findsOneWidget,
      );
    });

    testWidgets('enables the lock after a successful authentication', (
      tester,
    ) async {
      platform.authenticateHandler = () async => true;

      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('biometric_step_switch')));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isTrue);
      expect(platform.authenticateCalls, 1);
      expect(find.byKey(const Key('biometric_step_switch')), findsOneWidget);
    });

    testWidgets('shows a failure snackbar when authentication is canceled', (
      tester,
    ) async {
      platform.authenticateHandler = () async => false;

      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('biometric_step_switch')));
      await tester.pumpAndSettle();

      expect(
        find.text('Biometric authentication failed or was canceled.'),
        findsOneWidget,
      );
      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets('shows an unavailability snackbar when the toggle re-check '
        'fails', (tester) async {
      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      // Simulate the device capability changing after the initial check.
      platform.deviceSupported = false;
      platform.supportsBiometrics = false;

      await tester.tap(find.byKey(const Key('biometric_step_switch')));
      await tester.pumpAndSettle();

      expect(
        find.text('Biometrics not available on this device'),
        findsWidgets,
      );
      expect(platform.authenticateCalls, 0);
      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets('disables the lock directly without authentication', (
      tester,
    ) async {
      settingsBloc.add(const UpdateBiometricLock(true));
      await tester.pumpWidget(buildSubject(onNext: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('biometric_step_switch')));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
      expect(platform.authenticateCalls, 0);
    });
  });
}
