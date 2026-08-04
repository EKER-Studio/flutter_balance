import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/presentation/screens/onboarding/widgets/step_biometric_lock.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    settingsBloc = AppSettingsBloc();
  });

  tearDown(() {
    settingsBloc.close();
  });

  Widget buildSubject({required VoidCallback onNext}) {
    return BlocProvider<AppSettingsBloc>.value(
      value: settingsBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StepBiometricLock(onNext: onNext)),
      ),
    );
  }

  group('StepBiometricLock Widget Tests', () {
    testWidgets(
      'renders step title, description, switch, skip and next buttons',
      (tester) async {
        await tester.pumpWidget(buildSubject(onNext: () {}));
        await tester.pumpAndSettle();

        expect(find.text('Biometric Lock'), findsWidgets);
        expect(find.byKey(const Key('biometric_step_switch')), findsOneWidget);
        expect(
          find.byKey(const Key('biometric_step_skip_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('biometric_step_next_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('invokes onNext when skip or next button is pressed', (
      tester,
    ) async {
      int nextCount = 0;
      await tester.pumpWidget(buildSubject(onNext: () => nextCount++));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('biometric_step_skip_button')));
      await tester.pumpAndSettle();
      expect(nextCount, equals(1));

      await tester.tap(find.byKey(const Key('biometric_step_next_button')));
      await tester.pumpAndSettle();
      expect(nextCount, equals(2));
    });
  });
}
