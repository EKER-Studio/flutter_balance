import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';

/// A Flutter-based splash screen that visually mimics the native splash screen.
///
/// It is displayed immediately after the Dart VM starts, while the application
/// finishes asynchronous initializations (like database setup).
/// Being a Flutter widget, it correctly responds to the app's internal theme
/// preferences (dark/light) regardless of the host OS theme.
class AppSplashScreen extends StatelessWidget {
  /// Creates an [AppSplashScreen] displayed while the app initializes.
  const AppSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold automatically uses Theme.of(context).colorScheme.surface as background.
    return Scaffold(
      body: Center(
        child: Semantics(
          label: AppLocalizations.of(context).appLoadingSemantics,
          textDirection: TextDirection.ltr,
          child: Image.asset(
            'assets/app_icon.png',
            width: 144,
            height: 144,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
