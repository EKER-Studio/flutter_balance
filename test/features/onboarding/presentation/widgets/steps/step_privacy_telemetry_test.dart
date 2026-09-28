import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/onboarding/presentation/widgets/steps/step_privacy_telemetry.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

MockAppSettingsBloc _buildMockSettingsBloc({
  bool analyticsEnabled = false,
  bool crashReportingEnabled = false,
}) {
  final bloc = MockAppSettingsBloc();
  when(() => bloc.state).thenReturn(
    AppSettingsState(
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
    ),
  );
  when(
    () => bloc.stream,
  ).thenAnswer((_) => Stream<AppSettingsState>.multi((controller) {}));
  return bloc;
}

void main() {
  late MockHydratedStorage storage;

  setUpAll(() {
    registerFallbackValue(const ToggleAnalytics(false));
    registerFallbackValue(const ToggleCrashReporting(false));
  });

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
  });

  Widget buildSubject({
    required VoidCallback onNext,
    required AppSettingsBloc bloc,
  }) {
    return BlocProvider<AppSettingsBloc>.value(
      value: bloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StepPrivacyTelemetry(onNext: onNext)),
      ),
    );
  }

  final analyticsSwitchFinder = find.byKey(
    const Key('privacy_step_analytics_switch'),
  );
  final crashReportsSwitchFinder = find.byKey(
    const Key('privacy_step_crash_reports_switch'),
  );
  final nextButtonFinder = find.byKey(const Key('privacy_step_next_button'));

  group('StepPrivacyTelemetry Widget Tests', () {
    testWidgets('renders title, subtitle, switches and next button', (
      tester,
    ) async {
      final bloc = _buildMockSettingsBloc();

      await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));

      expect(find.text('Privacy & Diagnostics'), findsOneWidget);
      expect(
        find.textContaining('Balance is built local-first'),
        findsOneWidget,
      );
      expect(find.text('Usage analytics'), findsOneWidget);
      expect(find.textContaining('Firebase Analytics'), findsOneWidget);
      expect(find.text('Crash reports'), findsOneWidget);
      expect(find.textContaining('Firebase Crashlytics'), findsOneWidget);
      expect(analyticsSwitchFinder, findsOneWidget);
      expect(crashReportsSwitchFinder, findsOneWidget);
      expect(nextButtonFinder, findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(analyticsSwitchFinder).value,
        isFalse,
      );
      expect(
        tester.widget<SwitchListTile>(crashReportsSwitchFinder).value,
        isFalse,
      );
    });

    testWidgets('renders initial switch values reflecting state', (
      tester,
    ) async {
      final bloc = _buildMockSettingsBloc(
        analyticsEnabled: true,
        crashReportingEnabled: true,
      );

      await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));

      expect(
        tester.widget<SwitchListTile>(analyticsSwitchFinder).value,
        isTrue,
      );
      expect(
        tester.widget<SwitchListTile>(crashReportsSwitchFinder).value,
        isTrue,
      );
    });

    testWidgets(
      'dispatches ToggleAnalytics(true) when analytics switch is toggled on',
      (tester) async {
        final bloc = _buildMockSettingsBloc(analyticsEnabled: false);

        await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));
        await tester.tap(analyticsSwitchFinder);
        await tester.pump();

        final captured = verify(() => bloc.add(captureAny())).captured;
        final event = captured.single as ToggleAnalytics;
        expect(event.enabled, isTrue);
      },
    );

    testWidgets(
      'dispatches ToggleAnalytics(false) when analytics switch is toggled off',
      (tester) async {
        final bloc = _buildMockSettingsBloc(analyticsEnabled: true);

        await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));
        await tester.tap(analyticsSwitchFinder);
        await tester.pump();

        final captured = verify(() => bloc.add(captureAny())).captured;
        final event = captured.single as ToggleAnalytics;
        expect(event.enabled, isFalse);
      },
    );

    testWidgets(
      'dispatches ToggleCrashReporting(true) when crash reports switch is toggled on',
      (tester) async {
        final bloc = _buildMockSettingsBloc(crashReportingEnabled: false);

        await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));
        await tester.tap(crashReportsSwitchFinder);
        await tester.pump();

        final captured = verify(() => bloc.add(captureAny())).captured;
        final event = captured.single as ToggleCrashReporting;
        expect(event.enabled, isTrue);
      },
    );

    testWidgets(
      'dispatches ToggleCrashReporting(false) when crash reports switch is toggled off',
      (tester) async {
        final bloc = _buildMockSettingsBloc(crashReportingEnabled: true);

        await tester.pumpWidget(buildSubject(onNext: () {}, bloc: bloc));
        await tester.tap(crashReportsSwitchFinder);
        await tester.pump();

        final captured = verify(() => bloc.add(captureAny())).captured;
        final event = captured.single as ToggleCrashReporting;
        expect(event.enabled, isFalse);
      },
    );

    testWidgets('calls onNext when Next button is pressed', (tester) async {
      final bloc = _buildMockSettingsBloc();
      bool called = false;

      await tester.pumpWidget(
        buildSubject(onNext: () => called = true, bloc: bloc),
      );
      await tester.tap(nextButtonFinder);
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
