// Tests for PillSegmentedControl widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/widgets/pill_segmented_control.dart';

void main() {
  Widget buildSubject<T>({
    required T selectedValue,
    required List<PillSegment<T>> segments,
    required ValueChanged<T> onValueChanged,
    bool expand = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PillSegmentedControl<T>(
          selectedValue: selectedValue,
          segments: segments,
          onValueChanged: onValueChanged,
          expand: expand,
        ),
      ),
    );
  }

  testWidgets('renders all segments and reflects selected state', (
    tester,
  ) async {
    String? selected = 'A';
    await tester.pumpWidget(
      buildSubject<String>(
        selectedValue: 'A',
        segments: const [
          PillSegment(value: 'A', label: 'Option A', key: Key('opt_a')),
          PillSegment(value: 'B', label: 'Option B', key: Key('opt_b')),
        ],
        onValueChanged: (val) => selected = val,
      ),
    );

    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);

    await tester.tap(find.byKey(const Key('opt_b')));
    await tester.pumpAndSettle();

    expect(selected, 'B');
  });

  testWidgets('renders in non-expanding centered mode', (tester) async {
    await tester.pumpWidget(
      buildSubject<int>(
        selectedValue: 1,
        segments: const [
          PillSegment(value: 1, label: '1'),
          PillSegment(value: 2, label: '2'),
        ],
        onValueChanged: (_) {},
        expand: false,
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
