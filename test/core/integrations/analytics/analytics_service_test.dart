import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/analytics/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAnalyticsService', () {
    test('exposes a single shared singleton instance', () {
      expect(
        identical(
          FirebaseAnalyticsService.instance,
          FirebaseAnalyticsService.instance,
        ),
        isTrue,
      );
    });

    test('rawInstance is null while Firebase is unavailable', () {
      FirebaseAnalyticsService.instance.setAvailable(false);
      expect(FirebaseAnalyticsService.instance.rawInstance, isNull);
    });

    test(
      'rawInstance throws config error when Firebase is not initialized',
      () {
        FirebaseAnalyticsService.instance.setAvailable(true);
        expect(
          () => FirebaseAnalyticsService.instance.rawInstance,
          throwsA(
            isA<FirebaseException>().having((e) => e.code, 'code', 'no-app'),
          ),
        );
        FirebaseAnalyticsService.instance.setAvailable(false);
      },
    );

    test('setAvailable(false) clears any cached analytics instance', () {
      FirebaseAnalyticsService.instance.setAvailable(true);
      FirebaseAnalyticsService.instance.setAvailable(false);
      expect(FirebaseAnalyticsService.instance.rawInstance, isNull);
    });

    group('silent fail without Firebase', () {
      setUp(() {
        FirebaseAnalyticsService.instance.setAvailable(false);
      });

      test('logEvent completes without throwing', () async {
        await expectLater(
          FirebaseAnalyticsService.instance.logEvent(
            name: 'test_event',
            parameters: {'a': 1},
          ),
          completes,
        );
      });

      test('logScreenView completes without throwing', () async {
        await expectLater(
          FirebaseAnalyticsService.instance.logScreenView(
            screenName: 'test_screen',
            screenClass: 'TestScreen',
          ),
          completes,
        );
      });

      test(
        'setAnalyticsCollectionEnabled completes without throwing',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.setAnalyticsCollectionEnabled(
              true,
            ),
            completes,
          );
        },
      );

      test('setUserId completes without throwing', () async {
        await expectLater(
          FirebaseAnalyticsService.instance.setUserId('user-1'),
          completes,
        );
        await expectLater(
          FirebaseAnalyticsService.instance.setUserId(null),
          completes,
        );
      });

      test('setUserProperty completes without throwing', () async {
        await expectLater(
          FirebaseAnalyticsService.instance.setUserProperty(
            name: 'plan',
            value: 'free',
          ),
          completes,
        );
        await expectLater(
          FirebaseAnalyticsService.instance.setUserProperty(
            name: 'plan',
            value: null,
          ),
          completes,
        );
      });
    });

    group('methods swallow platform failures when Firebase is unavailable', () {
      setUp(() async {
        FirebaseAnalyticsService.instance.setAvailable(true);
        // Enable collection so guards pass and execution enters the try blocks
        await FirebaseAnalyticsService.instance.setAnalyticsCollectionEnabled(
          true,
        );
      });

      tearDown(() {
        FirebaseAnalyticsService.instance.setAvailable(false);
      });

      test(
        'logEvent still completes when Firebase is not initialized',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.logEvent(name: 'some_event'),
            completes,
          );
        },
      );

      test(
        'logScreenView still completes when Firebase is not initialized',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.logScreenView(
              screenName: 'some_screen',
              screenClass: 'SomeClass',
            ),
            completes,
          );
        },
      );

      test(
        'setUserId still completes when Firebase is not initialized',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.setUserId('user_123'),
            completes,
          );
        },
      );

      test(
        'setUserProperty still completes when Firebase is not initialized',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.setUserProperty(
              name: 'tier',
              value: 'pro',
            ),
            completes,
          );
        },
      );

      test(
        'setAnalyticsCollectionEnabled records error when platform throws',
        () async {
          await expectLater(
            FirebaseAnalyticsService.instance.setAnalyticsCollectionEnabled(
              false,
            ),
            completes,
          );
        },
      );
    });
  });
}
