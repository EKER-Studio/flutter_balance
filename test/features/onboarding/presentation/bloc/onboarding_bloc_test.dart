import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockAppSettingsBloc appSettingsBloc;
  late MockWeightBloc weightBloc;

  setUpAll(() {
    registerFallbackValue(const SubscribeToWeightChanges());
  });

  setUp(() {
    appSettingsBloc = MockAppSettingsBloc();
    weightBloc = MockWeightBloc();
  });

  OnboardingBloc buildBloc({int totalSteps = 6}) {
    return OnboardingBloc(
      appSettingsBloc: appSettingsBloc,
      weightBloc: weightBloc,
      totalSteps: totalSteps,
    );
  }

  group('OnboardingBloc', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingHealthSyncToggled(true) sets the isHealthSyncRequested flag',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingHealthSyncToggled(true)),
      expect: () => [const OnboardingState(isHealthSyncRequested: true)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingHealthSyncToggled(false) clears the isHealthSyncRequested flag',
      build: buildBloc,
      seed: () => const OnboardingState(isHealthSyncRequested: true),
      act: (bloc) => bloc.add(const OnboardingHealthSyncToggled(false)),
      expect: () => [const OnboardingState(isHealthSyncRequested: false)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepAdvanced advances from step 0 to step 1',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStepAdvanced()),
      expect: () => [const OnboardingState(currentStepIndex: 1)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepAdvanced is a no-op on the final step',
      build: () => buildBloc(totalSteps: 6),
      seed: () => const OnboardingState(currentStepIndex: 5),
      act: (bloc) => bloc.add(const OnboardingStepAdvanced()),
      expect: () => [],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepRewound goes back from step 1 to step 0',
      build: buildBloc,
      seed: () => const OnboardingState(currentStepIndex: 1),
      act: (bloc) => bloc.add(const OnboardingStepRewound()),
      expect: () => [const OnboardingState(currentStepIndex: 0)],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingStepRewound is a no-op on the first step',
      build: buildBloc,
      act: (bloc) => bloc.add(const OnboardingStepRewound()),
      expect: () => [],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingCompleted imports CSV history except the latest entry',
      build: () {
        when(() => appSettingsBloc.state).thenReturn(AppSettingsState());
        return buildBloc();
      },
      seed: () {
        final first = WeightEntry(
          id: 1,
          weightKg: 77,
          dateTime: DateTime(2025, 1, 1),
        );
        final latest = WeightEntry(
          id: 2,
          weightKg: 76.5,
          dateTime: DateTime(2025, 2, 1),
        );
        return OnboardingState(importedCsvEntries: [first, latest]);
      },
      act: (bloc) => bloc.add(const OnboardingCompleted()),
      verify: (_) {
        final captured = verify(
          () => weightBloc.add(captureAny()),
        ).captured.single;
        expect(captured, isA<ImportWeightEntries>());
        final imported = (captured as ImportWeightEntries).entries;
        expect(imported.length, 1);
        expect(imported.single.id, 1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingCompleted enables health sync when requested and not '
      'yet persisted',
      build: () {
        when(
          () => appSettingsBloc.state,
        ).thenReturn(const AppSettingsState(isHealthSyncEnabled: false));
        return buildBloc();
      },
      seed: () => const OnboardingState(isHealthSyncRequested: true),
      act: (bloc) => bloc.add(const OnboardingCompleted()),
      verify: (_) {
        verify(
          () => appSettingsBloc.add(const ToggleHealthSync(true)),
        ).called(1);
      },
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'OnboardingCompleted enables the biometric lock when requested and '
      'not yet persisted',
      build: () {
        when(
          () => appSettingsBloc.state,
        ).thenReturn(const AppSettingsState(isBiometricLockEnabled: false));
        return buildBloc();
      },
      seed: () => const OnboardingState(isBiometricEnabled: true),
      act: (bloc) => bloc.add(const OnboardingCompleted()),
      verify: (_) {
        verify(
          () => appSettingsBloc.add(const UpdateBiometricLock(true)),
        ).called(1);
      },
    );
  });
}
