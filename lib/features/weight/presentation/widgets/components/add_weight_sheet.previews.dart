import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widget_previews.dart';
import 'package:balance/dev/preview/fixtures/dashboard_preview_fixtures.dart';
import 'package:balance/dev/preview/preview_support.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_state.dart';
import 'package:balance/features/weight/presentation/widgets/components/add_weight_sheet.dart';

/// Shows the blank add-weight modal in a phone-sized viewport.
@Preview(
  name: 'Add Weight - Empty',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget addWeightSheetEmptyPreview() => _addWeightSheetPreview();

/// Shows the add-weight modal adjusted for an open software keyboard.
@Preview(
  name: 'Add Weight - Keyboard',
  group: 'Balance Components',
  size: Size(430, 932),
  brightness: Brightness.light,
  wrapper: lightPreviewWrapper,
)
Widget addWeightSheetKeyboardPreview() =>
    _addWeightSheetPreview(keyboardInset: 300);

Widget _addWeightSheetPreview({double keyboardInset = 0}) =>
    withDashboardPreviewBlocs(
      settingsState: dashboardPreviewSettingsState,
      weightState: const WeightLoaded(entries: [], filteredEntries: []),
      child: _AddWeightSheetPreviewHost(keyboardInset: keyboardInset),
    );

class _AddWeightSheetPreviewHost extends StatefulWidget {
  final double keyboardInset;

  const _AddWeightSheetPreviewHost({required this.keyboardInset});

  @override
  State<_AddWeightSheetPreviewHost> createState() =>
      _AddWeightSheetPreviewHostState();
}

class _AddWeightSheetPreviewHostState
    extends State<_AddWeightSheetPreviewHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settingsBloc = context.read<AppSettingsBloc>();
      final weightBloc = context.read<WeightBloc>();

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => MediaQuery(
          data: MediaQuery.of(
            sheetContext,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: widget.keyboardInset)),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
              BlocProvider<WeightBloc>.value(value: weightBloc),
            ],
            child: const AddWeightSheet(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
