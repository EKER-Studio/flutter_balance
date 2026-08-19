import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/settings/presentation/bloc/bmi_category.dart';
import 'package:balance/features/weight/presentation/widgets/components/bmi_legend_item.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    BmiCategory category = BmiCategory.normal,
    String range = '18.5 – 24.9',
    bool isDark = false,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: BmiLegendItem(
            category: category,
            range: range,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  group('BmiLegendItem', () {
    testWidgets('renders category label, range, and color swatch in light theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          category: BmiCategory.normal,
          range: '18.5 – 24.9',
          isDark: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('18.5 – 24.9'), findsOneWidget);
      expect(find.byType(MergeSemantics), findsOneWidget);
    });

    testWidgets('renders obese category and handles dark theme styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          category: BmiCategory.obese,
          range: '≥ 30.0',
          isDark: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Obese'), findsOneWidget);
      expect(find.text('≥ 30.0'), findsOneWidget);
    });
  });
}
