import 'package:flutter/foundation.dart';
import 'package:balance/l10n/app_localizations.dart';

/// Localized platform-specific labels for the connected health service.
extension HealthServicePlatformX on TargetPlatform {
  /// Returns the display name of the health service for this platform.
  ///
  /// Resolves to Apple Health on iOS, Health Connect on Android, and a
  /// generic health services label on all other platforms.
  String healthServiceName(AppLocalizations l10n) {
    return switch (this) {
      TargetPlatform.iOS => l10n.healthServiceNameIOS,
      TargetPlatform.android => l10n.healthServiceNameAndroid,
      _ => l10n.healthServiceNameOther,
    };
  }

  /// Returns the weight sync description for the health service of this platform.
  ///
  /// Resolves to the service-specific copy on iOS and Android, and to a
  /// generic health apps description on all other platforms.
  String healthServiceSyncDescription(AppLocalizations l10n) {
    return switch (this) {
      TargetPlatform.iOS => l10n.healthSyncDescIOS,
      TargetPlatform.android => l10n.healthSyncDescAndroid,
      _ => l10n.healthSyncDescOther,
    };
  }
}
