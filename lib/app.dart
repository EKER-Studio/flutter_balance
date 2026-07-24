import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/screens/weight_dashboard_screen.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Root widget of the PureWeight application.
class App extends StatelessWidget {
  /// The [WeightBloc] instance driving the application state.
  final WeightBloc bloc;

  /// Creates an [App] with the given [bloc].
  const App({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        title: 'PureWeight',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WeightDashboardScreen(),
      ),
    );
  }
}
