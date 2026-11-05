import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/statistics/presentation/utils/summary_share_coordinator.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/weight_goal_mode.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  MethodCall? lastCall;

  setUp(() {
    lastCall = null;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      lastCall = call;
      if (call.method == 'share') {
        return 'success';
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(shareChannel, null);
  });

  testWidgets('returns early without sharing if entries is empty', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    await SummaryShareCoordinator.shareProgress(
      capturedContext,
      entries: const <WeightEntry>[],
      unit: MeasurementUnit.metric,
    );

    expect(lastCall, isNull);
  });

  testWidgets('formats and triggers SharePlus when entries are provided', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox(width: 200, height: 100);
          },
        ),
      ),
    );

    final entries = [
      WeightEntry(id: 1, weightKg: 85.0, dateTime: DateTime(2026, 1, 1)),
      WeightEntry(id: 2, weightKg: 80.0, dateTime: DateTime(2026, 2, 1)),
    ];

    await SummaryShareCoordinator.shareProgress(
      capturedContext,
      entries: entries,
      targetWeight: 75.0,
      goalMode: WeightGoalMode.lose,
      unit: MeasurementUnit.metric,
      heightCm: 180.0,
    );

    expect(lastCall, isNotNull);
    expect(lastCall!.method, equals('share'));
    final arguments = lastCall!.arguments as Map<dynamic, dynamic>;
    final sharedText = arguments['text'] as String;
    expect(sharedText, contains('Total Progress'));
    expect(sharedText, contains('85.0 kg'));
    expect(sharedText, contains('80.0 kg'));
    expect(arguments['subject'], isNotNull);
  });
}
