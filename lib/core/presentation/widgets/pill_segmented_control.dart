import 'package:flutter/material.dart';

/// A segment specification for [PillSegmentedControl].
class PillSegment<T> {
  /// The value associated with this segment.
  final T value;

  /// The localized label text displayed within the pill.
  final String label;

  /// An optional widget key for identification in automated tests.
  final Key? key;

  /// An optional semantic label for accessibility tools.
  final String? semanticsLabel;

  /// Creates a [PillSegment].
  ///
  /// [value] is the unique value represented by this segment.
  /// [label] is the text displayed on the segment.
  /// [key] is an optional testing key.
  /// [semanticsLabel] is an optional accessibility label.
  const PillSegment({
    required this.value,
    required this.label,
    this.key,
    this.semanticsLabel,
  });
}

/// A shared, reusable pill-style tab selector widget with smooth animated transitions.
class PillSegmentedControl<T> extends StatelessWidget {
  /// The currently selected segment value.
  final T selectedValue;

  /// The list of segments available in this selector.
  final List<PillSegment<T>> segments;

  /// Callback invoked when a segment is selected.
  final ValueChanged<T> onValueChanged;

  /// Whether segments expand to fill the container's available width.
  final bool expand;

  /// Optional padding for each individual pill segment.
  final EdgeInsetsGeometry itemPadding;

  /// Optional outer margin or padding.
  final EdgeInsetsGeometry outerPadding;

  /// Creates a [PillSegmentedControl].
  ///
  /// [selectedValue] indicates the active segment.
  /// [segments] provides the items displayed in the control.
  /// [onValueChanged] receives updates when the user chooses a segment.
  /// [expand] determines whether segments expand symmetrically.
  /// [itemPadding] configures inner padding for segment pills.
  /// [outerPadding] configures padding around the outer container.
  const PillSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.segments,
    required this.onValueChanged,
    this.expand = true,
    this.itemPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 6.0,
    ),
    this.outerPadding = const EdgeInsets.all(4.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final items = segments.map((segment) {
      final isSelected = selectedValue == segment.value;

      final pill = Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        label: segment.semanticsLabel ?? segment.label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: segment.key,
              borderRadius: BorderRadius.circular(10.0),
              onTap: () => onValueChanged(segment.value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 44.0,
                  minWidth: 48.0,
                ),
                child: Padding(
                  padding: itemPadding,
                  child: Center(
                    child: Text(
                      segment.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      return expand ? Expanded(child: pill) : pill;
    }).toList();

    final container = Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: outerPadding,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: items,
      ),
    );

    return expand ? container : Center(child: container);
  }
}
