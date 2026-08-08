import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/core/services/notification_service.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

class MockNotificationService extends Mock implements NotificationService {}

class MockHealthService extends Mock implements HealthService {}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late MockHealthService healthService;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    weightBloc = MockWeightBloc();
    when(
      () => weightBloc.state,
    ).thenReturn(const WeightLoaded(entries: [], filteredEntries: []));
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(const WeightLoaded(entries: [], filteredEntries: [])),
    );

    healthService = MockHealthService();
    when(
      () => healthService.isHealthApiAvailable(),
    ).thenAnswer((_) async => true);

    settingsBloc = AppSettingsBloc(healthService: healthService);
  });

  Widget createTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeightBloc>.value(value: weightBloc),
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('renders all section headers', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('APPLICATION'), findsOneWidget);
    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('DATA'), findsOneWidget);
    expect(find.text('INTEGRATIONS'), findsOneWidget);
  });

  testWidgets('renders height value from settings', (tester) async {
    settingsBloc.add(const UpdateHeight(170.0));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('170 cm'), findsOneWidget);
  });

  testWidgets('shows theme selection dialog on theme tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.drag(find.text('PROFILE'), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pump();

    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('shows height dialog on height tap', (tester) async {
    settingsBloc.add(const UpdateHeight(170.0));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('170 cm'));
    await tester.pumpAndSettle();

    expect(find.text('Set Height'), findsOneWidget);
    expect(find.text('Height (cm)'), findsOneWidget);
  });

  testWidgets(
    'shows inline height error when entering height outside 50-250 cm range',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('height not set'));
      await tester.pumpAndSettle();

      // Enter invalid height (e.g. 1 cm)
      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Height must be between 50 and 250 cm'), findsOneWidget);
    },
  );

  testWidgets('shows unit selection dialog on unit tap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.drag(find.text('PROFILE'), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metric (kg, cm)'));
    await tester.pump();

    expect(find.text('Imperial (lb, ft/in)'), findsOneWidget);
  });

  testWidgets('shows target weight dialog on target weight tap', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.tap(find.text('Not set'));
    await tester.pump();

    expect(find.text('Target Weight').last, findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
  });

  testWidgets(
    'shows inline weight error when entering target weight outside 20-300 kg range',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not set'));
      await tester.pumpAndSettle();

      // Enter invalid target weight (e.g. 5 kg)
      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Weight must be between 20 and 300 kg'), findsOneWidget);
    },
  );

  testWidgets('shows notification switch disabled by default', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    final switchFinder = find.byType(Switch).first;
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
  });

  testWidgets(
    'shows permission denied snackbar when notification permission is rejected',
    (tester) async {
      final mockNotificationService = MockNotificationService();
      registerFallbackValue(const TimeOfDay(hour: 8, minute: 0));
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => false);
      when(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).thenAnswer((_) async {});

      settingsBloc = AppSettingsBloc(
        notificationService: mockNotificationService,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(
        find.text('Notification permission is required to enable reminders.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows wipe confirmation dialog', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.ensureVisible(find.text('Wipe All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    expect(
      find.text(
        'This will permanently delete all your weight entries and reset app settings. This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Wipe Data'), findsOneWidget);
  });

  testWidgets('wipe does not clear hydrated storage', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.ensureVisible(find.text('Wipe All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    await tester.tap(find.text('Wipe Data'));
    await tester.pump();

    verifyNever(() => storage.clear());
  });

  group('Health sync', () {
    Finder healthSyncSwitch() => find.descendant(
      of: find.widgetWithText(ListTile, 'Health Sync'),
      matching: find.byType(Switch),
    );

    testWidgets('renders the health sync switch enabled by default', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Health Sync'), findsOneWidget);
      expect(
        find.text('Sync weight data with Apple Health / Health Connect'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(healthSyncSwitch()).value, isFalse);
      expect(tester.widget<Switch>(healthSyncSwitch()).onChanged, isNotNull);
    });

    testWidgets('switch reflects a persisted enabled health sync state', (
      tester,
    ) async {
      settingsBloc = AppSettingsBloc(healthService: healthService);
      when(
        () => healthService.requestPermissions(),
      ).thenAnswer((_) async => true);

      settingsBloc.add(const ToggleHealthSync(true));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(healthSyncSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(healthSyncSwitch()).value, isTrue);
    });

    testWidgets('enables sync and requests permissions when toggled on', (
      tester,
    ) async {
      settingsBloc = AppSettingsBloc(healthService: healthService);
      when(
        () => healthService.requestPermissions(),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(healthSyncSwitch());
      await tester.pumpAndSettle();
      await tester.tap(healthSyncSwitch());
      await tester.pumpAndSettle();

      verify(() => healthService.requestPermissions()).called(1);
      expect(tester.widget<Switch>(healthSyncSwitch()).value, isTrue);
    });

    testWidgets(
      'dispatches SyncHealthEntries when sync is enabled with granted permissions',
      (tester) async {
        settingsBloc = AppSettingsBloc(healthService: healthService);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.ensureVisible(healthSyncSwitch());
        await tester.pumpAndSettle();
        await tester.tap(healthSyncSwitch());
        await tester.pumpAndSettle();

        verify(() => weightBloc.add(const SyncHealthEntries())).called(1);
      },
    );

    testWidgets(
      'does not dispatch SyncHealthEntries when permissions are denied',
      (tester) async {
        settingsBloc = AppSettingsBloc(healthService: healthService);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.ensureVisible(healthSyncSwitch());
        await tester.pumpAndSettle();
        await tester.tap(healthSyncSwitch());
        await tester.pumpAndSettle();

        verifyNever(() => weightBloc.add(const SyncHealthEntries()));
      },
    );

    testWidgets(
      'shows info snackbar with system settings hint when toggled off',
      (tester) async {
        settingsBloc = AppSettingsBloc(healthService: healthService);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => true);

        settingsBloc.add(const ToggleHealthSync(true));
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(healthSyncSwitch());
        await tester.pumpAndSettle();
        await tester.tap(healthSyncSwitch());
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'To fully revoke system-level access, go to system settings',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows permission denied snackbar with settings action when denied',
      (tester) async {
        settingsBloc = AppSettingsBloc(healthService: healthService);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.ensureVisible(healthSyncSwitch());
        await tester.pumpAndSettle();
        await tester.tap(healthSyncSwitch());
        await tester.pumpAndSettle();

        expect(
          find.text('Health data permissions are required to sync weight.'),
          findsOneWidget,
        );
        expect(find.text('Settings'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byType(SnackBarAction),
          ),
          findsOneWidget,
        );
        expect(tester.widget<Switch>(healthSyncSwitch()).value, isFalse);
      },
    );

    testWidgets(
      'on non-Android keeps the switch disabled when API is unavailable',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          settingsBloc = AppSettingsBloc(healthService: healthService);
          when(
            () => healthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
          when(
            () => healthService.hasPermissions(),
          ).thenAnswer((_) async => false);

          settingsBloc.add(const CheckHealthSyncStatus());
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Unavailable on this device'), findsOneWidget);
          expect(tester.widget<Switch>(healthSyncSwitch()).onChanged, isNull);
          verifyNever(() => healthService.requestPermissions());
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets(
      'on Android shows install dialog when the health API is unavailable',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        try {
          settingsBloc = AppSettingsBloc(healthService: healthService);
          when(
            () => healthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
          when(
            () => healthService.hasPermissions(),
          ).thenAnswer((_) async => false);

          settingsBloc.add(const CheckHealthSyncStatus());
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // The disabled switch is replaced by a tappable tile.
          expect(find.text('Unavailable on this device'), findsOneWidget);
          expect(
            find.descendant(
              of: find.widgetWithText(ListTile, 'Health Sync'),
              matching: find.byType(Switch),
            ),
            findsNothing,
          );

          await tester.ensureVisible(find.text('Health Sync'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Health Sync'));
          await tester.pumpAndSettle();

          expect(find.text('Health Connect App Required'), findsOneWidget);
          expect(
            find.text(
              'Download the official Google Health Connect app from the Play '
              'Store to enable sync.',
            ),
            findsOneWidget,
          );
          expect(find.text('Install from Play Store'), findsOneWidget);

          await tester.tap(find.text('Install from Play Store'));
          await tester.pumpAndSettle();

          expect(find.text('Health Connect App Required'), findsNothing);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  testWidgets('renders Material Icons for settings items', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.byIcon(Icons.height), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.straighten), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);
  });

  testWidgets('shows empty export snackbar when exporting with no entries', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.ensureVisible(find.text('Export data to CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export data to CSV'));
    await tester.pump();

    expect(find.text('No weight entries to export.'), findsOneWidget);
  });

  testWidgets('renders 2-column layout on wide screen (tablet / landscape)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.byType(Row), findsWidgets);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('APPLICATION'), findsOneWidget);
    expect(find.text('SECURITY'), findsOneWidget);
    expect(find.text('DATA'), findsOneWidget);
    expect(find.text('INTEGRATIONS'), findsOneWidget);
  });

  testWidgets(
    'shows app version as subtitle and links title and subtitle in semantics',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            (call) async => {
              'appName': 'Balance',
              'packageName': 'com.example.balance',
              'version': '1.0.0',
              'buildNumber': '1',
            },
          );

      final semanticsHandle = tester.ensureSemantics();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final tileFinder = find.ancestor(
        of: find.text('App version'),
        matching: find.byType(ListTile),
      );
      final tile = tester.widget<ListTile>(tileFinder);
      expect(tile.subtitle, isNotNull);
      expect(tile.trailing, isNull);

      expect(
        find.bySemanticsLabel(RegExp(r'HELP, App version, 1\.0\.0')),
        findsOneWidget,
      );

      semanticsHandle.dispose();
    },
  );
}
