import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/app_theme_mode.dart';
import 'package:balance/features/settings/presentation/widgets/components/theme_selection_dialog.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  group('ThemeSelectionDialog', () {
    testWidgets('renders all theme choices and calls onSelected on choice', (
      tester,
    ) async {
      AppThemeMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ThemeSelectionDialog.show(
                    context,
                    currentMode: AppThemeMode.system,
                    onSelected: (mode) => selectedMode = mode,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(selectedMode, equals(AppThemeMode.dark));
      expect(find.byType(ThemeSelectionDialog), findsNothing);
    });
  });
}
