import 'package:flutter/material.dart';
import 'package:balance/core/utils/analytics.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/today_shimmer_skeleton.dart';
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
