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

  group('MainNavigationScreen Portrait Tests', () {
    testWidgets('renders the shell when constructed non-const', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildNonConstSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Today'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all 4 bottom navigation tabs in portrait', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
      'switches through all 4 tabs in portrait when destinations are selected',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(TodayScreen), findsOneWidget);

        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();
        expect(find.byType(CalendarScreen), findsOneWidget);

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();
        expect(find.byType(StatisticsScreen), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);

        await tester.tap(find.widgetWithText(NavigationDestination, 'Today'));
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
      },
    );

    testWidgets('renders the focus overlay when a destination is focused via '
        'keyboard traversal', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

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

  group('MainNavigationScreen Landscape Tests', () {
    testWidgets('renders NavigationRail and VerticalDivider in landscape', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'switches through all 4 tabs in landscape when rail destinations are selected',
      (tester) async {
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(TodayScreen), findsOneWidget);

        await tester.tap(find.text('Calendar'));
        await tester.pumpAndSettle();
        expect(find.byType(CalendarScreen), findsOneWidget);

        await tester.tap(find.text('Statistics'));
        await tester.pumpAndSettle();
        expect(find.byType(StatisticsScreen), findsOneWidget);

        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);

        await tester.tap(find.text('Today').first);
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
      },
    );

    testWidgets('supports RTL layout in landscape without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiBlocProvider(
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
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: MainNavigationScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'renders without RenderFlex overflow on small landscape viewports (640x320)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 320);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
