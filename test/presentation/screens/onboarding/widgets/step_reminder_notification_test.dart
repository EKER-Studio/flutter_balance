import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_reminder_notification.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockNotificationService extends Mock implements NotificationService {}

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
        home: Scaffold(body: StepReminderNotification(onNext: onNext)),
      ),
    );
  }

  group('StepReminderNotification Widget Tests', () {
    testWidgets('renders step title, description, switch, and next button', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(onNext: () {}));

      expect(find.text('Daily Reminder (Optional)'), findsWidgets);
      expect(
        find.text('Set a daily reminder to log your weight and stay on track.'),
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
      'toggling the switch enables notifications via the bloc and shows time tile',
      (tester) async {
        final mockNotificationService = MockNotificationService();
        registerFallbackValue(const TimeOfDay(hour: 8, minute: 0));
        when(
          () => mockNotificationService.requestPermissions(),
        ).thenAnswer((_) async => true);
        when(
          () => mockNotificationService.scheduleDailyReminder(any()),
        ).thenAnswer((_) async => true);

        settingsBloc = AppSettingsBloc(
          notificationService: mockNotificationService,
        );

        await tester.pumpWidget(buildSubject(onNext: () {}));

        expect(settingsBloc.state.notificationsEnabled, isFalse);
        expect(
          find.byKey(const Key('notification_step_time_tile')),
          findsNothing,
        );

        await tester.tap(find.byKey(const Key('notification_step_switch')));
        await tester.pumpAndSettle();

        expect(settingsBloc.state.notificationsEnabled, isTrue);
        expect(
          find.byKey(const Key('notification_step_time_tile')),
          findsOneWidget,
        );
      },
    );
  });
}
