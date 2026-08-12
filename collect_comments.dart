import 'dart:io';

void main() {
  final dir = Directory('.');
  final files = [...Directory('lib').listSync(recursive: true), ...Directory('test').listSync(recursive: true)]
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart') && !f.path.contains('.freezed.dart'));
      
  final commentRegex = RegExp(r'^\s*//\s*(?!\/).*$', multiLine: true);
  
  final comments = <String>[];
  for (final file in files) {
    final content = file.readAsStringSync();
    final matches = commentRegex.allMatches(content);
    for (final match in matches) {
      comments.add('${file.path}: ${match.group(0)?.trim()}');
    }
  }
  
  for (final c in comments) {
    print(c);
  }
}
