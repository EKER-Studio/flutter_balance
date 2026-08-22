import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

/// Records every event the [AppSettingsBloc] processes.
///
/// `BlocObserver.onEvent` fires synchronously within `add`, unlike the bloc
/// state stream whose deliveries are deferred past the fake-async test zone.
class RecordingBlocObserver extends BlocObserver {
  /// Events observed so far, in processing order.
  final List<Object?> events = [];

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    events.add(event);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/local_auth');

  late MockHydratedStorage storage;
  late AppSettingsBloc bloc;

  Widget buildTestWidget() {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AppSettingsBloc>.value(
        value: bloc,
        child: const BiometricShieldScreen(),
      ),
    );
  }

  void setupMockChannel({
    required bool canCheckBiometrics,
    required bool isDeviceSupported,
    required bool authenticateResult,
    String? errorCode,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'canCheckBiometrics':
              return canCheckBiometrics;
            case 'isDeviceSupported':
              return isDeviceSupported;
            case 'getAvailableBiometrics':
              return canCheckBiometrics ? <String>['fingerprint'] : <String>[];
            case 'authenticate':
              if (errorCode != null) {
                throw PlatformException(code: errorCode, message: 'Mock error');
              }
              return authenticateResult;
            default:
              return null;
          }
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    bloc.close();
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    bloc = AppSettingsBloc();
  });

  group('BiometricShieldScreen Tests', () {
    testWidgets('renders lock icon, title, reason, and unlock button', (
      tester,
    ) async {
      setupMockChannel(
        canCheckBiometrics: true,
        isDeviceSupported: true,
        authenticateResult: true,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('successful authentication unlocks the app', (tester) async {
      setupMockChannel(
        canCheckBiometrics: true,
        isDeviceSupported: true,
        authenticateResult: true,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(bloc.state.isLocked, false);
    });

    testWidgets('mounting while already locked does not re-lock before auth', (
      tester,
    ) async {
      setupMockChannel(
        canCheckBiometrics: true,
        isDeviceSupported: true,
        authenticateResult: true,
      );

      final observer = RecordingBlocObserver();
      final originalObserver = Bloc.observer;
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = originalObserver);
      bloc.close();
      bloc = AppSettingsBloc();

      bloc.add(const SetLocked(true));
      await tester.pump();
      expect(bloc.state.isLocked, true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(bloc.state.isLocked, false);
      expect(
        observer.events.whereType<SetLocked>().where((e) => e.locked).length,
        1,
        reason: 'The mount must not emit a redundant lock-transition event',
      );
    });

    testWidgets('disables the unlock button while authentication is running', (
      tester,
    ) async {
      final completer = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'canCheckBiometrics':
                return true;
              case 'isDeviceSupported':
                return true;
              case 'getAvailableBiometrics':
                return <String>['fingerprint'];
              case 'authenticate':
                return completer.future;
              default:
                return null;
            }
          });

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        button.onPressed,
        isNull,
        reason: 'Unlock must not be tappable while auth is in flight',
      );

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(bloc.state.isLocked, false);
    });

    testWidgets(
      'terminal failure opens lock recovery dialog and user can disable lock',
      (tester) async {
        setupMockChannel(
          canCheckBiometrics: false,
          isDeviceSupported: false,
          authenticateResult: false,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        final l10n = AppLocalizations.of(
          tester.element(find.byType(AlertDialog)),
        );
        await tester.tap(find.widgetWithText(TextButton, l10n.disableLock));
        await tester.pumpAndSettle();

        expect(bloc.state.isBiometricLockEnabled, false);
        expect(bloc.state.isLocked, false);
      },
    );

    testWidgets('terminal failure dialog can be dismissed with keep locked', (
      tester,
    ) async {
      setupMockChannel(
        canCheckBiometrics: false,
        isDeviceSupported: false,
        authenticateResult: false,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      );
      await tester.tap(find.widgetWithText(TextButton, l10n.keepLocked));
      await tester.pumpAndSettle();

      expect(bloc.state.isLocked, true);
    });

    testWidgets('failed authentication shows a retry snackbar', (tester) async {
      setupMockChannel(
        canCheckBiometrics: true,
        isDeviceSupported: true,
        authenticateResult: false,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(
        find.text('Biometric authentication failed or was canceled.'),
        findsOneWidget,
      );
      expect(bloc.state.isLocked, true);
    });
  });
}
