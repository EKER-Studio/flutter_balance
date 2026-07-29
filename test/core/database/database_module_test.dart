import 'package:flutter_test/flutter_test.dart';
import 'package:pure_weight/core/database/database_module.dart';

void main() {
  group('DatabaseModule', () {
    test('dbName is versioned correctly', () {
      expect(DatabaseModule.dbName, 'pure_weight_v1');
    });
  });
}
