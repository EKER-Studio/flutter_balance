import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/theme/app_layout_tokens.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';
import 'package:balance/core/presentation/widgets/clamped_layout.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/l10n/app_localizations.dart';

const MethodChannel _urlLauncherChannel = MethodChannel(
  'plugins.flutter.io/url_launcher',
);

void main() {
  Widget createTestWidget({Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PrivacyPolicyScreen(),
    );
  }

  testWidgets('renders PrivacyPolicyScreen in English', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('100% Local-First'), findsOneWidget);
    expect(
      find.textContaining('1. Local-First & Zero Account Model'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('contact@ekerstudio.com'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.textContaining('7. Contact Us'), findsOneWidget);
    expect(find.text('contact@ekerstudio.com'), findsOneWidget);
  });

  testWidgets('renders PrivacyPolicyScreen in Polish', (tester) async {
    await tester.pumpWidget(createTestWidget(locale: const Locale('pl')));
    await tester.pumpAndSettle();

    expect(find.text('Polityka prywatności'), findsOneWidget);
    expect(find.text('Balance'), findsOneWidget);
    expect(find.textContaining('100% Local-First'), findsOneWidget);
    expect(
      find.textContaining('1. Architektura Local-First i brak konta'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('contact@ekerstudio.com'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.textContaining('7. Kontakt z nami'), findsOneWidget);
    expect(find.text('contact@ekerstudio.com'), findsOneWidget);
  });

  testWidgets(
    'PrivacyPolicyScreen wraps content with ClampedLayout for tablet & landscape',
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

  group('contact email', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, null);
    });

    Future<void> tapContactButton(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text('contact@ekerstudio.com'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.ensureVisible(find.text('contact@ekerstudio.com'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('contact@ekerstudio.com'));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping the contact button launches a mailto URL', (
      tester,
    ) async {
      final launchedUrls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
            launchedUrls.add(call.arguments['url'] as String);
            return true;
          });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tapContactButton(tester);

      expect(launchedUrls, hasLength(1));
      expect(launchedUrls.single, startsWith('mailto:contact@ekerstudio.com'));
      expect(launchedUrls.single, contains('subject='));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows a snackbar when the email client cannot open', (
      tester,
    ) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_urlLauncherChannel, (call) async => false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tapContactButton(tester);

      expect(
        find.text('Could not open email client for contact@ekerstudio.com'),
        findsOneWidget,
      );
    });

    testWidgets(
      'reports the error and shows a snackbar when launching throws',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
              throw PlatformException(code: 'launch_failed');
            });

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        await tapContactButton(tester);

        expect(
          find.text('Could not open email client for contact@ekerstudio.com'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('uses the dark header surface in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final headerCard = tester.widgetList<Card>(find.byType(Card)).first;
    expect(
      headerCard.color,
      AppTheme.darkColorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    );
  });
}
