import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/widgets/target_weight_sheet.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';

class MockAppSettingsBloc extends MockBloc<AppSettingsEvent, AppSettingsState>
    implements AppSettingsBloc {}

void main() {
  late MockAppSettingsBloc mockSettingsBloc;

  setUp(() {
    mockSettingsBloc = MockAppSettingsBloc();
  });

  Future<dynamic> openDialog(
    WidgetTester tester, {
    double? currentValue,
    MeasurementUnit unit = MeasurementUnit.metric,
  }) async {
    when(() => mockSettingsBloc.state).thenReturn(
      AppSettingsState(targetWeight: currentValue, measurementUnit: unit),
    );

    dynamic result;
    await tester.pumpWidget(
      BlocProvider<AppSettingsBloc>.value(
        value: mockSettingsBloc,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<Object?>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TargetWeightSheet(
                        currentValueKg: currentValue,
                        measurementUnit: unit,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('prefills the field with the current value', (tester) async {
    await openDialog(tester, currentValue: 75.5);

    expect(find.text('Target weight'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '75.5');
    expect(find.text('Weight (kg)'), findsOneWidget);
  });

  testWidgets('uses the lb label in imperial mode', (tester) async {
    await openDialog(tester, unit: MeasurementUnit.imperial);

    expect(find.text('Weight in lb'), findsOneWidget);
  });

  testWidgets('saves a valid metric weight', (tester) async {
    final getResult = await openDialog(tester);

    await tester.enterText(find.byType(TextField), '80,5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(getResult(), 80.5);
  });

  testWidgets('saves a valid imperial weight as entered', (tester) async {
    final getResult = await openDialog(tester, unit: MeasurementUnit.imperial);

    await tester.enterText(find.byType(TextField), '170.0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(getResult(), 170.0);
  });

  testWidgets('clears the target weight when the field is empty', (
    tester,
  ) async {
    final getResult = await openDialog(tester, currentValue: 75.5);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(getResult(), 'clear');
  });

  testWidgets('does not offer a dedicated Remove goal action', (tester) async {
    await openDialog(tester, currentValue: 75.5);

    expect(find.text('Remove goal'), findsNothing);
  });

  testWidgets('clear icon clears the field when text is present', (
    tester,
  ) async {
    await openDialog(tester, currentValue: 75.5);

    expect(find.byIcon(Icons.clear), findsOneWidget);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('shows an error for non-numeric input', (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter a valid positive number.'), findsOneWidget);
    expect(find.byType(TargetWeightSheet), findsOneWidget);
  });

  testWidgets('shows a range error for out-of-range weight', (tester) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '400');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Weight must be between 20 and 300 kg'), findsOneWidget);
  });

  testWidgets('clears the error once the user starts typing again', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Please enter a valid positive number.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '8');
    await tester.pump();
    expect(find.text('Please enter a valid positive number.'), findsNothing);
  });

  testWidgets('cancel button closes the dialog without a result', (
    tester,
  ) async {
    final getResult = await openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(getResult(), isNull);
    expect(find.byType(TargetWeightSheet), findsNothing);
  });

  testWidgets('submitting from the keyboard saves the weight', (tester) async {
    final getResult = await openDialog(tester);

    await tester.enterText(find.byType(TextField), '88.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(getResult(), 88.5);
  });
}
