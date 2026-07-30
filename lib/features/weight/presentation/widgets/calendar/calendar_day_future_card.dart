import 'package:flutter/material.dart';

/// Reusable Material 3 card displayed when a user selects a date in the future.
class CalendarDayFutureCard extends StatelessWidget {
  /// The future date selected by the user.
  final DateTime selectedDate;

  /// Callback executed when the user taps "Przejdź do dzisiaj".
  final VoidCallback onSelectToday;

  /// Creates a [CalendarDayFutureCard] widget.
  const CalendarDayFutureCard({
    super.key,
    required this.selectedDate,
    required this.onSelectToday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(
                Icons.schedule,
                size: 40,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Przyszła data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Ta data jeszcze nie nadeszła. Pomiary wagi rejestruje się dla dni bieżących lub przeszłych.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSelectToday,
              icon: const Icon(Icons.today),
              label: const Text('Przejdź do dzisiaj'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
