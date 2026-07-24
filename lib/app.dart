import 'package:flutter/material.dart';

/// Root widget of the PureWeight application.
class App extends StatelessWidget {
  /// Creates an [App].
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureWeight',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('PureWeight MVP'))),
    );
  }
}
