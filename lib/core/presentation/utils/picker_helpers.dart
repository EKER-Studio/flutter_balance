// Universal helper functions for safe date and time pickers.

import 'package:flutter/material.dart';

/// Displays a platform-safe time picker dialog resilient to landscape layout overflows.
///
/// In landscape mode, forces [TimePickerEntryMode.dialOnly] to prevent keyboard
/// overflow crashes and wraps the content in a [SingleChildScrollView].
Future<TimeOfDay?> showSafeTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  bool alwaysUse24HourFormat = true,
}) {
  final isLandscape =
      MediaQuery.of(context).orientation == Orientation.landscape;

  return showTimePicker(
    context: context,
    initialTime: initialTime,
    initialEntryMode: isLandscape
        ? TimePickerEntryMode.dialOnly
        : TimePickerEntryMode.dial,
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(alwaysUse24HourFormat: alwaysUse24HourFormat),
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 24 : 16,
            vertical: isLandscape ? 8 : 16,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SingleChildScrollView(child: child),
        ),
      );
    },
  );
}

/// Displays a safe date picker dialog with consistent theming and scroll fallback.
Future<DateTime?> showSafeDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      return SingleChildScrollView(child: child);
    },
  );
}
