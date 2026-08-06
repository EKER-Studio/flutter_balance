import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/app.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => Stream.value(<WeightEntry>[]));
  });

  testWidgets(
    'App renders OnboardingWizardScreen when onboarding is not completed',
    (tester) async {
      final settingsBloc = AppSettingsBloc();

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);

      settingsBloc.close();
    },
  );

  testWidgets('App renders MainNavigationScreen when onboarding is completed', (
    tester,
  ) async {
    final settingsBloc = AppSettingsBloc();
    settingsBloc.add(const CompleteOnboarding());

    await tester.pumpWidget(
      BlocProvider<AppSettingsBloc>.value(
        value: settingsBloc,
        child: App(repositoryOverride: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    settingsBloc.close();
  });

  testWidgets(
    'App navigates back to OnboardingWizardScreen when app settings are reset',
    (tester) async {
      final settingsBloc = AppSettingsBloc();

      // 1. Arrange: Start with completed onboarding
      settingsBloc.add(const CompleteOnboarding());

      await tester.pumpWidget(
        BlocProvider<AppSettingsBloc>.value(
          value: settingsBloc,
          child: App(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure we are on the main screen
      expect(find.byType(NavigationBar), findsOneWidget);

      // 2. Act: Reset app settings (simulating "Wipe Data")
      settingsBloc.add(const ResetAppSettings());
      await tester.pumpAndSettle();

      // 3. Assert: Verify we are back on the Onboarding Screen
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Units & Height'), findsOneWidget);

      settingsBloc.close();
    },
  );
}
