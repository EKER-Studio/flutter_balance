import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show FlutterLocalNotificationsPlatform;
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart'
    show AndroidFlutterLocalNotificationsPlugin;
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/statistics/domain/entities/milestone.dart';
import 'package:balance/features/statistics/presentation/utils/milestone_notification_coordinator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/l10n/app_localizations_en.dart';

class FakeNotificationChannel {
  final List<MethodCall> calls = [];

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    return switch (call.method) {
      'initialize' => true,
      'createNotificationChannel' => null,
      'cancel' => null,
      'show' => null,
      'zonedSchedule' => null,
      'requestNotificationsPermission' => true,
      'requestPermissions' => true,
      _ => null,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezoneChannel = MethodChannel('flutter_timezone');

  late FakeNotificationChannel fake;
  late AppLocalizations l10n;
  late MilestoneNotificationCoordinator coordinator;
  late FlutterLocalNotificationsPlatform? originalPlatform;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    fake = FakeNotificationChannel();
    messenger.setMockMethodCallHandler(notificationsChannel, fake.handle);
    messenger.setMockMethodCallHandler(
      timezoneChannel,
      (call) async => 'Europe/Warsaw',
    );

    try {
      originalPlatform = FlutterLocalNotificationsPlatform.instance;
    } catch (_) {
      originalPlatform = null;
    }
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();

    await NotificationService.instance.initialize();
    fake.calls.clear();

    l10n = AppLocalizationsEn();
    coordinator = MilestoneNotificationCoordinator();
  });

  tearDown(() {
    if (originalPlatform != null) {
      FlutterLocalNotificationsPlatform.instance = originalPlatform!;
    }
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(notificationsChannel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
  });

  group('MilestoneNotificationCoordinator', () {
    test('does nothing when entries are empty', () {
      coordinator.checkForNewMilestones(
        entries: const [],
        targetWeight: 75.0,
        heightCm: 180.0,
        goalMode: WeightGoalMode.lose,
        l10n: l10n,
      );

      expect(coordinator.knownUnlockedTypes, isNull);
      expect(fake.calls.where((c) => c.method == 'show'), isEmpty);
    });

    test(
      'initial call establishes baseline without triggering notifications',
      () {
        final initialEntries = [
          WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
        ];

        coordinator.checkForNewMilestones(
          entries: initialEntries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        expect(coordinator.knownUnlockedTypes, isNotNull);
        expect(
          coordinator.knownUnlockedTypes,
          contains(MilestoneType.firstEntry),
        );
        expect(fake.calls.where((c) => c.method == 'show'), isEmpty);
      },
    );

    test(
      'subsequent call with no new milestones triggers no notifications',
      () {
        final entries = [
          WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
        ];

        coordinator.checkForNewMilestones(
          entries: entries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        fake.calls.clear();

        coordinator.checkForNewMilestones(
          entries: entries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        expect(fake.calls.where((c) => c.method == 'show'), isEmpty);
      },
    );

    test(
      'triggers individual notification when a new milestone is unlocked',
      () {
        final initialEntries = [
          WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
        ];

        coordinator.checkForNewMilestones(
          entries: initialEntries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        fake.calls.clear();

        // Adding 1kg weight loss entry (80.0 -> 78.5 kg = -1.5 kg loss)
        final updatedEntries = [
          ...initialEntries,
          WeightEntry(id: 2, weightKg: 78.5, dateTime: DateTime(2026, 1, 2)),
        ];

        coordinator.checkForNewMilestones(
          entries: updatedEntries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        final showCalls = fake.calls.where((c) => c.method == 'show').toList();
        expect(showCalls, isNotEmpty);
        expect(
          coordinator.knownUnlockedTypes,
          contains(MilestoneType.weightLoss1kg),
        );
      },
    );

    test(
      'triggers batch notification when > 2 milestones are unlocked at once',
      () {
        // Establish baseline with single entry
        final initialEntries = [
          WeightEntry(id: 1, weightKg: 90.0, dateTime: DateTime(2026, 1, 1)),
        ];

        coordinator.checkForNewMilestones(
          entries: initialEntries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        fake.calls.clear();

        // Add 7 days of entries losing 11 kg reaching goal and healthy BMI
        // This unlocks: streak7, weightLoss1kg, weightLoss5kg, weightLoss10kg, goalHalfway, goalReached, healthyBmi
        final updatedEntries = [
          ...initialEntries,
          WeightEntry(id: 2, weightKg: 88.0, dateTime: DateTime(2026, 1, 2)),
          WeightEntry(id: 3, weightKg: 86.0, dateTime: DateTime(2026, 1, 3)),
          WeightEntry(id: 4, weightKg: 84.0, dateTime: DateTime(2026, 1, 4)),
          WeightEntry(id: 5, weightKg: 82.0, dateTime: DateTime(2026, 1, 5)),
          WeightEntry(id: 6, weightKg: 80.0, dateTime: DateTime(2026, 1, 6)),
          WeightEntry(id: 7, weightKg: 74.0, dateTime: DateTime(2026, 1, 7)),
        ];

        coordinator.checkForNewMilestones(
          entries: updatedEntries,
          targetWeight: 75.0,
          heightCm: 180.0,
          goalMode: WeightGoalMode.lose,
          l10n: l10n,
        );

        final showCalls = fake.calls.where((c) => c.method == 'show').toList();
        expect(showCalls, hasLength(1));
        final callArgs = showCalls.first.arguments as Map<dynamic, dynamic>;
        expect(callArgs['id'], 999);
        expect(callArgs['title'], contains('🏆'));
      },
    );

    test('reset clears the tracked baseline', () {
      final entries = [
        WeightEntry(id: 1, weightKg: 80.0, dateTime: DateTime(2026, 1, 1)),
      ];

      coordinator.checkForNewMilestones(
        entries: entries,
        targetWeight: 75.0,
        heightCm: 180.0,
        goalMode: WeightGoalMode.lose,
        l10n: l10n,
      );

      expect(coordinator.knownUnlockedTypes, isNotNull);

      coordinator.reset();

      expect(coordinator.knownUnlockedTypes, isNull);
    });
  });
}
