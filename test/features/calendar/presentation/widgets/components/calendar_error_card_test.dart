import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/calendar/presentation/widgets/components/calendar_error_card.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';

class MockWeightBloc extends Mock implements WeightBloc {}

void main() {
  late MockWeightBloc weightBloc;

  setUpAll(() {
    registerFallbackValue(const RefreshWeightData());
  });

  setUp(() {
    weightBloc = MockWeightBloc();
    when(() => weightBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget({required String errorMessage}) {
    return BlocProvider<WeightBloc>.value(
      value: weightBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CalendarErrorCard(errorMessage: errorMessage)),
      ),
    );
  }

  testWidgets('renders the title and the provided error message', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(errorMessage: 'Custom error'));

    expect(find.text('Database read error'), findsOneWidget);
    expect(find.text('Custom error'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('shows the default message when the message is empty', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(errorMessage: ''));

    expect(find.text('Database read error'), findsOneWidget);
    expect(
      find.text(
        'Failed to load weight history from the local database. Please try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('dispatches RefreshWeightData when retry is tapped', (
    tester,
  ) async {
    when(() => weightBloc.add(any())).thenReturn(null);

    await tester.pumpWidget(buildTestWidget(errorMessage: 'Custom error'));

    await tester.tap(find.text('Try again'));
    await tester.pump();

    verify(() => weightBloc.add(const RefreshWeightData())).called(1);
  });
}
