import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/widgets/widget_sync_service.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/features/settings/presentation/bloc/weight_goal_mode.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const widgetChannel = MethodChannel('home_widget');

  final Map<String, dynamic> savedData = {};
  final List<String> updatedWidgets = [];
  String? appGroupId;

  setUp(() {
    savedData.clear();
    updatedWidgets.clear();
    appGroupId = null;

    messenger.setMockMethodCallHandler(widgetChannel, (call) async {
      switch (call.method) {
        case 'setAppGroupId':
          appGroupId =
              call.arguments['groupId'] as String? ??
              (call.arguments is String ? call.arguments as String : null);
          return true;
        case 'saveWidgetData':
          final key = call.arguments['id'] as String;
          final value = call.arguments['data'];
          savedData[key] = value;
          return true;
        case 'updateWidget':
          final name =
              call.arguments['name'] as String? ??
              call.arguments['android'] as String? ??
              call.arguments['androidName'] as String? ??
              'widget';
          updatedWidgets.add(name);
          return true;
        case 'getWidgetData':
          final key = call.arguments['id'] as String;
          return savedData[key];
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(widgetChannel, null);
  });

  group('WidgetSyncService', () {
    const service = WidgetSyncService();

    test('initialize sets the app group id', () async {
      await service.initialize();
      expect(appGroupId, WidgetSyncService.appGroupId);
    });

    test('updateWidgetData with empty entries sets has_data false', () async {
      await service.updateWidgetData(
        entries: [],
        targetWeight: 75.0,
        goalMode: WeightGoalMode.lose,
        unit: MeasurementUnit.metric,
      );

      expect(savedData['has_data'], isFalse);
      expect(savedData['current_weight'], '--');
      expect(savedData['unit'], 'kg');
      expect(savedData['delta_text'], '');
      expect(savedData['goal_progress_pct'], 0);
      expect(updatedWidgets, isNotEmpty);
    });

    test(
      'updateWidgetData calculates metric values and delta correctly',
      () async {
        final entries = [
          WeightEntry(
            id: 1,
            weightKg: 80.0,
            dateTime: DateTime(2026, 8, 30, 8, 0),
          ),
          WeightEntry(
            id: 2,
            weightKg: 79.4,
            dateTime: DateTime(2026, 8, 31, 8, 0),
          ),
        ];

        await service.updateWidgetData(
          entries: entries,
          targetWeight: 75.0,
          goalMode: WeightGoalMode.lose,
          unit: MeasurementUnit.metric,
        );

        expect(savedData['has_data'], isTrue);
        expect(savedData['current_weight'], '79.4');
        expect(savedData['unit'], 'kg');
        expect(savedData['delta_text'], '-0.6 kg');
        expect(savedData['delta_is_loss'], isTrue);
        expect(savedData['target_weight'], '75.0 kg');
        // Start 80.0, current 79.4, target 75.0 -> 0.6 / 5.0 = 12%
        expect(savedData['goal_progress_pct'], 12);
        expect(savedData['goal_mode'], 'lose');
        expect(savedData['last_entry_date'], isNotEmpty);
        expect(updatedWidgets, isNotEmpty);
      },
    );

    test(
      'updateWidgetData formats imperial values and conversions correctly',
      () async {
        final entries = [
          WeightEntry(
            id: 1,
            weightKg: 70.0,
            dateTime: DateTime(2026, 8, 30, 8, 0),
          ),
          WeightEntry(
            id: 2,
            weightKg: 71.0,
            dateTime: DateTime(2026, 8, 31, 8, 0),
          ),
        ];

        await service.updateWidgetData(
          entries: entries,
          targetWeight: 75.0,
          goalMode: WeightGoalMode.gain,
          unit: MeasurementUnit.imperial,
        );

        expect(savedData['has_data'], isTrue);
        expect(savedData['unit'], 'lb');
        expect(savedData['delta_is_loss'], isFalse);
        expect(savedData['delta_text'], contains('+'));
        expect(savedData['delta_text'], contains('lb'));
        // Start 70, current 71, target 75 -> 1.0 / 5.0 = 20%
        expect(savedData['goal_progress_pct'], 20);
        expect(savedData['goal_mode'], 'gain');
      },
    );

    test('updateWidgetData handles maintain goal mode', () async {
      final entries = [
        WeightEntry(
          id: 1,
          weightKg: 75.2,
          dateTime: DateTime(2026, 8, 31, 8, 0),
        ),
      ];

      await service.updateWidgetData(
        entries: entries,
        targetWeight: 75.0,
        goalMode: WeightGoalMode.maintain,
        unit: MeasurementUnit.metric,
      );

      expect(savedData['has_data'], isTrue);
      expect(savedData['current_weight'], '75.2');
      // Within 1.0 kg -> 100%
      expect(savedData['goal_progress_pct'], 100);
      expect(savedData['goal_mode'], 'maintain');
    });

    test('clearWidgetData resets widget storage', () async {
      await service.clearWidgetData();

      expect(savedData['has_data'], isFalse);
      expect(savedData['current_weight'], '--');
      expect(savedData['delta_text'], '');
      expect(savedData['target_weight'], '');
      expect(savedData['goal_progress_pct'], 0);
      expect(savedData['last_entry_date'], '');
      expect(updatedWidgets, isNotEmpty);
    });
  });
}
