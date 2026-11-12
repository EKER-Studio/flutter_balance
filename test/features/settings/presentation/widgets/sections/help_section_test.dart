import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/utils/crash_reporter.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/widgets/sections/help_section.dart';

/// Outcome queued for the next `launch` call on [FakeUrlLauncherChannel].
enum LaunchOutcome { succeed, fail, throwException }

/// A sequence-capable mock for the `url_launcher` method channel.
///
/// Each `launch` call pops the next [LaunchOutcome] from the internal queue;
/// once the queue is drained it falls back to [LaunchOutcome.fail]. This lets
/// a single test exercise the multi-step fallback logic (market URL first, web
/// URL second) that [HelpSectionState._rateApp] performs.
class FakeUrlLauncherChannel {
  final Queue<LaunchOutcome> _outcomes = Queue();

  /// Number of `launch` calls received so far.
  int launchCount = 0;

  /// Every URL that was launched, in call order.
  final List<String> launchedUrls = <String>[];

  /// Queues [outcome] for the next `launch` call.
  void queue(LaunchOutcome outcome) => _outcomes.add(outcome);

  /// Handles a single `launch` method call, consuming the next queued outcome.
  Future<Object?> handle(MethodCall call) async {
    expect(call.method, 'launch');
    launchCount++;
    final url = call.arguments['url'] as String?;
    launchedUrls.add(url ?? '');

    final outcome = _outcomes.isEmpty
        ? LaunchOutcome.fail
        : _outcomes.removeFirst();
    switch (outcome) {
      case LaunchOutcome.succeed:
        return true;
      case LaunchOutcome.fail:
        return false;
      case LaunchOutcome.throwException:
        throw PlatformException(code: 'launch_failed');
    }
  }
}

/// The method channel used by the default `url_launcher` platform instance.
const MethodChannel _urlLauncherChannel = MethodChannel(
  'plugins.flutter.io/url_launcher',
);

/// Installs a mock handler for the `url_launcher` method channel.
void _installUrlLauncherMock(FakeUrlLauncherChannel fake) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_urlLauncherChannel, fake.handle);
}

/// Removes any mock handler previously installed for the `url_launcher`
/// method channel.
void _removeUrlLauncherMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_urlLauncherChannel, null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWithL10n(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget buildHelpSection() => Builder(
    builder: (context) => HelpSection(
      l10n: AppLocalizations.of(context),
      onBmiCategoriesTap: () {},
      onPrivacyPolicyTap: () {},
      onLicensesTap: () {},
    ),
  );

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Balance',
      packageName: 'com.example.balance',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
    // The crash path is exercised by the "both fail/throw" branches; keep
    // Firebase disabled so [AppCrashReporter.recordError] only writes to the
    // on-device log (which safely catches MissingPluginException).
    AppCrashReporter.setFirebaseAvailable(false);
  });

  tearDown(() {
    _removeUrlLauncherMock();
  });

  group('HelpSection — Rate Balance', () {
    testWidgets('market launch succeeds and shows no snackbar', (tester) async {
      final fake = FakeUrlLauncherChannel()..queue(LaunchOutcome.succeed);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('Rate Balance'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 1);
      expect(fake.launchedUrls.single, contains('market://details'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'market launch fails, web launch succeeds, and shows no snackbar',
      (tester) async {
        final fake = FakeUrlLauncherChannel()
          ..queue(LaunchOutcome.fail)
          ..queue(LaunchOutcome.succeed);
        _installUrlLauncherMock(fake);

        await pumpWithL10n(tester, buildHelpSection());

        await tester.tap(find.text('Rate Balance'));
        await tester.pumpAndSettle();

        expect(fake.launchCount, 2);
        expect(fake.launchedUrls, anyElement(contains('market://details')));
        expect(fake.launchedUrls, anyElement(contains('play.google.com')));
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets('market and web launches both fail and shows a snackbar', (
      tester,
    ) async {
      final fake = FakeUrlLauncherChannel()
        ..queue(LaunchOutcome.fail)
        ..queue(LaunchOutcome.fail);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('Rate Balance'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 2);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'market launch throws, web launch succeeds, and shows no snackbar',
      (tester) async {
        final fake = FakeUrlLauncherChannel()
          ..queue(LaunchOutcome.throwException)
          ..queue(LaunchOutcome.succeed);
        _installUrlLauncherMock(fake);

        await pumpWithL10n(tester, buildHelpSection());

        await tester.tap(find.text('Rate Balance'));
        await tester.pumpAndSettle();

        expect(fake.launchCount, 2);
        expect(fake.launchedUrls, anyElement(contains('play.google.com')));
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets('market and web launches both throw and shows a snackbar', (
      tester,
    ) async {
      final fake = FakeUrlLauncherChannel()
        ..queue(LaunchOutcome.throwException)
        ..queue(LaunchOutcome.throwException);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('Rate Balance'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 2);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('HelpSection — View on GitHub', () {
    testWidgets('github launch succeeds and shows no snackbar', (tester) async {
      final fake = FakeUrlLauncherChannel()..queue(LaunchOutcome.succeed);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('View on GitHub'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 1);
      expect(fake.launchedUrls.single, contains('github.com'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('github launch fails and shows a snackbar', (tester) async {
      final fake = FakeUrlLauncherChannel()..queue(LaunchOutcome.fail);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('View on GitHub'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 1);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('github launch throws and shows a snackbar', (tester) async {
      final fake = FakeUrlLauncherChannel()
        ..queue(LaunchOutcome.throwException);
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('View on GitHub'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 1);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('HelpSection — App version', () {
    testWidgets('tapping the app version tile does not launch any URL', (
      tester,
    ) async {
      final fake = FakeUrlLauncherChannel();
      _installUrlLauncherMock(fake);

      await pumpWithL10n(tester, buildHelpSection());

      await tester.tap(find.text('App version'));
      await tester.pumpAndSettle();

      expect(fake.launchCount, 0);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
