import 'package:flutter/widgets.dart';

/// Centralized responsive layout tokens and viewport breakpoints.
abstract final class AppLayoutTokens {
  /// The minimum shortest side dimension (in logical pixels) to consider a device a tablet.
  static const double tabletBreakpoint = 600.0;

  /// The standard content width constraint for compact phone viewports.
  static const double compactContentMaxWidth = 480.0;

  /// The standard content width constraint for expanded tablet viewports.
  static const double expandedContentMaxWidth = 1200.0;
}

/// Convenience extensions on [BuildContext] for responsive layout queries.
extension ContextLayout on BuildContext {
  /// Returns `true` when the current viewport shortest side is >= [AppLayoutTokens.tabletBreakpoint].
  bool get isTablet =>
      MediaQuery.sizeOf(this).shortestSide >= AppLayoutTokens.tabletBreakpoint;

  /// Returns the standard maximum content width based on whether the device is a tablet.
  double get standardContentMaxWidth => isTablet
      ? AppLayoutTokens.expandedContentMaxWidth
      : AppLayoutTokens.compactContentMaxWidth;
}
