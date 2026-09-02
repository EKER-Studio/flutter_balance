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
  final now = DateTime(2026, 9, 2, 9, 41);
  final entries = <WeightEntry>[];
  for (int i = 0; i < 90; i++) {
    final date = now.subtract(Duration(days: i));
    final base = 92.5 - (92.5 - 87.0) * (89 - i) / 89.0;
    final fluctuation = ((i * 7) % 5 - 2) * 0.1;
    final weight = (i == 0)
        ? 87.0
        : (i == 1)
        ? 87.2
        : double.parse((base + fluctuation).toStringAsFixed(1));
    entries.add(
      WeightEntry(
        id: 90 - i,
        weightKg: weight,
        dateTime: date,
        note: i % 10 == 0 ? 'Morning check' : null,
      ),
    );
  }
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

