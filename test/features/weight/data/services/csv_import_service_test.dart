import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:balance/features/weight/data/services/csv_import_service.dart';

/// Minimal [PlatformFile] test double backed by a file [Uri].
final class TestPlatformFile extends PlatformFile {
  TestPlatformFile({required this.name, String? path})
    : _uri = path != null ? Uri.file(path) : Uri.parse('about:blank');

  @override
  final String name;

  final Uri _uri;

  @override
  Uri get uri => _uri;

  @override
  XFile get xFile => _uri.scheme == 'file'
      ? XFile(_uri.toFilePath(), name: name)
      : XFile.fromData(Uint8List(0), name: name);

  @override
  int? lengthSync() => null;

  @override
  Future<int?> length() async => null;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  @override
  Stream<Uint8List> readAsByteStream() => const Stream.empty();
}

/// A test double that extends [FilePickerPlatform] so the platform interface
/// token verification in `FilePickerPlatform.instance =` passes.
class FakeFilePickerPlatform extends FilePickerPlatform {
  FakeFilePickerPlatform(this.onPickFiles);

  final Future<List<PlatformFile>> Function({
    required FileType type,
    List<String>? allowedExtensions,
  })
  onPickFiles;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
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
      return Future.value(<PlatformFile>[]);
    });
    FilePickerPlatform.instance = filePicker;
    service = CsvImportService();
    tempDir = Directory.systemTemp.createTempSync('csv_import_service_test');
  });

  tearDown(() {
    FilePickerPlatform.instance = originalPlatform;
    tempDir.deleteSync(recursive: true);
  });

  List<PlatformFile> pickResult(String path) => [
    TestPlatformFile(name: 'weights.csv', path: path),
  ];

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
        return <PlatformFile>[];
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
        ({required type, allowedExtensions}) async => [
          TestPlatformFile(name: 'weights.csv'),
        ],
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

    test('strips a leading UTF-8 BOM before parsing', () async {
      final file = writeCsv(
        '\uFEFFID,Data,Weight (kg),BMI,Note\n'
        '1,2024-01-18 07:30,74.5,22.8,BOM note\n',
      );
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      final result = await service.pickAndImport();

      expect(result, isNotNull);
      expect(result!.validEntries, hasLength(1));
      expect(result.validEntries.single.weightKg, 74.5);
      expect(result.validEntries.single.note, 'BOM note');
    });

    test(
      'decodes files with invalid UTF-8 bytes using allowMalformed',
      () async {
        final file = File('${tempDir.path}/weights.csv');
        file.writeAsBytesSync([
          ...utf8.encode(
            'ID,Data,Weight (kg),BMI,Note\n'
            '1,2024-01-19 07:30,73.9,22.5,Note ',
          ),
          0xFF,
          ...utf8.encode(' end\n'),
        ]);
        filePicker = FakeFilePickerPlatform(
          ({required type, allowedExtensions}) async => pickResult(file.path),
        );
        FilePickerPlatform.instance = filePicker;

        final result = await service.pickAndImport();

        expect(result!.validEntries, hasLength(1));
        expect(result.validEntries.single.note, 'Note \uFFFD end');
      },
    );

    test('allows files exactly at the size limit', () async {
      final file = File('${tempDir.path}/weights.csv');
      file.writeAsBytesSync(List.filled(5 * 1024 * 1024, 0x78));
      filePicker = FakeFilePickerPlatform(
        ({required type, allowedExtensions}) async => pickResult(file.path),
      );
      FilePickerPlatform.instance = filePicker;

      expect(() => service.pickAndImport(), throwsFormatException);
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
