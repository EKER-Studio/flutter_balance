import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/models/time_period.dart';
import 'package:balance/core/presentation/navigation/app_router.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/screens/licenses_screen.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockAppSettingsBloc mockSettingsBloc;
  late MockWeightBloc mockWeightBloc;

  setUp(() {
    mockSettingsBloc = MockAppSettingsBloc();
    mockWeightBloc = MockWeightBloc();
    when(() => mockSettingsBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockWeightBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockWeightBloc.state).thenReturn(WeightInitial());
  });

  Widget buildTestableApp(GoRouter router) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<WeightBloc>.value(value: mockWeightBloc),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('AppRouter integration tests', () {
    testWidgets(
      'routes to OnboardingWizardScreen when onboarding is incomplete',
      (tester) async {
        when(
          () => mockSettingsBloc.state,
        ).thenReturn(const AppSettingsState(isOnboardingCompleted: false));

        final router = createAppRouter(
          settingsBloc: mockSettingsBloc,
          initialLocation: AppRoutes.today,
        );

        await tester.pumpWidget(buildTestableApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingWizardScreen), findsOneWidget);
      },
    );

    testWidgets('routes to BiometricShieldScreen when app is locked', (
      tester,
    ) async {
      when(() => mockSettingsBloc.state).thenReturn(
        const AppSettingsState(isOnboardingCompleted: true, isLocked: true),
      );

      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.today,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(BiometricShieldScreen), findsOneWidget);
    });
  });

  group('AppRouter route builders', () {
    setUp(() {
      when(
        () => mockSettingsBloc.state,
      ).thenReturn(const AppSettingsState(isOnboardingCompleted: true));
      when(() => mockWeightBloc.state).thenReturn(
        WeightLoaded(
          entries: const [],
          filteredEntries: const [],
          timePeriod: TimePeriod.month,
          heightCm: null,
        ),
      );
    });

    testWidgets('renders the splash screen route', (tester) async {
      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.splash,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(AppSplashScreen), findsOneWidget);
    });

    testWidgets('renders the privacy policy route', (tester) async {
      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.privacyPolicy,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    });

    testWidgets('renders the licenses route', (tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Balance',
        packageName: 'com.ekerstudio.balance',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.licenses,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(LicensesScreen), findsOneWidget);
    });

    testWidgets('calendar route parses the date query parameter', (
      tester,
    ) async {
      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation:
            '${AppRoutes.calendar}?${AppRouteParams.date}=2026-08-15',
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      final screen = tester.widget<CalendarScreen>(find.byType(CalendarScreen));
      expect(screen.initialDate, DateTime(2026, 8, 15));
    });

    testWidgets('renders the statistics route', (tester) async {
      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.statistics,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('renders the settings route', (tester) async {
      final router = createAppRouter(
        settingsBloc: mockSettingsBloc,
        initialLocation: AppRoutes.settings,
      );

      await tester.pumpWidget(buildTestableApp(router));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
