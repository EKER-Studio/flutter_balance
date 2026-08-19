import 'package:flutter/material.dart';
import 'package:balance/features/weight/domain/weight_error_type.dart';
import 'package:balance/features/weight/presentation/utils/weight_error_localizer.dart';
import 'package:balance/l10n/app_localizations.dart';

/// An inline banner shown above the card stack when the current state carries an error.
class InlineErrorBanner extends StatelessWidget {
  /// The typed error to surface to the user.
  final WeightErrorType errorType;

  /// An optional callback invoked when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Creates an [InlineErrorBanner] widget.
  const InlineErrorBanner({
    super.key,
    required this.errorType,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final errorText = errorType.localizedMessage(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}
