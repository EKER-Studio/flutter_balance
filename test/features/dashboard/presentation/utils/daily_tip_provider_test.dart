import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/dashboard/presentation/utils/daily_tip_provider.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  testWidgets('DailyTipProvider returns a localized tip deterministically', (
    tester,
  ) async {
    late DailyTip tip;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            tip = DailyTipProvider.getDailyTip(context);
            return Text(tip.title);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tip.title, isNotEmpty);
    expect(tip.text, isNotEmpty);
    expect(find.text(tip.title), findsOneWidget);
  });
}
