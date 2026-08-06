import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/screens/app_initialization_error_screen.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

void main() {
  group('AppInitializationErrorScreen Tests', () {
    testWidgets('renders light mode error UI and handles retry tap', (
      WidgetTester tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.light),
          child: AppInitializationErrorScreen(
            error: Exception('Database lock error'),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Failed to Start PureWeight'), findsOneWidget);
      expect(find.text('Retry Startup'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('Retry Startup'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('renders dark mode error UI cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: AppInitializationErrorScreen(
            error: Exception('Storage write error'),
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Failed to Start PureWeight'), findsOneWidget);
      expect(find.text('Retry Startup'), findsOneWidget);
    });

    testWidgets('verifies accessibility (a11y) semantics tree', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        AppInitializationErrorScreen(
          error: Exception('Access error'),
          onRetry: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Initialization Error')),
        findsOneWidget,
      );

      expect(find.bySemanticsLabel(RegExp(r'Retry Startup')), findsOneWidget);

      handle.dispose();
    });
  });

  group('AppInitializationErrorContent Tests', () {
    testWidgets('renders inside an existing MaterialApp and handles retry', (
      WidgetTester tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppInitializationErrorContent(
            error: Exception('Database lock error'),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Failed to Start PureWeight'), findsOneWidget);
      expect(find.text('Retry Startup'), findsOneWidget);

      await tester.tap(find.text('Retry Startup'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });
}
