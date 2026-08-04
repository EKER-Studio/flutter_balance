import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
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

    settingsBloc = AppSettingsBloc();
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

      await tester.drag(find.text('PROFILE'), const Offset(0, -500));
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

    await tester.drag(find.text('PROFILE'), const Offset(0, -500));
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

    await tester.drag(find.text('PROFILE'), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wipe All Data'));
    await tester.pump();

    await tester.tap(find.text('Wipe Data'));
    await tester.pump();

    verifyNever(() => storage.clear());
  });

  testWidgets('renders Material Icons for settings items', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();

    expect(find.byIcon(Icons.height), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.straighten), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
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

    await tester.drag(find.text('PROFILE'), const Offset(0, -500));
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
  });
}
