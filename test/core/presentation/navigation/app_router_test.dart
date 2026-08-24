import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/presentation/navigation/app_router.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
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
    when(() => mockWeightBloc.state).thenReturn(const WeightInitial());
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
}
