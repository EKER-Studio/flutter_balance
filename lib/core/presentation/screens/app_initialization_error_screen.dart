
import 'package:flutter/material.dart';
import 'package:balance/l10n/app_localizations.dart';
import 'package:balance/core/presentation/theme/app_theme.dart';

/// Fallback UI shown when app startup initialization fails.
///
/// A stateless widget rendered as fallback content when app initialization (DB, storage, etc.) fails.
///
/// Designed with high-contrast Material 3 semantics and full accessibility
/// (a11y) support so users on TalkBack/VoiceOver are informed of initialization
/// failures and can retry without getting stuck on a native splash screen.
///
/// Renders inside an existing MaterialApp and resolves colors and text styles
/// from the ambient Theme, so it can be embedded anywhere without owning its
//// own Navigator, localization, or overlay scope.
class AppInitializationErrorContent extends StatelessWidget {
  /// Error details for diagnostic display.
  final Object error;

  /// Callback executed when the user taps the retry button.
  final VoidCallback onRetry;

  /// Creates an [AppInitializationErrorContent].
  const AppInitializationErrorContent({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              container: true,
              label: l10n.initErrorSemantics,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.initErrorTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.initErrorSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    button: true,
                    label: l10n.initErrorRetryLabel,
                    hint: l10n.initErrorRetryHint,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.retryStartup),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A root-level wrapper widget rendering [AppInitializationErrorContent] inside its own
/// MaterialApp.
///
/// Only needed when the app itself could not be constructed (see `main.dart`);
/// when embedded in an existing MaterialApp use [AppInitializationErrorContent]
//// directly instead.
class AppInitializationErrorScreen extends StatelessWidget {
  /// Error details for diagnostic display.
  final Object error;

  /// Callback executed when the user taps the retry button.
  final VoidCallback onRetry;

  /// Creates an [AppInitializationErrorScreen].
  const AppInitializationErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppInitializationErrorContent(error: error, onRetry: onRetry),
    );
  }
}
