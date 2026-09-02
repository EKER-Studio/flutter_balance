import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/l10n/app_localizations.dart';

/// The in-app splash screen shown during startup initialization.
///
/// Visually mimics the native splash screen and responds to the app's internal
/// theme (dark/light) regardless of the host OS theme.
class AppSplashScreen extends StatefulWidget {
  /// Creates an [AppSplashScreen] displayed while the app initializes.
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.logSplashScreenViewed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF141218) : const Color(0xFFFDF7FF);
    final assetPath = isDark
        ? 'assets/icon/splash_dark.png'
        : 'assets/icon/splash_light.png';

    return Scaffold(
      backgroundColor: bgColor,
      body: Semantics(
        label: AppLocalizations.of(context).appLoadingSemantics,
        textDirection: TextDirection.ltr,
        child: Center(
          child: Image.asset(
            assetPath,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
