import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_bloc.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_event.dart';
import 'package:balance/presentation/bloc/onboarding/onboarding_state.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';

class MockAppSettingsBloc extends Mock implements AppSettingsBloc {}

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockAppSettingsBloc appSettingsBloc;
  late MockWeightBloc weightBloc;

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
  });
}
