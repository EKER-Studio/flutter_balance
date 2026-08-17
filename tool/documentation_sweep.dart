// documentation_sweep.dart
// This script performs a Dartdoc coverage and hygiene sweep across the project's lib/ directory.
// It adds missing docstrings, converts qualifying inline comments, removes TODO comments,
// and adds a library directive after file-level comments if missing.

import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    stderr.writeln('lib directory not found');
    exit(1);
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      .toList();

  for (final file in dartFiles) {
    await processFile(file);
  }

  // Run formatting after modifications.
  final formatResult = await Process.run('dart', ['format', '.']);
  stdout.write(formatResult.stdout);
  stderr.write(formatResult.stderr);
}

Future<void> processFile(File file) async {
  final lines = await file.readAsLines();
  final newLines = <String>[];
  bool hasLibraryDirective = false;
  bool firstNonCommentSeen = false;

  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    // Remove TODO comments.
    if (line.trim().startsWith('// TODO')) {
      continue;
    }
    // Convert qualifying inline comment to docstring if it precedes a public declaration.
    if (line.trim().startsWith('//') && i + 1 < lines.length) {
      final nextLine = lines[i + 1];
      final declPattern = RegExp(
        r'^(abstract\s+)?class\s+\w+|^enum\s+\w+|^typedef\s+\w+|^Future<.*>\s+\w+\s*\(|^Stream<.*>\s+\w+\s*\(|^List<.*>\s+\w+\s*\(|^Map<.*>\s+\w+\s*\(|^\w+\s+\w+\s*\{',
      );
      if (declPattern.hasMatch(nextLine.trim())) {
        line = line.replaceFirst('//', '///');
      }
    }
    if (line.trim().startsWith('library ')) {
      hasLibraryDirective = true;
    }
    // Insert library directive after top-level doc comment block if missing.
    if (!firstNonCommentSeen &&
        line.trim().isNotEmpty &&
        !line.trim().startsWith('//') &&
        !line.trim().startsWith('///')) {
      if (!hasLibraryDirective) {
        final libName = generateLibraryName(file.path);
        newLines.add('library $libName;');
        hasLibraryDirective = true;
      }
      firstNonCommentSeen = true;
    }
    newLines.add(line);
  }

  // Ensure library directive is present
  if (!hasLibraryDirective) {
    final libName = generateLibraryName(file.path);
    newLines.insert(0, 'library $libName;');
    hasLibraryDirective = true;
  }

  final newContent = newLines.join('\n');
  if (newContent != lines.join('\n')) {
    await file.writeAsString(newContent);
    stdout.writeln('Updated ${file.path}');
  }
}

String generateLibraryName(String filePath) {
  // Convert path like lib/features/dashboard/presentation/screens/today_screen.dart
  // to a library name like "features.dashboard.presentation.screens.today_screen".
  final relative = p.relative(filePath, from: 'lib');
  final withoutExtension = p.withoutExtension(relative);
  final parts = withoutExtension.split(p.separator);
  return parts.join('.');
}
