import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_reminder_notification.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    registerFallbackValue(const (hour: 8, minute: 0));
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
        home: Scaffold(body: StepReminderNotification(onNext: onNext)),
      ),
    );
  }

  Widget buildEnabledSubject() {
    final mockNotificationService = MockNotificationService();
    when(
      () => mockNotificationService.requestPermissions(),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationService.scheduleDailyReminder(any()),
    ).thenAnswer((_) async => true);
    when(
      () => mockNotificationService.canScheduleExactNotifications(),
    ).thenAnswer((_) async => true);
    settingsBloc = AppSettingsBloc(
      notificationService: mockNotificationService,
    );
    return buildSubject(onNext: () {});
  }

  group('StepReminderNotification Widget Tests', () {
    testWidgets('renders step title, description, switch, and next button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(onNext: () {}));

      expect(find.text('Weight Notifications'), findsWidgets);
      expect(
        find.text(
          'Build a healthy habit and let us remind you to log your weight every day.',
        ),
        findsOneWidget,
      );
      expect(find.text('Daily Reminder'), findsOneWidget);
      expect(
        find.text('Regular alert in your notification center'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('notification_step_switch')), findsOneWidget);
      expect(
        find.byKey(const Key('notification_step_next_button')),
        findsOneWidget,
      );
    });

    testWidgets('invokes onNext when next button is pressed', (tester) async {
      int nextCount = 0;
      await tester.pumpWidget(buildSubject(onNext: () => nextCount++));

      await tester.tap(find.byKey(const Key('notification_step_next_button')));
      await tester.pumpAndSettle();
      expect(nextCount, equals(1));
    });

    testWidgets(
      'toggling the switch enables notifications via the bloc and enables time tile',
      (tester) async {
        await tester.pumpWidget(buildEnabledSubject());

        expect(settingsBloc.state.notificationsEnabled, isFalse);
        final timeTileBefore = tester.widget<ListTile>(
          find.byKey(const Key('notification_step_time_tile')),
        );
        expect(timeTileBefore.enabled, isFalse);

        await tester.tap(find.byKey(const Key('notification_step_switch')));
        await tester.pumpAndSettle();

        expect(settingsBloc.state.notificationsEnabled, isTrue);
        final timeTileAfter = tester.widget<ListTile>(
          find.byKey(const Key('notification_step_time_tile')),
        );
        expect(timeTileAfter.enabled, isTrue);
      },
    );

    testWidgets(
      'toggling with denied permission shows the permission denied warning',
      (tester) async {
        final mockNotificationService = MockNotificationService();
        when(
          () => mockNotificationService.requestPermissions(),
        ).thenAnswer((_) async => false);
        when(
          () => mockNotificationService.scheduleDailyReminder(any()),
        ).thenAnswer((_) async => true);

        settingsBloc = AppSettingsBloc(
          notificationService: mockNotificationService,
        );

        await tester.pumpWidget(buildSubject(onNext: () {}));

        expect(
          find.text('Notification permission is required to enable reminders.'),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('notification_step_switch')));
        await tester.pumpAndSettle();

        expect(
          find.text('Notification permission is required to enable reminders.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'opening the time picker and confirming dispatches the new time',
      (tester) async {
        await tester.pumpWidget(buildEnabledSubject());
        await tester.tap(find.byKey(const Key('notification_step_switch')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('notification_step_time_tile')));
        await tester.pumpAndSettle();

        expect(find.byType(TimePickerDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.textContaining('reminder set to'), findsOneWidget);
        expect(settingsBloc.state.notificationTime, const (hour: 8, minute: 0));
      },
    );

    testWidgets('canceling the time picker keeps the current time', (
      tester,
    ) async {
      await tester.pumpWidget(buildEnabledSubject());
      await tester.tap(find.byKey(const Key('notification_step_switch')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_step_time_tile')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.textContaining('reminder set to'), findsNothing);
      expect(settingsBloc.state.notificationTime, isNotNull);
    });
  });
}
