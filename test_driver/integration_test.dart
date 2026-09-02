import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Entry point for Flutter Driver with screenshot handling.
Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, dynamic>? args,
        ]) async {
          final file = File('.github/assets/$screenshotName.png');
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(screenshotBytes);
          // ignore: avoid_print
          print(
            '📸 [Screenshot] Saved: ${file.path} (${screenshotBytes.length} bytes)',
          );
          return true;
        },
  );
}
