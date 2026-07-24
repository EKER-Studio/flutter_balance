import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';

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

  testWidgets('Dashboard renders height config and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(App(repository: repository));
    // Let the BlocProvider's create method and streams settle
    await tester.pump();
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    // Verify UI state
    expect(find.text('PureWeight'), findsOneWidget);
    expect(find.text('Set Your Height'), findsOneWidget);
    expect(
      find.text('Brak wpisów. Dodaj swój pierwszy pomiar poniżej!'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
