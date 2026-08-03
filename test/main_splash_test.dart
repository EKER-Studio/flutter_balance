import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_test/flutter_test.dart';




void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterNativeSplash Integration Tests', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_native_splash'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );
    });


    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_native_splash'),
        null,
      );
    });

    testWidgets(
        'FlutterNativeSplash.preserve and remove execute without error',
        (WidgetTester tester) async {
      final widgetsBinding = tester.binding;

      // Preserve holds the first frame
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Remove allows the first frame to render
      FlutterNativeSplash.remove();

      await tester.pumpWidget(const SizedBox());
      expect(find.byType(SizedBox), findsOneWidget);
    });





  });
}
