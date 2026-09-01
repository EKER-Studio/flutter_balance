import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:balance/core/presentation/navigation/app_routes.dart';
import 'package:balance/core/presentation/screens/app_initialization_error_screen.dart';
import 'package:balance/core/presentation/screens/app_splash_screen.dart';
import 'package:balance/core/presentation/screens/biometric_shield_screen.dart';
import 'package:balance/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:balance/features/dashboard/presentation/screens/today_screen.dart';
import 'package:balance/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:balance/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/screens/licenses_screen.dart';
import 'package:balance/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:balance/features/settings/presentation/screens/settings_screen.dart';
import 'package:balance/features/statistics/presentation/screens/statistics_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Creates and configures the application-wide [GoRouter] instance.
///
/// Supports reactive redirection based on [AppSettingsBloc] state (onboarding and biometric lock)
/// and preserves tab navigation state via [StatefulShellRoute.indexedStack].
GoRouter createAppRouter({
  AppSettingsBloc? settingsBloc,
  String initialLocation = AppRoutes.today,
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    observers: observers,
    redirect: (context, state) {
      if (settingsBloc == null) return null;
      final settings = settingsBloc.state;

      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;
      final isGoingToError = state.matchedLocation == AppRoutes.error;
      final isGoingToOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isGoingToShield = state.matchedLocation == AppRoutes.shield;

      if (isGoingToSplash || isGoingToError) return null;

      // 1. First-time user onboarding gate
      if (!settings.isOnboardingCompleted) {
        return isGoingToOnboarding ? null : AppRoutes.onboarding;
      }

      // 2. Biometric shield authentication gate
      if (settings.isLocked) {
        return isGoingToShield ? null : AppRoutes.shield;
      }

      // 3. User is authenticated and onboarding is finished; redirect away from gate screens.
      if (isGoingToOnboarding || isGoingToShield) {
        return AppRoutes.today;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AppSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.error,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final error = state.extra;
          return AppInitializationErrorContent(
            error: error ?? 'Initialization failed',
            onRetry: () => context.go(AppRoutes.splash),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
      GoRoute(
        path: AppRoutes.shield,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BiometricShieldScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.licenses,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LicensesScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) {
                  final action =
                      state.uri.queryParameters[AppRouteParams.action];
                  return TodayScreen(
                    initialAction: action,
                    onNavigateToSettings: () => context.go(AppRoutes.settings),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) {
                  final dateString =
                      state.uri.queryParameters[AppRouteParams.date];
                  DateTime? initialDate;
                  if (dateString != null) {
                    initialDate = DateTime.tryParse(dateString);
                  }
                  return CalendarScreen(initialDate: initialDate);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
