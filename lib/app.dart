import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pure_weight/features/weight/domain/repositories/weight_repository.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_bloc.dart';
import 'package:pure_weight/features/weight/presentation/bloc/weight_event.dart';
import 'package:pure_weight/features/weight/presentation/screens/weight_dashboard_screen.dart';
import 'package:pure_weight/l10n/app_localizations.dart';

/// Root widget of the PureWeight application.
class App extends StatelessWidget {
  /// The [WeightRepository] backing the application.
  final WeightRepository repository;

  /// Creates an [App] with the given [repository].
  const App({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (context) =>
            WeightBloc(repository: context.read<WeightRepository>())
              ..add(const SubscribeToWeightChanges()),
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
      ),
    );
  }
}
