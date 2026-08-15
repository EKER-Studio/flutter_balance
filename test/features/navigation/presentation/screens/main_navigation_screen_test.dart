import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';

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

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsBloc()),
        BlocProvider(
          create: (_) =>
              WeightBloc(repository: repository)
                ..add(const SubscribeToWeightChanges()),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainNavigationScreen(),
      ),
    );
  }

  /// Renders the navigation shell with a non-const [MainNavigationScreen] so
  /// the runtime constructor executes (const canonicalization skips it).
  Widget buildNonConstSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AppSettingsBloc()),
        BlocProvider(
          create: (_) =>
              WeightBloc(repository: repository)
                ..add(const SubscribeToWeightChanges()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MainNavigationScreen(key: const ValueKey('non_const_nav')),
      ),
    );
  }

  group('MainNavigationScreen Tests', () {
    testWidgets('renders the shell when constructed non-const', (
      tester,
    ) async {
      await tester.pumpWidget(buildNonConstSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('switches through all 4 tabs when destinations are selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Default active tab is Today
      expect(find.byType(TodayScreen), findsOneWidget);

      // Tap Calendar tab
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsOneWidget);

      // Tap Statistics tab
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);

      // Tap Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Tap Today tab back
      await tester.tap(find.widgetWithText(NavigationDestination, 'Today'));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('renders the focus overlay when a destination is focused via '
        'keyboard traversal', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Move keyboard focus into the navigation bar.
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
