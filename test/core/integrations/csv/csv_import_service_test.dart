import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker/src/platform/file_picker_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';

/// A test double that extends [FilePickerPlatform] so the platform interface
/// token verification in `FilePickerPlatform.instance =` passes.
class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.onPickFiles);

  final Future<FilePickerResult?> Function({
    required FileType type,
    List<String>? allowedExtensions,
  })
  onPickFiles;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
  }) {
    return onPickFiles(type: type, allowedExtensions: allowedExtensions);
  }
}

void main() {
  late FakeFilePickerPlatform filePicker;
  late FilePickerPlatform originalPlatform;
  late CsvImportService service;
  late Directory tempDir;

  setUp(() {
    originalPlatform = FilePickerPlatform.instance;
    filePicker = FakeFilePickerPlatform(({required type, allowedExtensions}) {
      return Future.value(null);
    });
    FilePickerPlatform.instance = filePicker;
    service = CsvImportService();
    tempDir = Directory.systemTemp.createTempSync('csv_import_service_test');
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPlatform;
    tempDir.deleteSync(recursive: true);
  });

  FilePickerResult pickResult(String path) => FilePickerResult([
    PlatformFile(name: 'weights.csv', size: 0, path: path),
  ]);

  File writeCsv(String content) {
    final file = File('${tempDir.path}/weights.csv');
    file.writeAsStringSync(content);
    return file;
  }

  group('CsvImportService.pickAndImport', () {
    test('parses the picked CSV file into weight entries', () async {
      final file = writeCsv(
        'ID,Data,Weight (kg),BMI,Note\n'
        '1,2024-01-15 07:30,75.2,23.1,Morning\n'
        '2,2024-01-16 07:30,75.0,23.0,\n',
      );
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      final result = await service.pickAndImport();

      expect(result, isNotNull);
      expect(result!.validEntries, hasLength(2));
      expect(result.validEntries.first.weightKg, 75.2);
      expect(result.validEntries.first.dateTime, DateTime(2024, 1, 15, 7, 30));
      expect(result.validEntries.first.note, 'Morning');
      expect(result.skippedRowCount, 0);
    });

    test('requests a CSV-filtered file picker', () async {
      FileType? requestedType;
      List<String>? requestedExtensions;
      filePicker = FakeFilePickerPlatform(({
        required type,
        allowedExtensions,
      }) async {
        requestedType = type;
        requestedExtensions = allowedExtensions;
        return null;
      });
      FilePickerPlatform.instance = filePicker;

      final result = await service.pickAndImport();

      expect(result, isNull);
      expect(requestedType, FileType.custom);
      expect(requestedExtensions, ['csv']);
    });

    test('returns null when the picker is cancelled', () async {
      final result = await service.pickAndImport();

      expect(result, isNull);
    });

    test('returns null when the picked file has no path', () async {
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async =>
            FilePickerResult([PlatformFile(name: 'weights.csv', size: 0)]),
      );
      FilePickerPlatform.instance = filePicker;

      final result = await service.pickAndImport();

      expect(result, isNull);
    });

    test('throws FormatException for a CSV without a valid header', () async {
      final file = writeCsv('not,a,valid,header\n1,2,3,4\n');
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      expect(() => service.pickAndImport(), throwsFormatException);
    });

    test('throws FileTooLargeException for files exceeding 5 MB', () async {
      // 5 MB + 1 byte to exceed the limit.
      final bigContent = List.filled(5 * 1024 * 1024 + 1, 'x').join();
      final file = writeCsv(bigContent);
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      expect(
        () => service.pickAndImport(),
        throwsA(
          isA<FileTooLargeException>().having(
            (e) => e.message,
            'message',
            contains('5 MB'),
          ),
        ),
      );
    });

    test('skips invalid rows and returns valid entries', () async {
      final file = writeCsv(
        'ID,Data,Weight (kg),BMI,Note\n'
        '1,not-a-date,75.2,23.1,Invalid date\n'
        '2,2024-01-16 07:30,999.0,23.0,Out of range\n'
        '3,2024-01-17 07:30,74.8,22.9,Valid\n',
      );
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      final result = await service.pickAndImport();

      expect(result!.validEntries, hasLength(1));
      expect(result.validEntries.single.weightKg, 74.8);
      expect(result.skippedRowCount, 2);
    });
  });
}
