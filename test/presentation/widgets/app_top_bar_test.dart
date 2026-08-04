import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/widgets/app_top_bar.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CustomScrollView(slivers: [child])),
    );
  }

  group('AppTopBar', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const AppTopBar(title: 'Dzisiaj')),
      );

      expect(find.text('Dzisiaj'), findsOneWidget);
    });

    testWidgets('renders action items when provided', (tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        createTestWidget(
          AppTopBar(
            title: 'Ustawienia',
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => actionTapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      expect(actionTapped, isTrue);
    });
  });
}
