import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/features/dashboard/presentation/widgets/components/latest_measurement_info.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('LatestMeasurementInfo', () {
    testWidgets('renders weight, unit label, and vs yesterday in English', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: LatestMeasurementInfo(
            displayWeight: 75.5,
            unitLabel: 'kg',
            deltaFromYesterday: -0.5,
            lastUpdated: DateTime(2026, 6, 15, 8, 30),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('75.5'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('-0.5 kg vs yesterday'), findsOneWidget);
    });

    testWidgets('renders vs yesterday in Polish', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: LatestMeasurementInfo(
            displayWeight: 80.0,
            unitLabel: 'kg',
            deltaFromYesterday: 0.3,
            lastUpdated: DateTime(2026, 6, 15, 8, 30),
          ),
          locale: const Locale('pl'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('80.0'), findsOneWidget);
      expect(find.text('+0.3 kg vs wczoraj'), findsOneWidget);
    });

    testWidgets(
      'renders without delta indicator when deltaFromYesterday is null',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const LatestMeasurementInfo(
              displayWeight: 70.0,
              unitLabel: 'kg',
              deltaFromYesterday: null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('70.0'), findsOneWidget);
        expect(find.textContaining('vs yesterday'), findsNothing);
      },
    );
  });
}
