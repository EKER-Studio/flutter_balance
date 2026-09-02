import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/entities/weight_entry.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:balance/features/weight/presentation/bloc/weight_event.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class FakeWeightRepository implements WeightRepository {
  final List<WeightEntry> entries;
  FakeWeightRepository(this.entries);

  @override
  Stream<List<WeightEntry>> watchAllEntries() => Stream.value(entries);

  @override
  Future<List<WeightEntry>> getAllEntries() async => entries;

  @override
  Future<void> addEntry(WeightEntry entry) async {}

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Future<int> bulkImportEntries(List<WeightEntry> entries) async =>
      entries.length;

  @override
  Future<int> syncRemoteEntries(List<WeightEntry> remoteEntries) async =>
      remoteEntries.length;

  @override
  Future<void> clearAllData() async {}
}

List<WeightEntry> generate90MockEntries() {
  final entries = <WeightEntry>[];
  int nextId = 1;

  void addEntry(DateTime dt, double weight, [String? note]) {
    entries.add(
      WeightEntry(
        id: nextId++,
        weightKg: weight,
        dateTime: dt,
        note: note,
      ),
    );
  }

  // September 2026 (Today & Yesterday)
  addEntry(DateTime(2026, 9, 2, 9, 41), 87.0, 'Morning check');
  addEntry(DateTime(2026, 9, 1, 9, 41), 87.2);

  // August 2026 - matching exact calendar distribution:
  // Target: 85.0 kg (< 85.0 is green, >= 85.0 is blue)
  // Day 31: 1 green dot
  addEntry(DateTime(2026, 8, 31, 8, 30), 84.3);
  // Day 30: 1 green dot
  addEntry(DateTime(2026, 8, 30, 8, 15), 84.4);
  // Day 29: 1 green dot
  addEntry(DateTime(2026, 8, 29, 8, 20), 84.5);
  // Day 28: 1 green dot
  addEntry(DateTime(2026, 8, 28, 8, 10), 84.6);
  // Day 27: 1 blue dot
  addEntry(DateTime(2026, 8, 27, 8, 30), 85.2);
  // Day 26: 2 green dots
  addEntry(DateTime(2026, 8, 26, 20, 15), 84.3, 'Evening weigh-in');
  addEntry(DateTime(2026, 8, 26, 8, 0), 84.5, 'Morning check');
  // Day 25: >= 4 entries -> dash (blue bar: all >= 85.0 kg)
  addEntry(DateTime(2026, 8, 25, 21, 20), 85.4, 'Evening check');
  addEntry(DateTime(2026, 8, 25, 17, 30), 85.5, 'Post-workout');
  addEntry(DateTime(2026, 8, 25, 12, 45), 85.6, 'After lunch');
  addEntry(DateTime(2026, 8, 25, 8, 15), 85.8, 'Morning check');
  // Day 24: 2 green dots
  addEntry(DateTime(2026, 8, 24, 20, 45), 84.3);
  addEntry(DateTime(2026, 8, 24, 8, 15), 84.5);
  // Day 23: 1 green dot
  addEntry(DateTime(2026, 8, 23, 8, 45), 84.6);
  // Day 22: 2 green dots
  addEntry(DateTime(2026, 8, 22, 19, 30), 84.4);
  addEntry(DateTime(2026, 8, 22, 8, 0), 84.6);
  // Day 21: 1 blue dot
  addEntry(DateTime(2026, 8, 21, 8, 15), 85.3);
  // Day 20: 2 green dots
  addEntry(DateTime(2026, 8, 20, 21, 0), 84.5);
  addEntry(DateTime(2026, 8, 20, 8, 30), 84.7);
  // Day 19: 1 blue dot
  addEntry(DateTime(2026, 8, 19, 8, 20), 85.4);
  // Day 18: 3 green dots
  addEntry(DateTime(2026, 8, 18, 20, 0), 84.5, 'Evening check');
  addEntry(DateTime(2026, 8, 18, 13, 30), 84.6, 'Midday check');
  addEntry(DateTime(2026, 8, 18, 8, 0), 84.8, 'Morning check');
  // Day 17: 1 green dot
  addEntry(DateTime(2026, 8, 17, 8, 30), 84.7);
  // Day 16: 1 green dot
  addEntry(DateTime(2026, 8, 16, 8, 15), 84.8);
  // Day 15: 1 blue dot
  addEntry(DateTime(2026, 8, 15, 8, 45), 85.6);
  // Day 14: 2 green dots
  addEntry(DateTime(2026, 8, 14, 19, 45), 84.6, 'Evening check');
  addEntry(DateTime(2026, 8, 14, 8, 15), 84.8, 'Morning check');
  // Day 13: 2 blue dots
  addEntry(DateTime(2026, 8, 13, 20, 30), 85.7);
  addEntry(DateTime(2026, 8, 13, 8, 0), 85.9);
  // Day 12: 1 blue dot
  addEntry(DateTime(2026, 8, 12, 8, 15), 85.8);
  // Day 11: 1 blue dot
  addEntry(DateTime(2026, 8, 11, 8, 20), 86.1);
  // Day 10: 1 blue dot
  addEntry(DateTime(2026, 8, 10, 8, 10), 86.4);
  // Day 9: 1 blue dot
  addEntry(DateTime(2026, 8, 9, 8, 30), 86.2);
  // Day 8: 1 green dot
  addEntry(DateTime(2026, 8, 8, 8, 15), 84.7);
  // Day 7: 1 green dot
  addEntry(DateTime(2026, 8, 7, 8, 30), 84.8);
  // Day 6: 1 blue dot
  addEntry(DateTime(2026, 8, 6, 8, 15), 86.5);
  // Day 5: 1 blue dot
  addEntry(DateTime(2026, 8, 5, 8, 30), 86.8);
  // Day 4: 1 blue dot
  addEntry(DateTime(2026, 8, 4, 8, 10), 87.1);
  // Day 3: 1 blue dot
  addEntry(DateTime(2026, 8, 3, 8, 20), 87.4);
  // Day 2: 1 blue dot
  addEntry(DateTime(2026, 8, 2, 8, 15), 87.6);
  // Day 1: 1 blue dot
  addEntry(DateTime(2026, 8, 1, 8, 30), 87.8);

  // July & June history (gradual trend from 92.5 kg down to 88.0 kg)
  for (int d = 1; d <= 57; d++) {
    final date = DateTime(2026, 8, 1, 8, 0).subtract(Duration(days: d));
    final base = 88.0 + (92.5 - 88.0) * d / 57.0;
    final fluctuation = ((d * 7) % 5 - 2) * 0.1;
    final weight = double.parse((base + fluctuation).toStringAsFixed(1));
    addEntry(date, weight, d % 10 == 0 ? 'Morning check' : null);
  }

  // Ensure entries are strictly sorted newest first
  entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  return entries;
}

const List<String> supportedScreenshotLocales = <String>[
  'en',
  'de',
  'ja',
  'fr',
  'es',
  'pl',
  'pt',
  'nl',
  'it',
  'ko',
];

String getScreenshotPrefix() {
  const device = String.fromEnvironment(
    'SCREENSHOT_DEVICE',
    defaultValue: 'android/phone',
  );
  return device.isNotEmpty ? '$device/' : '';
}

List<String> getEffectiveLocales() {
  const localeFilter = String.fromEnvironment(
    'SCREENSHOT_LOCALE',
    defaultValue: '',
  );
  if (localeFilter.isNotEmpty &&
      supportedScreenshotLocales.contains(localeFilter)) {
    return [localeFilter];
  }
  return supportedScreenshotLocales;
}

Future<FakeWeightRepository> initScreenshotEnvironment(
  IntegrationTestWidgetsFlutterBinding binding,
) async {
  await binding.convertFlutterSurfaceToImage();
  final storage = MockHydratedStorage();
  HydratedBloc.storage = storage;
  when(() => storage.read(any())).thenReturn(null);
  when(() => storage.write(any(), any())).thenAnswer((_) async {});
  final mockEntries = generate90MockEntries();
  return FakeWeightRepository(mockEntries);
}

Widget buildScreenshotAppWrapper({
  required Widget child,
  required Locale locale,
  required ThemeData theme,
  required ThemeMode themeMode,
  required FakeWeightRepository weightRepo,
  AppSettingsBloc? settingsBloc,
  WeightBloc? weightBloc,
  PreferredSizeWidget? appBar,
  bool includeSystemBars = true,
  bool showNotificationIcon = false,
}) {
  final effectiveSettingsBloc = settingsBloc ?? AppSettingsBloc();
  final effectiveWeightBloc =
      weightBloc ??
      (WeightBloc(repository: weightRepo)
        ..add(const SubscribeToWeightChanges()));

  final isDark = themeMode == ThemeMode.dark;

  final content = Scaffold(
    appBar: appBar,
    body: SafeArea(child: child),
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider<AppSettingsBloc>.value(value: effectiveSettingsBloc),
      BlocProvider<WeightBloc>.value(value: effectiveWeightBloc),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      themeMode: themeMode,
      home: includeSystemBars
          ? ScreenshotDeviceFrame(
              isDark: isDark,
              showNotificationIcon: showNotificationIcon,
              child: content,
            )
          : content,
    ),
  );
}

/// Device frame that emulates a realistic mobile status bar and bottom gesture navigation pill.
class ScreenshotDeviceFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final bool showNotificationIcon;
  final Color? statusBarColor;
  final Color? navigationBarColor;

  const ScreenshotDeviceFrame({
    super.key,
    required this.child,
    required this.isDark,
    this.showNotificationIcon = false,
    this.statusBarColor,
    this.navigationBarColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 36.0, bottom: 20.0),
        viewPadding: const EdgeInsets.only(top: 36.0, bottom: 20.0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // App Content
          child,

          // Mock System Status Bar (Overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 36.0,
            child: IgnorePointer(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  color: statusBarColor ?? Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left side: Time + Notification icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '09:41',
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          if (showNotificationIcon) ...[
                            const SizedBox(width: 6.0),
                            Image.asset(
                              'assets/icon/app_icon_foreground.png',
                              width: 17.0,
                              height: 17.0,
                              color: fgColor.withValues(alpha: 0.9),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ],
                        ],
                      ),
                      // Right side: Signal, Wi-Fi, Horizontal Battery
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            color: fgColor,
                            size: 15.0,
                          ),
                          const SizedBox(width: 6.0),
                          Icon(Icons.wifi, color: fgColor, size: 15.0),
                          const SizedBox(width: 8.0),
                          // Horizontal battery icon
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20.0,
                                height: 10.0,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: fgColor,
                                    width: 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(3.0),
                                ),
                                padding: const EdgeInsets.all(1.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: fgColor,
                                    borderRadius: BorderRadius.circular(1.0),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1.5,
                                height: 4.0,
                                decoration: BoxDecoration(
                                  color: fgColor.withValues(alpha: 0.8),
                                  borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(1.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Mock Bottom Gesture Navigation Bar (Overlay)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 20.0,
            child: IgnorePointer(
              child: Container(
                color: navigationBarColor ?? Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 134.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: fgColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a Material 3 bottom sheet container with proper background color,
/// elevation, and top rounded corners to emulate modal bottom sheets in tests.
class ScreenshotBottomSheetContainer extends StatelessWidget {
  final Widget child;

  const ScreenshotBottomSheetContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 2.0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
