import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:balance/features/onboarding/presentation/coordinators/onboarding_completion_coordinator.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';

class MockAppSettingsBloc extends MockBloc<AppSettingsEvent, AppSettingsState>
    implements AppSettingsBloc {}

class MockWeightBloc extends MockBloc<WeightEvent, WeightState>
    implements WeightBloc {}

void main() {
  late MockAppSettingsBloc settingsBloc;
  late MockWeightBloc weightBloc;

  setUpAll(() {
    registerFallbackValue(const CompleteOnboarding());
    registerFallbackValue(const ToggleHealthSync(true));
    registerFallbackValue(const UpdateBiometricLock(true));
    registerFallbackValue(const ImportWeightEntries([]));
  });

  setUp(() {
    settingsBloc = MockAppSettingsBloc();
    weightBloc = MockWeightBloc();

    when(() => settingsBloc.state).thenReturn(const AppSettingsState());
  });

  group('OnboardingCompletionCoordinator', () {
    test(
      'completes onboarding without extra actions for a default clean draft',
      () {
        var completedCalled = false;
        final coordinator = OnboardingCompletionCoordinator(
          settingsBloc: settingsBloc,
          weightBloc: weightBloc,
          onCompleted: () => completedCalled = true,
        );

        coordinator.complete(const OnboardingState());

        verifyNever(() => weightBloc.add(any()));
        verifyNever(() => settingsBloc.add(const ToggleHealthSync(true)));
        verifyNever(() => settingsBloc.add(const UpdateBiometricLock(true)));
        verify(() => settingsBloc.add(const CompleteOnboarding())).called(1);
        expect(completedCalled, isTrue);
      },
    );

    test('dispatches ImportWeightEntries when draft has imported entries', () {
      final entry1 = WeightEntry(
        id: 1,
        weightKg: 75.0,
        dateTime: DateTime(2026, 1, 1),
      );
      final entry2 = WeightEntry(
        id: 2,
        weightKg: 74.5,
        dateTime: DateTime(2026, 1, 2),
      );
      final state = const OnboardingState().copyWith(
        importedCsvEntries: [entry1, entry2],
      );

      final coordinator = OnboardingCompletionCoordinator(
        settingsBloc: settingsBloc,
        weightBloc: weightBloc,
      );

      coordinator.complete(state);

      verify(
        () => weightBloc.add(
          any(
            that: isA<ImportWeightEntries>().having(
              (e) => e.entries,
              'entries',
              equals([entry1]),
            ),
          ),
        ),
      ).called(1);
      verify(() => settingsBloc.add(const CompleteOnboarding())).called(1);
    });

    test('dispatches ToggleHealthSync when health sync is newly requested', () {
      final state = const OnboardingState().copyWith(
        isHealthSyncRequested: true,
      );

      final coordinator = OnboardingCompletionCoordinator(
        settingsBloc: settingsBloc,
        weightBloc: weightBloc,
      );

      coordinator.complete(state);

      verify(() => settingsBloc.add(const ToggleHealthSync(true))).called(1);
      verify(() => settingsBloc.add(const CompleteOnboarding())).called(1);
    });

    test(
      'dispatches UpdateBiometricLock when biometric lock is newly requested',
      () {
        final state = const OnboardingState().copyWith(
          isBiometricEnabled: true,
        );

        final coordinator = OnboardingCompletionCoordinator(
          settingsBloc: settingsBloc,
          weightBloc: weightBloc,
        );

        coordinator.complete(state);

        verify(
          () => settingsBloc.add(const UpdateBiometricLock(true)),
        ).called(1);
        verify(() => settingsBloc.add(const CompleteOnboarding())).called(1);
      },
    );

    test(
      'does not dispatch duplicate enable events if settings already had them enabled',
      () {
        when(() => settingsBloc.state).thenReturn(
          const AppSettingsState(
            isHealthSyncEnabled: true,
            isBiometricLockEnabled: true,
          ),
        );

        final state = const OnboardingState().copyWith(
          isHealthSyncRequested: true,
          isBiometricEnabled: true,
        );

        final coordinator = OnboardingCompletionCoordinator(
          settingsBloc: settingsBloc,
          weightBloc: weightBloc,
        );

        coordinator.complete(state);

        verifyNever(() => settingsBloc.add(const ToggleHealthSync(true)));
        verifyNever(() => settingsBloc.add(const UpdateBiometricLock(true)));
        verify(() => settingsBloc.add(const CompleteOnboarding())).called(1);
      },
    );
  });
}
