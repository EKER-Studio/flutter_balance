import 'package:flutter/widgets.dart';

/// Centralized responsive layout tokens and viewport breakpoints.
abstract final class AppLayoutTokens {
  /// The minimum shortest side dimension (in logical pixels) to consider a device a tablet.
  static const double tabletBreakpoint = 600.0;

  /// The minimum viewport width required to split content into multiple side-by-side columns.
  static const double multiColumnBreakpoint = 720.0;

  /// The standard content width constraint for compact phone viewports.
  static const double compactContentMaxWidth = 480.0;

  /// The standard content width constraint for single-column tablet viewports.
  static const double maxSingleColumnContentWidth = 600.0;

  /// The standard content width constraint for expanded multi-column tablet viewports.
  static const double expandedContentMaxWidth = 1200.0;
}

/// Convenience extensions on [BuildContext] for responsive layout queries.
extension ContextLayout on BuildContext {
  /// Returns `true` when the current viewport shortest side is >= [AppLayoutTokens.tabletBreakpoint].
  bool get isTablet =>
      MediaQuery.sizeOf(this).shortestSide >= AppLayoutTokens.tabletBreakpoint;

  /// Returns `true` when the current viewport width supports multi-column layouts.
  bool get isMultiColumn =>
      MediaQuery.sizeOf(this).width >= AppLayoutTokens.multiColumnBreakpoint;

  /// Returns standard horizontal padding for content areas (24dp on tablets, 16dp on phones).
  double get contentHorizontalPadding => isTablet ? 24.0 : 16.0;

  /// Returns the standard maximum content width based on whether the device is a tablet.
  double get standardContentMaxWidth {
    if (isMultiColumn) {
      return AppLayoutTokens.expandedContentMaxWidth;
    }
    if (isTablet) {
      return AppLayoutTokens.maxSingleColumnContentWidth;
    }
    return AppLayoutTokens.compactContentMaxWidth;
  }
}
