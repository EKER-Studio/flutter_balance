import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:balance/core/presentation/utils/app_snackbar.dart';

void main() {
  Widget buildTestApp({
    required ThemeMode themeMode,
    required SnackBarType type,
    required String message,
    SnackBarAction? action,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AppSnackBar.show(
                  context,
                  message: message,
                  type: type,
                  action: action,
                );
              },
              child: const Text('Show SnackBar'),
            );
          },
        ),
      ),
    );
  }

  group('AppSnackBar Widget Tests', () {
    testWidgets('shows Success SnackBar correctly in Light Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.light,
          type: SnackBarType.success,
          message: 'Success Message',
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFFE7F8ED));

      expect(find.text('Success Message'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_outline_rounded),
      );
      expect(icon.color, const Color(0xFF156F35));
    });

    testWidgets('shows Error SnackBar correctly in Dark Mode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.dark,
          type: SnackBarType.error,
          message: 'Error Message',
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFF2E1517));

      expect(find.text('Error Message'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color, const Color(0xFFF2B8B5));
    });

    testWidgets('shows Warning SnackBar correctly in Light Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.light,
          type: SnackBarType.warning,
          message: 'Warning Message',
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFFFEF7E0));

      final icon = tester.widget<Icon>(
        find.byIcon(Icons.warning_amber_rounded),
      );
      expect(icon.color, const Color(0xFF7D5700));
    });

    testWidgets('shows Info SnackBar correctly in Dark Mode', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          themeMode: ThemeMode.dark,
          type: SnackBarType.info,
          message: 'Info Message',
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, const Color(0xFF121C2B));

      final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline_rounded));
      expect(icon.color, const Color(0xFFA8C7FA));
    });
  });
}
