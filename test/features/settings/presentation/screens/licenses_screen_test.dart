import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
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
    ThemeData? theme,
  }) {
    return MaterialApp(
      locale: locale,
      theme: theme,
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

  group('license data', () {
    tearDown(LicenseRegistry.reset);

    test('PackageLicense holds its package name and paragraphs', () {
      final paragraphs = <String>['first text', 'second text'];
      final license = PackageLicense(
        packageName: 'alpha_pkg',
        paragraphs: paragraphs,
      );

      expect(license.packageName, 'alpha_pkg');
      expect(license.paragraphs, same(paragraphs));
    });

    testWidgets('shows a loading spinner while license data resolves', (
      tester,
    ) async {
      LicenseRegistry.addLicense(() async* {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        yield const LicenseEntryWithLineBreaks(<String>['slow_pkg'], 'Slow');
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The loading header omits the version because package info is not part
      // of the resolved snapshot yet.
      expect(find.text('v1.1.0'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('slow_pkg'), findsOneWidget);
    });

    testWidgets('loads package info from the platform when not injected', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'Balance',
        packageName: 'com.ekerstudio.balance',
        version: '2.3.4',
        buildNumber: '99',
        buildSignature: '',
      );
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['platform_pkg'], 'Text'),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LicensesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('v2.3.4'), findsOneWidget);
    });

    testWidgets('renders registered licenses sorted by package name', (
      tester,
    ) async {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['beta_pkg'], 'Beta text'),
        ),
      );
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['Alpha_pkg'], 'Alpha text'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Alpha_pkg'), findsOneWidget);
      expect(find.text('beta_pkg'), findsOneWidget);
      expect(find.text('2 open-source packages'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Alpha_pkg')).dy,
        lessThan(tester.getTopLeft(find.text('beta_pkg')).dy),
      );
    });

    testWidgets('expands a license tile to reveal the full license text', (
      tester,
    ) async {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>[
            'expandable_pkg',
          ], 'First paragraph\n\nSecond paragraph'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsNothing);

      await tester.tap(find.text('expandable_pkg'));
      await tester.pumpAndSettle();

      final selectableText = tester.widget<SelectableText>(
        find.byType(SelectableText),
      );
      expect(selectableText.data, contains('First paragraph'));
      expect(selectableText.data, contains('Second paragraph'));
    });

    testWidgets('labels a package with one license in singular form', (
      tester,
    ) async {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['solo_pkg'], 'Solo text'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1 licencja'), findsOneWidget);
    });

    testWidgets('labels a package with multiple licenses in plural form', (
      tester,
    ) async {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['shared_pkg'], 'First'),
        ),
      );
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          const LicenseEntryWithLineBreaks(<String>['shared_pkg'], 'Second'),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('2 licencje'), findsOneWidget);
    });
  });
}
