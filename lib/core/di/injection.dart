import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:balance/core/di/injection.config.dart';

/// Global service locator instance for dependency injection.
final GetIt getIt = GetIt.instance;

/// Configures all registered dependencies in the [GetIt] container.
///
/// Supports environment filtering using [environment] (e.g. [Environment.dev],
/// [Environment.prod], or [Environment.test]).
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String? environment}) async =>
    getIt.init(environment: environment);
