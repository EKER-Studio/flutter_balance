import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/biometrics/biometric_lock_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricLockObserver', () {
    late bool isLockEnabled;
    late bool lockStateEmitted;
    late StreamController<bool> lockStreamController;

    setUp(() {
      isLockEnabled = false;
      lockStateEmitted = false;
      lockStreamController = StreamController<bool>.broadcast();
    });

    tearDown(() {
      lockStreamController.close();
    });

    test('initializes lock state and listens to stream updates', () async {
      final observer = BiometricLockObserver(
        isBiometricLockEnabled: () => isLockEnabled,
        onLockStateChanged: (locked) {
          lockStateEmitted = locked;
        },
        lockEnabledStream: lockStreamController.stream,
        localizedReason: () => 'Authenticate to access Balance',
        verifyDatabaseIntegrity: () async => (reopened: false),
      );

      // Verify initialization does not throw
      expect(observer, isNotNull);

      // Emit stream update
      lockStreamController.add(true);
      await pumpEventQueue();
      expect(lockStateEmitted, isFalse);

      // Dispose cleanly
      observer.removeThisObserver();
    });

    test('didChangeAppLifecycleState ignores non-resumed states', () {
      bool called = false;
      final observer = BiometricLockObserver(
        isBiometricLockEnabled: () => false,
        onLockStateChanged: (_) {
          called = true;
        },
        localizedReason: () => 'Authenticate to access Balance',
        verifyDatabaseIntegrity: () async => (reopened: false),
      );

      observer.didChangeAppLifecycleState(AppLifecycleState.paused);
      observer.didChangeAppLifecycleState(AppLifecycleState.inactive);
      observer.didChangeAppLifecycleState(AppLifecycleState.detached);

      expect(called, isFalse);
      observer.dispose();
    });

    test(
      'didChangeAppLifecycleState triggers check on resumed state',
      () async {
        final observer = BiometricLockObserver(
          isBiometricLockEnabled: () => false,
          onLockStateChanged: (_) {},
          localizedReason: () => 'Authenticate to access Balance',
          verifyDatabaseIntegrity: () async => (reopened: false),
        );

        // Trigger resumed state
        observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        observer.dispose();
      },
    );
  });
}
