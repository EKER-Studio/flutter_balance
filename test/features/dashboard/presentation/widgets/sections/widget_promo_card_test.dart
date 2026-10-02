import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/features/dashboard/presentation/widgets/sections/widget_promo_card.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/l10n/app_localizations.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const widgetChannel = MethodChannel('home_widget');

  late MockHydratedStorage storage;
  late AppSettingsBloc settingsBloc;
  late List<String> pinRequests;
  bool pinSupported = true;
  List<Map<String, dynamic>> installedWidgets = const [];

  setUp(() {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    settingsBloc = AppSettingsBloc();
    pinRequests = [];
    pinSupported = true;
    installedWidgets = const [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
          switch (call.method) {
            case 'isRequestPinWidgetSupported':
              return pinSupported;
            case 'getInstalledWidgets':
              return installedWidgets;
            case 'requestPinWidget':
              final args = (call.arguments as Map).cast<String, dynamic>();
              pinRequests.add(args['android'] as String? ?? '');
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
    settingsBloc.close();
  });

  Widget buildSubject() {
    return BlocProvider<AppSettingsBloc>.value(
      value: settingsBloc,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WidgetPromoCard()),
      ),
    );
  }

  /// Pumps the card with a faked target platform.
  ///
  /// The platform override is set for the pump only and restored afterwards,
  /// matching the repository convention for platform-dependent tests.
  Future<void> pumpSubject(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('WidgetPromoCard', () {
    testWidgets('shows the promo when pinning is supported and idle', (
      tester,
    ) async {
      await pumpSubject(tester);

      expect(find.text('Track from your home screen'), findsOneWidget);
      expect(find.text('Add widget'), findsOneWidget);
    });

    testWidgets('stays hidden on non-Android platforms', (tester) async {
      await pumpSubject(tester, platform: TargetPlatform.iOS);

      expect(find.text('Track from your home screen'), findsNothing);
    });

    testWidgets('stays hidden when pin requests are unsupported', (
      tester,
    ) async {
      pinSupported = false;

      await pumpSubject(tester);

      expect(find.text('Track from your home screen'), findsNothing);
    });

    testWidgets('stays hidden when a widget is already pinned', (tester) async {
      installedWidgets = const [<String, dynamic>{}];

      await pumpSubject(tester);

      expect(find.text('Track from your home screen'), findsNothing);
    });

    testWidgets('stays hidden after dismissal', (tester) async {
      settingsBloc.add(const DismissWidgetPromo());
      await pumpSubject(tester);

      expect(find.text('Track from your home screen'), findsNothing);
    });

    testWidgets('requests a widget pin on action tap', (tester) async {
      await pumpSubject(tester);

      await tester.tap(find.text('Add widget'));
      await tester.pumpAndSettle();

      expect(pinRequests, ['BalanceAppWidgetProvider']);
      expect(settingsBloc.state.hasDismissedWidgetPromo, isFalse);
    });

    testWidgets('dismisses the card permanently via the close button', (
      tester,
    ) async {
      await pumpSubject(tester);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(settingsBloc.state.hasDismissedWidgetPromo, isTrue);
      expect(find.text('Track from your home screen'), findsNothing);
    });
  });
}
