import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/features/settings/presentation/screens/licenses_screen.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  final testPackageInfo = PackageInfo(
    appName: 'Balance',
    packageName: 'com.ekerstudio.balance',
    version: '1.1.0',
    buildNumber: '1',
  );

  Widget createTestWidget({
    Locale locale = const Locale('en'),
    PackageInfo? packageInfo,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LicensesScreen(packageInfo: packageInfo ?? testPackageInfo),
    );
  }

  testWidgets('renders LicensesScreen in English', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Open Source Licenses'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('v1.1.0'), findsOneWidget);
    expect(find.text('© 2026 EKER Studio'), findsOneWidget);
    expect(find.text('Powered by Flutter'), findsOneWidget);
  });

  testWidgets('renders LicensesScreen in Polish', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('pl')));
    await tester.pumpAndSettle();

    expect(find.text('Licencje open source'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.text('v1.1.0'), findsOneWidget);
    expect(find.text('© 2026 EKER Studio'), findsOneWidget);
    expect(find.text('Powered by Flutter'), findsOneWidget);
  });

  testWidgets(
    'LicensesScreen wraps content with ClampedLayout for tablet & landscape',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final clampedLayoutFinder = find.byType(ClampedLayout);
      expect(clampedLayoutFinder, findsOneWidget);
      final clampedLayout = tester.widget<ClampedLayout>(clampedLayoutFinder);
      expect(
        clampedLayout.maxWidth,
        AppLayoutTokens.maxSingleColumnContentWidth,
      );
    },
  );

  testWidgets(
    'LicensesScreen renders without overflow on phone landscape viewport',
    (tester) async {
      // Simulate low-height phone landscape: 800x360 px
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      // Pump initial frame (loading state)
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Settle full async license loading
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Balance'), findsOneWidget);
    },
  );
}
