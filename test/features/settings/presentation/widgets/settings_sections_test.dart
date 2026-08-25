import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balance/core/models/measurement_unit.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';
import 'package:balance/features/settings/presentation/widgets/sections/application_section.dart';
import 'package:balance/features/settings/presentation/widgets/components/custom_settings_toggle.dart';
import 'package:balance/features/settings/presentation/widgets/sections/data_section.dart';
import 'package:balance/features/settings/presentation/widgets/sections/help_section.dart';
import 'package:balance/features/settings/presentation/widgets/sections/integrations_section.dart';
import 'package:balance/features/settings/presentation/widgets/sections/profile_section.dart';
import 'package:balance/features/settings/presentation/widgets/components/section_header.dart';
import 'package:balance/features/settings/presentation/widgets/sections/security_section.dart';

void main() {
  Future<void> pumpWithL10n(
    WidgetTester tester,
    Widget child, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SectionHeader', () {
    testWidgets('renders the section label', (tester) async {
      await pumpWithL10n(tester, const SectionHeader(label: 'PROFILE'));

      expect(find.text('PROFILE'), findsOneWidget);
    });
  });

  group('ApplicationSection', () {
    testWidgets('renders unit, theme, and reminder tiles', (tester) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ApplicationSection(
            state: const AppSettingsState(),
            l10n: AppLocalizations.of(context),
            onThemeTap: () {},
            onUnitTap: () {},
            onNotificationsChanged: (_) {},
            onNotificationTimeTap: () {},
          ),
        ),
      );

      expect(find.text('Measurement Unit'), findsOneWidget);
      expect(find.text('Metric (kg, cm)'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Daily Reminder'), findsOneWidget);
      // Reminder time tile hidden while notifications are disabled.
      expect(find.text('Reminder Time'), findsNothing);
      expect(find.text('APPLICATION'), findsNothing);
    });

    testWidgets('shows reminder time when notifications are enabled', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ApplicationSection(
            state: const AppSettingsState(
              notificationsEnabled: true,
              notificationTime: (hour: 8, minute: 0),
            ),
            l10n: AppLocalizations.of(context),
            onThemeTap: () {},
            onUnitTap: () {},
            onNotificationsChanged: (_) {},
            onNotificationTimeTap: () {},
          ),
        ),
      );

      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.textContaining('8:00'), findsOneWidget);
    });

    testWidgets('invokes tile callbacks on tap', (tester) async {
      var unitTapped = false;
      var themeTapped = false;
      var timeTapped = false;
      bool? notificationsChanged;

      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ApplicationSection(
            state: const AppSettingsState(
              notificationsEnabled: true,
              notificationTime: (hour: 8, minute: 0),
            ),
            l10n: AppLocalizations.of(context),
            onThemeTap: () => themeTapped = true,
            onUnitTap: () => unitTapped = true,
            onNotificationsChanged: (v) => notificationsChanged = v,
            onNotificationTimeTap: () => timeTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Measurement Unit'));
      await tester.tap(find.text('Theme'));
      await tester.tap(find.byType(Switch));
      await tester.tap(find.text('Reminder Time'));
      await tester.pump();

      expect(unitTapped, isTrue);
      expect(themeTapped, isTrue);
      expect(timeTapped, isTrue);
      // The switch starts ON, so tapping it reports the new value `false`.
      expect(notificationsChanged, isFalse);
    });
  });

  group('DataSection', () {
    testWidgets('renders import, export, and wipe tiles', (tester) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => DataSection(
            l10n: AppLocalizations.of(context),
            onImportTap: () {},
            onExportTap: () {},
            onWipeTap: () {},
          ),
        ),
      );

      expect(find.text('Import data from CSV'), findsOneWidget);
      expect(find.text('Export data to CSV'), findsOneWidget);
      expect(find.text('Wipe All Data'), findsOneWidget);
    });

    testWidgets('invokes callbacks on tap', (tester) async {
      var importTapped = false;
      var exportTapped = false;
      var wipeTapped = false;

      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => DataSection(
            l10n: AppLocalizations.of(context),
            onImportTap: () => importTapped = true,
            onExportTap: () => exportTapped = true,
            onWipeTap: () => wipeTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Import data from CSV'));
      await tester.tap(find.text('Export data to CSV'));
      await tester.tap(find.text('Wipe All Data'));
      await tester.pump();

      expect(importTapped, isTrue);
      expect(exportTapped, isTrue);
      expect(wipeTapped, isTrue);
    });
  });

  group('HelpSection', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'Balance',
        packageName: 'com.example.balance',
        version: '1.2.3',
        buildNumber: '4',
        buildSignature: '',
      );
    });

    testWidgets(
      'renders privacy policy tile and app version from PackageInfo',
      (tester) async {
        await pumpWithL10n(
          tester,
          Builder(
            builder: (context) => HelpSection(
              l10n: AppLocalizations.of(context),
              onPrivacyPolicyTap: () {},
            ),
          ),
        );

        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(find.text('App version'), findsOneWidget);
        expect(find.text('1.2.3'), findsOneWidget);
      },
    );

    testWidgets('invokes the privacy policy callback on tap', (tester) async {
      var tapped = false;

      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => HelpSection(
            l10n: AppLocalizations.of(context),
            onPrivacyPolicyTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Privacy Policy'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('ProfileSection', () {
    testWidgets('renders formatted height and target weight', (tester) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ProfileSection(
            state: const AppSettingsState(height: 175, targetWeight: 80),
            l10n: AppLocalizations.of(context),
            onHeightTap: () {},
            onTargetWeightTap: () {},
          ),
        ),
      );

      expect(find.text('Height'), findsOneWidget);
      expect(find.text('175 cm'), findsOneWidget);
      expect(find.text('Target Weight'), findsOneWidget);
      expect(find.text('80.0 kg'), findsOneWidget);
    });

    testWidgets('renders imperial units for feet and pounds', (tester) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ProfileSection(
            state: const AppSettingsState(
              measurementUnit: MeasurementUnit.imperial,
              height: 180,
              targetWeight: 70,
            ),
            l10n: AppLocalizations.of(context),
            onHeightTap: () {},
            onTargetWeightTap: () {},
          ),
        ),
      );

      expect(find.text("5'11\""), findsOneWidget);
      expect(find.text('154.3 lbs'), findsOneWidget);
    });

    testWidgets('renders not-set labels when values are missing', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ProfileSection(
            state: const AppSettingsState(),
            l10n: AppLocalizations.of(context),
            onHeightTap: () {},
            onTargetWeightTap: () {},
          ),
        ),
      );

      expect(find.text('height not set'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('invokes callbacks on tap', (tester) async {
      var heightTapped = false;
      var targetTapped = false;

      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => ProfileSection(
            state: const AppSettingsState(),
            l10n: AppLocalizations.of(context),
            onHeightTap: () => heightTapped = true,
            onTargetWeightTap: () => targetTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Height'));
      await tester.tap(find.text('Target Weight'));
      await tester.pump();

      expect(heightTapped, isTrue);
      expect(targetTapped, isTrue);
    });
  });

  group('IntegrationsSection', () {
    testWidgets('renders an enabled health sync toggle when the API is '
        'available', (tester) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => IntegrationsSection(
            state: const AppSettingsState(
              isHealthSyncEnabled: true,
              isHealthApiAvailable: true,
            ),
            l10n: AppLocalizations.of(context),
            onHealthSyncChanged: (_) {},
            onInstallHealthConnect: () {},
          ),
        ),
      );

      expect(find.text('Health Connect'), findsOneWidget);
      expect(find.text('Sync weight data with Health Connect'), findsOneWidget);
      final toggle = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(toggle.value, isTrue);
    });

    testWidgets('disables the toggle when the API is unavailable on iOS', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => IntegrationsSection(
            state: const AppSettingsState(isHealthApiAvailable: false),
            l10n: AppLocalizations.of(context),
            onHealthSyncChanged: (_) {},
            onInstallHealthConnect: () {},
          ),
        ),
        platform: TargetPlatform.iOS,
      );

      expect(find.text('Apple Health'), findsOneWidget);
      expect(find.text('Unavailable on this device'), findsOneWidget);
      final toggle = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(toggle.onChanged, isNull);
    });

    testWidgets('renders an install tile on Android when the API is '
        'unavailable', (tester) async {
      var installTapped = false;

      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => IntegrationsSection(
            state: const AppSettingsState(isHealthApiAvailable: false),
            l10n: AppLocalizations.of(context),
            onHealthSyncChanged: (_) {},
            onInstallHealthConnect: () => installTapped = true,
          ),
        ),
        platform: TargetPlatform.android,
      );

      expect(find.text('Unavailable on this device'), findsOneWidget);
      expect(find.byType(CustomSettingsToggle), findsNothing);

      await tester.tap(find.text('Health Connect'));
      await tester.pump();

      expect(installTapped, isTrue);
    });
  });

  group('SecuritySection', () {
    testWidgets('enables the biometric toggle when hardware is available', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => SecuritySection(
            state: const AppSettingsState(isBiometricLockEnabled: true),
            l10n: AppLocalizations.of(context),
            isBiometricAvailable: Future.value(true),
            onBiometricChanged: (_) {},
            biometricsAvailableLabel: 'Use your fingerprint',
            biometricsNotAvailableLabel: 'Not supported',
          ),
        ),
      );

      expect(find.text('Biometric Protection'), findsOneWidget);
      expect(find.text('Use your fingerprint'), findsOneWidget);
      final toggle = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(toggle.value, isTrue);
    });

    testWidgets('disables and untoggles when hardware is unavailable', (
      tester,
    ) async {
      await pumpWithL10n(
        tester,
        Builder(
          builder: (context) => SecuritySection(
            state: const AppSettingsState(isBiometricLockEnabled: true),
            l10n: AppLocalizations.of(context),
            isBiometricAvailable: Future.value(false),
            onBiometricChanged: (_) {},
            biometricsAvailableLabel: 'Use your fingerprint',
            biometricsNotAvailableLabel: 'Not supported',
          ),
        ),
      );

      expect(find.text('Not supported'), findsOneWidget);
      final toggle = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(toggle.value, isFalse);
      expect(toggle.onChanged, isNull);
    });

    testWidgets('keeps the toggle disabled while availability is loading', (
      tester,
    ) async {
      final completer = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => SecuritySection(
                state: const AppSettingsState(),
                l10n: AppLocalizations.of(context),
                isBiometricAvailable: completer.future,
                onBiometricChanged: (_) {},
                biometricsAvailableLabel: 'Use your fingerprint',
                biometricsNotAvailableLabel: 'Not supported',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final toggle = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(toggle.onChanged, isNull);
      expect(find.text('Not supported'), findsOneWidget);

      completer.complete(true);
      await tester.pumpAndSettle();

      final resolved = tester.widget<CustomSettingsToggle>(
        find.byType(CustomSettingsToggle),
      );
      expect(resolved.onChanged, isNotNull);
    });
  });
}
