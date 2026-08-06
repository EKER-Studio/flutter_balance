@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/l10n/app_localizations.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_state.dart';
import 'package:pure_weight/presentation/screens/settings_screen.dart';

import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightBloc extends Mock implements WeightBloc {}

class FakeLocalAuthPlatform extends LocalAuthPlatform {
  @override
  Future<bool> deviceSupportsBiometrics() async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => const [
    BiometricType.fingerprint,
  ];
}

void main() {
  late MockHydratedStorage storage;
  late MockWeightBloc weightBloc;
  late AppSettingsBloc settingsBloc;

  setUp(() {
    LocalAuthPlatform.instance = FakeLocalAuthPlatform();
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});

    weightBloc = MockWeightBloc();
    when(
      () => weightBloc.state,
    ).thenReturn(const WeightLoaded(entries: [], filteredEntries: []));
    when(() => weightBloc.stream).thenAnswer(
      (_) => Stream.value(const WeightLoaded(entries: [], filteredEntries: [])),
    );

    settingsBloc = AppSettingsBloc();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (call) async => {
        'appName': 'PureWeight',
        'packageName': 'com.example.pure_weight',
        'version': '1.0.0',
        'buildNumber': '1',
      },
    );
  });

  Widget createTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeightBloc>.value(value: weightBloc),
        BlocProvider<AppSettingsBloc>.value(value: settingsBloc),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
  }

  testWidgets('matches golden screenshot in portrait mode', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('1.0.0'), findsOneWidget);

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_portrait.png'),
    );
  });

  testWidgets('matches golden screenshot in landscape mode', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_landscape.png'),
    );
  });
}
