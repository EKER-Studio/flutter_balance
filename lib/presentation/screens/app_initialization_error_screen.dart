import 'package:flutter/material.dart';
import 'package:pure_weight/presentation/theme/app_theme.dart';

/// Fallback screen rendered when app initialization (DB, storage, etc.) fails.
///
/// Designed with high-contrast Material 3 semantics and full accessibility (a11y)
/// support so users on TalkBack/VoiceOver are informed of initialization failures
/// and can retry without getting stuck on a native splash screen.
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
    final mediaQuery = MediaQuery.of(context);
    final brightness = mediaQuery.platformBrightness;
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? AppTheme.darkColorScheme
        : AppTheme.lightColorScheme;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                container: true,
                label:
                    'Initialization Error. App failed to start due to a database or storage error.',
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
                      'Failed to Start PureWeight',
                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'An unexpected error occurred during database setup. Please try restarting the app or tap retry below.',
                      style: AppTheme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Semantics(
                      button: true,
                      label: 'Retry starting the application',
                      hint:
                          'Double tap to attempt re-initializing database and services',
                      child: FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry Startup'),
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
      ),
    );
  }
}
