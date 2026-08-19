import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/utils/health_service_platform_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10nEn;
  late AppLocalizations l10nPl;

  setUpAll(() async {
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    l10nPl = await AppLocalizations.delegate.load(const Locale('pl'));
  });

  group('HealthServicePlatformX.healthServiceName', () {
    test('resolves iOS service name', () {
      expect(
        TargetPlatform.iOS.healthServiceName(l10nEn),
        equals(l10nEn.healthServiceNameIOS),
      );
      expect(
        TargetPlatform.iOS.healthServiceName(l10nPl),
        equals(l10nPl.healthServiceNameIOS),
      );
    });

    test('resolves Android service name', () {
      expect(
        TargetPlatform.android.healthServiceName(l10nEn),
        equals(l10nEn.healthServiceNameAndroid),
      );
      expect(
        TargetPlatform.android.healthServiceName(l10nPl),
        equals(l10nPl.healthServiceNameAndroid),
      );
    });

    test('resolves fallback for desktop and other platforms', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          platform.healthServiceName(l10nEn),
          equals(l10nEn.healthServiceNameOther),
        );
        expect(
          platform.healthServiceName(l10nPl),
          equals(l10nPl.healthServiceNameOther),
        );
      }
    });
  });

  group('HealthServicePlatformX.healthServiceSyncDescription', () {
    test('resolves iOS sync description', () {
      expect(
        TargetPlatform.iOS.healthServiceSyncDescription(l10nEn),
        equals(l10nEn.healthSyncDescIOS),
      );
      expect(
        TargetPlatform.iOS.healthServiceSyncDescription(l10nPl),
        equals(l10nPl.healthSyncDescIOS),
      );
    });

    test('resolves Android sync description', () {
      expect(
        TargetPlatform.android.healthServiceSyncDescription(l10nEn),
        equals(l10nEn.healthSyncDescAndroid),
      );
      expect(
        TargetPlatform.android.healthServiceSyncDescription(l10nPl),
        equals(l10nPl.healthSyncDescAndroid),
      );
    });

    test('resolves other platform sync description', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          platform.healthServiceSyncDescription(l10nEn),
          equals(l10nEn.healthSyncDescOther),
        );
        expect(
          platform.healthServiceSyncDescription(l10nPl),
          equals(l10nPl.healthSyncDescOther),
        );
      }
    });
  });
}
