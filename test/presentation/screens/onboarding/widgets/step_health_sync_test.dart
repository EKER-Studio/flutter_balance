import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/bloc/settings/app_settings_state.dart';
import 'package:balance/presentation/screens/onboarding/widgets/step_health_sync.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockHealthService extends Mock implements HealthService {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

/// Builds a mocked [AppSettingsBloc] that reports an available health API.
///
/// The broadcast stream never emits, so the widget renders from the stubbed
/// state and recorded [AppSettingsBloc.add] calls can be verified.
MockAppSettingsBloc _buildMockSettingsBloc() {
  final bloc = MockAppSettingsBloc();
  when(
    () => bloc.state,
  ).thenReturn(const AppSettingsState(isHealthApiAvailable: true));
  when(
    () => bloc.stream,
  ).thenAnswer((_) => Stream<AppSettingsState>.multi((controller) {}));
  return bloc;
}

void main() {
  late MockHydratedStorage storage;
  late MockHealthService healthService;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  Widget buildSubject({
    required VoidCallback onNext,
    required VoidCallback onSkip,
    required AppSettingsBloc bloc,
  }) {
    return BlocProvider<AppSettingsBloc>.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StepHealthSync(onNext: onNext, onSkip: onSkip),
        ),
      ),
    );
  }

  group('StepHealthSync Widget Tests', () {
    testWidgets('renders title, description, connect, and skip buttons', (
      tester,
    ) async {
      healthService = MockHealthService();
      when(
        () => healthService.isHealthApiAvailable(),
      ).thenAnswer((_) async => true);
      final bloc = AppSettingsBloc(healthService: healthService);

      await tester.pumpWidget(
        buildSubject(onNext: () {}, onSkip: () {}, bloc: bloc),
      );

      expect(find.text('Health Sync (Optional)'), findsWidgets);
      expect(
        find.text(
          'Automatically import and export your weight measurements with '
          'Apple Health / Google Health Connect.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('health_sync_connect_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('health_sync_skip_button')), findsOneWidget);

      addTearDown(bloc.close);
    });

    testWidgets('invokes onSkip when skip button is pressed', (tester) async {
      healthService = MockHealthService();
      when(
        () => healthService.isHealthApiAvailable(),
      ).thenAnswer((_) async => true);
      final bloc = AppSettingsBloc(healthService: healthService);

      int skipCount = 0;
      await tester.pumpWidget(
        buildSubject(onNext: () {}, onSkip: () => skipCount++, bloc: bloc),
      );

      await tester.tap(find.byKey(const Key('health_sync_skip_button')));
      await tester.pumpAndSettle();
      expect(skipCount, equals(1));

      addTearDown(bloc.close);
    });

    testWidgets(
      'dispatches ToggleHealthSync(true) when the Connect button is pressed',
      (tester) async {
        final bloc = _buildMockSettingsBloc();

        await tester.pumpWidget(
          buildSubject(onNext: () {}, onSkip: () {}, bloc: bloc),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('health_sync_connect_button')));
        await tester.pump();

        verify(() => bloc.add(const ToggleHealthSync(true))).called(1);
      },
    );

    testWidgets('invokes onSkip when the Skip button is pressed', (
      tester,
    ) async {
      final bloc = _buildMockSettingsBloc();

      int skipCount = 0;
      await tester.pumpWidget(
        buildSubject(onNext: () {}, onSkip: () => skipCount++, bloc: bloc),
      );
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(skipCount, equals(1));
    });

    testWidgets(
      'connects via the bloc and auto-advances after a short success state',
      (tester) async {
        healthService = MockHealthService();
        when(
          () => healthService.isHealthApiAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => true);
        final bloc = AppSettingsBloc(healthService: healthService);

        int nextCount = 0;
        await tester.pumpWidget(
          buildSubject(onNext: () => nextCount++, onSkip: () {}, bloc: bloc),
        );

        await tester.tap(find.byKey(const Key('health_sync_connect_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));

        expect(bloc.state.isHealthSyncEnabled, isTrue);
        expect(find.text('Health sync connected!'), findsOneWidget);
        expect(nextCount, equals(1));

        addTearDown(bloc.close);
      },
    );

    testWidgets('shows inline warning when permission request is denied', (
      tester,
    ) async {
      healthService = MockHealthService();
      when(
        () => healthService.isHealthApiAvailable(),
      ).thenAnswer((_) async => true);
      when(
        () => healthService.requestPermissions(),
      ).thenAnswer((_) async => false);
      final bloc = AppSettingsBloc(healthService: healthService);

      await tester.pumpWidget(
        buildSubject(onNext: () {}, onSkip: () {}, bloc: bloc),
      );

      await tester.tap(find.byKey(const Key('health_sync_connect_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Health data permissions are required to sync weight.'),
        findsOneWidget,
      );
      expect(bloc.state.isHealthSyncEnabled, isFalse);

      addTearDown(bloc.close);
    });

    // TEMPORARY DIAGNOSTIC: reflects the debug bypass of the availability
    // gate in AppSettingsBloc; restore together with the gate.
    testWidgets(
      'shows inline warning when permission request is denied even if the '
      'API check reports unavailable',
      (tester) async {
        healthService = MockHealthService();
        when(
          () => healthService.isHealthApiAvailable(),
        ).thenAnswer((_) async => false);
        when(
          () => healthService.requestPermissions(),
        ).thenAnswer((_) async => false);
        final bloc = AppSettingsBloc(healthService: healthService);

        await tester.pumpWidget(
          buildSubject(onNext: () {}, onSkip: () {}, bloc: bloc),
        );

        await tester.tap(find.byKey(const Key('health_sync_connect_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Health data permissions are required to sync weight.'),
          findsOneWidget,
        );

        addTearDown(bloc.close);
      },
    );
  });
}
