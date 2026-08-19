import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/dashboard/presentation/widgets/today_shimmer_skeleton.dart';
import 'package:balance/l10n/app_localizations.dart';

/// The in-app splash screen shown during startup initialization.
///
/// A Flutter-based splash screen that visually mimics the native splash screen.
///
/// It is displayed immediately after the Dart VM starts, while the application
/// finishes asynchronous initializations (like database setup).
/// Being a Flutter widget, it correctly responds to the app's internal theme
/// preferences (dark/light) regardless of the host OS theme.
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
    // Scaffold automatically uses Theme.of(context).colorScheme.surface as background.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Semantics(
            label: AppLocalizations.of(context).appLoadingSemantics,
            textDirection: TextDirection.ltr,
            child: const TodayShimmerSkeleton(),
          ),
        ),
      ),
    );
  }
}
