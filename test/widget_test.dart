import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';

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
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: settingsBloc),
            BlocProvider(
              create: (context) =>
                  WeightBloc(repository: repository)
                    ..add(const SubscribeToWeightChanges()),
            ),
          ],
          child: App(repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 4'), findsOneWidget);
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
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsBloc),
          BlocProvider(
            create: (context) =>
                WeightBloc(repository: repository)
                  ..add(const SubscribeToWeightChanges()),
          ),
        ],
        child: App(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    settingsBloc.close();
  });
}
