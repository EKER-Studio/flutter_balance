import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/core/models/measurement_unit.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

class MockNotificationService extends Mock implements NotificationService {}

class MockHealthService extends Mock implements HealthService {}

/// Test double for [FilePickerPlatform] with a configurable result, so the
/// platform token verification in `FilePickerPlatform.instance =` passes.
class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.onPickFiles);

  final Future<FilePickerResult?> Function({
    required FileType type,
    List<String>? allowedExtensions,
  })
  onPickFiles;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) {
    return onPickFiles(type: type, allowedExtensions: allowedExtensions);
  }
}

/// Test double for [LocalAuthPlatform] with mutable support flags so tests can
/// simulate the device capability changing between checks.
class MutableLocalAuthPlatform extends LocalAuthPlatform {
  bool deviceSupported = true;
  bool supportsBiometrics = true;
  Future<bool> Function()? authenticateHandler;

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
    final handler = authenticateHandler;
    return handler != null ? await handler() : true;
  }
}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late MockHealthService healthService;
  late AppSettingsBloc settingsBloc;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(const SubscribeToWeightChanges());
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    tempDir = Directory.systemTemp.createTempSync('settings_screen_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async => 'dev.fluttercommunity.plus/share/success',
        );

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

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
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

  /// Pumps frames until [finder] matches, guarding against microtask/frame
  /// races between BLoC emits and the next rendered frame.
  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 24,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
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
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Metric (kg, cm)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metric (kg, cm)'));
    await tester.pump();

    expect(find.text('Imperial (lb, ft/in)'), findsOneWidget);
  });

  testWidgets(
    'shows pace window selection dialog on pace window tap and updates state',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Pace calculation window'));
      await tester.pumpAndSettle();

      expect(find.text('Pace calculation window'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);

      await tester.tap(find.text('Pace calculation window'));
      await tester.pumpAndSettle();

      expect(find.text('Last 30 days (default)'), findsOneWidget);
      expect(find.text('Last 60 days'), findsOneWidget);

      await tester.tap(find.text('Last 60 days'));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.weeklyPaceWindowDays, 60);
    },
  );

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
      registerFallbackValue(const (hour: 8, minute: 0));
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => false);
      when(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).thenAnswer((_) async => true);

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

  testWidgets(
    'enables daily reminder notification without requiring exact alarms',
    (tester) async {
      final mockNotificationService = MockNotificationService();
      registerFallbackValue(const (hour: 8, minute: 0));
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).thenAnswer((_) async => true);

      settingsBloc = AppSettingsBloc(
        notificationService: mockNotificationService,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      verify(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).called(1);
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

  testWidgets('shows success snackbar only after the wipe completes', (
    tester,
  ) async {
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(const WeightLoaded(entries: [], filteredEntries: [])),
    );

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.ensureVisible(find.text('Wipe All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    await tester.tap(find.text('Wipe Data'));
    await tester.pumpAndSettle();

    expect(
      find.text('All data has been wiped. Restart the app.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error snackbar when the wipe fails', (tester) async {
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(
        const WeightError(
          errorType: WeightErrorType.wipeFailed,
          entries: [],
          filteredEntries: [],
        ),
      ),
    );

    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    await tester.ensureVisible(find.text('Wipe All Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    await tester.tap(find.text('Wipe Data'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to clear weight data.'), findsOneWidget);
  });

  group('Health sync', () {
    const healthServiceTitle = 'Health Connect';

    Finder healthSyncSwitch([String title = healthServiceTitle]) =>
        find.descendant(
          of: find.widgetWithText(ListTile, title),
          matching: find.byType(Switch),
        );

    testWidgets('renders the health sync switch enabled by default', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Health Connect'), findsOneWidget);
      expect(find.text('Sync weight data with Health Connect'), findsOneWidget);
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

        expect(settingsBloc.state.isHealthSyncEnabled, isFalse);
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
          when(
            () => healthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
          when(
            () => healthService.hasPermissions(),
          ).thenAnswer((_) async => false);

          settingsBloc = AppSettingsBloc(healthService: healthService);
          settingsBloc.add(const CheckHealthSyncStatus());
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Unavailable on this device'), findsOneWidget);
          expect(
            tester.widget<Switch>(healthSyncSwitch('Apple Health')).onChanged,
            isNull,
          );
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
          when(
            () => healthService.isHealthApiAvailable(),
          ).thenAnswer((_) async => false);
          when(
            () => healthService.hasPermissions(),
          ).thenAnswer((_) async => false);

          settingsBloc = AppSettingsBloc(healthService: healthService);
          settingsBloc.add(const CheckHealthSyncStatus());
          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Unavailable on this device'), findsOneWidget);
          expect(
            find.descendant(
              of: find.widgetWithText(ListTile, 'Health Connect'),
              matching: find.byType(Switch),
            ),
            findsNothing,
          );

          await tester.ensureVisible(find.text('Health Connect'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Health Connect'));
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

  testWidgets('shows empty export snackbar for a non-loaded weight state', (
    tester,
  ) async {
    when(() => weightBloc.state).thenReturn(const WeightInitial());

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

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

  group('SettingsScreen narrow layout', () {
    void useNarrowSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('height dialog closes without saving and ignores null result', (
      tester,
    ) async {
      useNarrowSurface(tester);
      settingsBloc.add(const UpdateHeight(170.0));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('170 cm'));
      await tester.pumpAndSettle();
      expect(find.text('Set Height'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Set Height'), findsNothing);
      expect(settingsBloc.state.height, 170.0);
    });

    testWidgets('theme selection applies the chosen mode', (tester) async {
      useNarrowSurface(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.themeMode, AppThemeMode.light);
      expect(find.text('Dark'), findsNothing);
    });

    testWidgets('unit selection applies the chosen unit', (tester) async {
      useNarrowSurface(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.text('Metric (kg, cm)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Imperial (lb, ft/in)'));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.measurementUnit, MeasurementUnit.imperial);
      expect(find.text('Light'), findsNothing);
    });

    testWidgets('target weight can be saved and cleared', (tester) async {
      useNarrowSurface(tester);
      settingsBloc = AppSettingsBloc(healthService: healthService);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not set'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '80');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.textContaining('80.0 kg'));

      expect(settingsBloc.state.targetWeight, 80.0);
      expect(find.textContaining('80.0 kg'), findsOneWidget);

      await tester.tap(find.textContaining('80.0 kg'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await pumpUntilFound(tester, find.text('Not set'));

      expect(settingsBloc.state.targetWeight, isNull);
    });

    testWidgets('notification toggle and time picker update the reminder', (
      tester,
    ) async {
      useNarrowSurface(tester);
      final mockNotificationService = MockNotificationService();
      registerFallbackValue(const (hour: 8, minute: 0));
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).thenAnswer((_) async => true);
      settingsBloc = AppSettingsBloc(
        notificationService: mockNotificationService,
      );
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reminder Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reminder Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.notificationTime, (hour: 8, minute: 0));
    });

    testWidgets('health install dialog can be canceled', (tester) async {
      useNarrowSurface(tester);
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

        await tester.ensureVisible(find.text('Health Connect'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Health Connect'));
        await tester.pumpAndSettle();
        expect(find.text('Health Connect App Required'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Health Connect App Required'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('height dialog save persists to both blocs', (tester) async {
      useNarrowSurface(tester);
      settingsBloc.add(const UpdateHeight(170.0));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('170 cm'));
      await tester.pumpAndSettle();
      expect(find.text('Set Height'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '175');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Set Height'), findsNothing);
      expect(settingsBloc.state.height, 175.0);
      verify(
        () => weightBloc.add(any(that: isA<UpdateUserHeight>())),
      ).called(1);
    });

    testWidgets('health sync switch enables sync in narrow layout', (
      tester,
    ) async {
      useNarrowSurface(tester);
      settingsBloc = AppSettingsBloc(healthService: healthService);
      when(
        () => healthService.requestPermissions(),
      ).thenAnswer((_) async => true);
      when(() => healthService.hasPermissions()).thenAnswer((_) async => true);
      final syncSwitch = find.descendant(
        of: find.widgetWithText(ListTile, 'Health Connect'),
        matching: find.byType(Switch),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(syncSwitch);
      await tester.pumpAndSettle();
      await tester.tap(syncSwitch);
      await tester.pumpAndSettle();

      verify(() => healthService.requestPermissions()).called(1);
      expect(tester.widget<Switch>(syncSwitch).value, isTrue);
    });

    testWidgets('data section import export and wipe in narrow layout', (
      tester,
    ) async {
      useNarrowSurface(tester);
      final previousPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => null,
      );
      addTearDown(() => FilePickerPlatform.instance = previousPicker);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Import data from CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import data from CSV'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Export data to CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export data to CSV'));
      await tester.pumpAndSettle();
      expect(find.text('No weight entries to export.'), findsOneWidget);

      await tester.ensureVisible(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
      expect(find.text('Wipe Data'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('privacy policy tile in narrow layout', (tester) async {
      useNarrowSurface(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('narrow layout biometric toggle works', (tester) async {
      useNarrowSurface(tester);
      final platform = MutableLocalAuthPlatform()
        ..authenticateHandler = () async => true;
      LocalAuthPlatform.instance = platform;
      BiometricService.resetForTesting();
      settingsBloc.add(const UpdateBiometricSupport(true));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final switchFinder = find.descendant(
        of: find.widgetWithText(ListTile, 'Biometric Protection'),
        matching: find.byType(Switch),
      );

      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isTrue);
    });

    testWidgets('wide layout time picker updates the reminder', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockNotificationService = MockNotificationService();
      registerFallbackValue(const (hour: 8, minute: 0));
      when(
        () => mockNotificationService.requestPermissions(),
      ).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.scheduleDailyReminder(any()),
      ).thenAnswer((_) async => true);
      settingsBloc = AppSettingsBloc(
        notificationService: mockNotificationService,
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Reminder Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reminder Time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.notificationTime, (hour: 8, minute: 0));
    });
  });

  group('SettingsScreen biometric flows', () {
    late MutableLocalAuthPlatform platform;
    Finder biometricSwitch() => find.descendant(
      of: find.widgetWithText(ListTile, 'Biometric Protection'),
      matching: find.byType(Switch),
    );

    setUp(() {
      platform = MutableLocalAuthPlatform();
      LocalAuthPlatform.instance = platform;
      BiometricService.resetForTesting();
      settingsBloc.add(const UpdateBiometricSupport(true));
    });

    testWidgets('shows unavailability snackbar when device has no biometrics', (
      tester,
    ) async {
      platform.deviceSupported = false;
      platform.supportsBiometrics = false;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(
        find.text('Biometrics not available on this device'),
        findsWidgets,
      );
      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets('enables the lock after successful authentication', (
      tester,
    ) async {
      platform.authenticateHandler = () async => true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isTrue);
    });

    testWidgets('shows failure snackbar when authentication is canceled', (
      tester,
    ) async {
      platform.authenticateHandler = () async => false;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(
        find.text('Biometric authentication failed or was canceled.'),
        findsOneWidget,
      );
      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets(
      'shows unavailability snackbar when biometrics become unavailable '
      'after the screen loaded',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(biometricSwitch());
        await tester.pumpAndSettle();

        platform.deviceSupported = false;
        platform.supportsBiometrics = false;

        await tester.tap(biometricSwitch());
        await tester.pumpAndSettle();

        expect(
          find.text('Biometrics not available on this device'),
          findsWidgets,
        );
        expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
      },
    );

    testWidgets('shows unavailability snackbar on terminal auth failure', (
      tester,
    ) async {
      platform.authenticateHandler = () async => throw LocalAuthException(
        code: LocalAuthExceptionCode.noBiometricsEnrolled,
        description: 'no enrolled biometrics',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(
        find.text('Biometrics not available on this device'),
        findsWidgets,
      );
      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets('disables the lock directly without authentication', (
      tester,
    ) async {
      settingsBloc.add(const UpdateBiometricLock(true));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isFalse);
    });

    testWidgets('wide layout biometric toggle works', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      platform.authenticateHandler = () async => true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(biometricSwitch());
      await tester.pumpAndSettle();
      await tester.tap(biometricSwitch());
      await tester.pumpAndSettle();

      expect(settingsBloc.state.isBiometricLockEnabled, isTrue);
    });
  });

  group('SettingsScreen CSV flows', () {
    void useWideSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    setUp(() {
      LocalAuthPlatform.instance = MutableLocalAuthPlatform();
      BiometricService.resetForTesting();
      registerFallbackValue(const SyncHealthEntries());
    });

    testWidgets('triggers CSV analysis and completes import flow via dialog', (
      tester,
    ) async {
      useWideSurface(tester);

      final stateController = StreamController<WeightState>.broadcast();
      when(() => weightBloc.stream).thenAnswer((_) => stateController.stream);

      final csvFile = File('${tempDir.path}/import.csv')
        ..writeAsStringSync('Date,Weight (kg)\n2026-07-25 08:30,69.0\n');
      FilePickerPlatform.instance = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => FilePickerResult([
          PlatformFile(path: csvFile.path, name: 'import.csv', size: 1),
        ]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Import data from CSV'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('Import data from CSV'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      final captured = verify(() => weightBloc.add(captureAny())).captured;
      expect(captured.last, isA<AnalyzeCsvFile>());

      stateController.add(
        CsvAnalysisReady(
          entries: [],
          filteredEntries: [],
          analysis: (
            validEntries: [
              WeightEntry(weightKg: 69.0, dateTime: DateTime(2026, 7, 25)),
            ],
            skippedRowCount: 0,
            earliestDate: DateTime(2026, 7, 25),
            latestDate: DateTime(2026, 7, 25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Import Preview'), findsOneWidget);
      expect(find.text('Confirm import'), findsOneWidget);

      await tester.tap(find.text('Confirm import'));
      await tester.pumpAndSettle();

      final captured2 = verify(() => weightBloc.add(captureAny())).captured;
      expect(captured2.last, isA<ConfirmCsvImport>());

      stateController.add(
        const WeightImportSuccess(
          entries: [],
          filteredEntries: [],
          importedCount: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imported 1 new entry'), findsOneWidget);

      await stateController.close();
    });

    testWidgets('shows no-data snackbar when BLoC emits noEntries error', (
      tester,
    ) async {
      useWideSurface(tester);
      final stateController = StreamController<WeightState>.broadcast();
      when(() => weightBloc.stream).thenAnswer((_) => stateController.stream);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      stateController.add(
        const CsvAnalysisError(
          entries: [],
          filteredEntries: [],
          errorType: CsvErrorType.noEntries,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No valid measurements found in this file'),
        findsOneWidget,
      );

      await stateController.close();
    });

    testWidgets('shows error snackbar when BLoC emits invalidFormat error', (
      tester,
    ) async {
      useWideSurface(tester);
      final stateController = StreamController<WeightState>.broadcast();
      when(() => weightBloc.stream).thenAnswer((_) => stateController.stream);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      stateController.add(
        const CsvAnalysisError(
          entries: [],
          filteredEntries: [],
          errorType: CsvErrorType.invalidFormat,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No date and weight columns found'), findsOneWidget);

      await stateController.close();
    });

    testWidgets('exports entries to a CSV file via the share sheet', (
      tester,
    ) async {
      useWideSurface(tester);
      when(() => weightBloc.state).thenReturn(
        WeightLoaded(
          entries: [
            WeightEntry(
              id: 1,
              weightKg: 70.5,
              dateTime: DateTime(2026, 7, 24, 15, 0),
            ),
          ],
          filteredEntries: [],
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Export data to CSV'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Export data to CSV'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(tempDir.listSync().isNotEmpty, isTrue);
      expect(find.text('Export completed successfully.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when sharing fails', (tester) async {
      useWideSurface(tester);
      when(() => weightBloc.state).thenReturn(
        WeightLoaded(
          entries: [
            WeightEntry(
              id: 1,
              weightKg: 70.5,
              dateTime: DateTime(2026, 7, 24, 15, 0),
            ),
          ],
          filteredEntries: [],
        ),
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/share'),
            (call) async => throw PlatformException(code: 'share_failed'),
          );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Export data to CSV'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Export data to CSV'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('Export error:'), findsOneWidget);
    });

    testWidgets('renders privacy policy tile in help section', (tester) async {
      useWideSurface(tester);
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('tapping privacy policy tile opens PrivacyPolicyScreen', (
      tester,
    ) async {
      useWideSurface(tester);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
    });
  });

  group('SettingsScreen wipe flows', () {
    testWidgets('cancel button dismisses the confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wipe All Data'));
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Wipe Data'), findsNothing);
    });

    testWidgets('shows error snackbar when the wipe stream fails', (
      tester,
    ) async {
      when(() => weightBloc.stream).thenAnswer(
        (_) => Stream.value(
          const WeightError(
            errorType: WeightErrorType.wipeFailed,
            entries: [],
            filteredEntries: [],
          ),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wipe All Data'));
      await tester.pump();

      await tester.tap(find.text('Wipe Data'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to clear weight data.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when the wipe stream times out', (
      tester,
    ) async {
      when(
        () => weightBloc.stream,
      ).thenAnswer((_) => Stream.fromIterable(const [WeightLoading()]));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.ensureVisible(find.text('Wipe All Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wipe All Data'));
      await tester.pump();

      await tester.tap(find.text('Wipe Data'));
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error wiping data:'), findsOneWidget);
    });

    testWidgets(
      'SettingsScreen renders single column clamped to 480 on mobile landscape',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final clampedLayoutFinder = find.byType(ClampedLayout);
        expect(clampedLayoutFinder, findsOneWidget);
        final clampedLayout = tester.widget<ClampedLayout>(clampedLayoutFinder);
        expect(clampedLayout.maxWidth, 480);
      },
    );
  });
}
