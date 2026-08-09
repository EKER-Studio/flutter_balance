import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Generate iOS Light and Dark app icons', () async {
    final foregroundFile = File('assets/icon/app_icon_foreground.png');
    expect(
      foregroundFile.existsSync(),
      isTrue,
      reason: 'Missing assets/icon/app_icon_foreground.png',
    );

    final bytes = await foregroundFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final foregroundImage = frame.image;

    // Composites the foreground on a solid background and writes a 1024x1024 PNG.
    Future<void> generateIconWithBackground(
      Color bgColor,
      String outputPath,
    ) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        const ui.Rect.fromLTWH(0, 0, 1024, 1024),
      );

      // 1. Fill the background.
      final bgPaint = ui.Paint()..color = bgColor;
      canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 1024, 1024), bgPaint);

      // 2. Draw the foreground icon centered over it.
      canvas.drawImageRect(
        foregroundImage,
        ui.Rect.fromLTWH(
          0,
          0,
          foregroundImage.width.toDouble(),
          foregroundImage.height.toDouble(),
        ),
        const ui.Rect.fromLTWH(0, 0, 1024, 1024),
        ui.Paint(),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(1024, 1024);
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(pngBytes!.buffer.asUint8List());
      debugPrint('Generated: $outputPath');
    }

    // Standard variant (#4f378a) and dark-mode variant (#000000).
    await generateIconWithBackground(
      const Color(0xFF4F378A),
      'assets/icon/app_icon.png',
    );
    await generateIconWithBackground(
      const Color(0xFF000000),
      'assets/icon/app_icon_dark.png',
    );
  });
}
