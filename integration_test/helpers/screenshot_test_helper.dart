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
  final now = DateTime(2026, 9, 2, 8, 0);
  final entries = <WeightEntry>[];
  for (int i = 89; i >= 0; i--) {
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
}) {
  final effectiveSettingsBloc = settingsBloc ?? AppSettingsBloc();
  final effectiveWeightBloc =
      weightBloc ??
      (WeightBloc(repository: weightRepo)
        ..add(const SubscribeToWeightChanges()));

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
      home: Scaffold(
        appBar: appBar,
        body: SafeArea(child: child),
      ),
    ),
  );
}
