import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/app.dart';
import 'package:pure_weight/features/weight/domain/entities/weight_entry.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  late MockWeightRepository repository;
  late MockHydratedStorage storage;
  late WeightBloc bloc;

  setUp(() {
    repository = MockWeightRepository();
    storage = MockHydratedStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    when(
      () => repository.watchAllEntries(),
    ).thenAnswer((_) => Stream.value(<WeightEntry>[]));
    bloc = WeightBloc(repository: repository);
  });

  testWidgets('Dashboard renders height config and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(App(bloc: bloc));
    // Let the post-frame callback dispatch SubscribeToWeightChanges
    await tester.pump();
    // Let the BLoC process the event and react to the stream
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(bloc.state, isA<WeightLoaded>());
    expect((bloc.state as WeightLoaded).heightCm, isNull);
    expect((bloc.state as WeightLoaded).entries, isEmpty);

    expect(find.text('PureWeight'), findsOneWidget);
    expect(find.text('Set Your Height'), findsOneWidget);
    expect(find.text('No entries yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
