import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:balance/core/di/injection.dart';
import 'package:balance/core/integrations/biometrics/biometric_service.dart';
import 'package:balance/core/integrations/csv/csv_import_service.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_bloc.dart';
import 'package:balance/features/weight/domain/repositories/weight_repository.dart';
import 'package:balance/features/weight/presentation/bloc/weight_bloc.dart';

class MockHydratedStorage extends Mock implements HydratedStorage {}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockHealthService extends Mock implements HealthService {}

void main() {
  late MockHydratedStorage storage;

  setUp(() async {
    storage = MockHydratedStorage();
    HydratedBloc.storage = storage;
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any())).thenAnswer((_) async {});
    when(() => storage.delete(any())).thenAnswer((_) async {});

    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('GetIt Dependency Injection Container', () {
    test('allows registering and resolving mock dependencies for tests', () {
      final mockRepo = MockWeightRepository();
      final mockHealth = MockHealthService();

      getIt.registerLazySingleton<WeightRepository>(() => mockRepo);
      getIt.registerLazySingleton<HealthService>(() => mockHealth);
      getIt.registerLazySingleton<BiometricService>(
        () => BiometricService.instance,
      );
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationService.instance,
      );
      getIt.registerLazySingleton<CsvImportService>(() => CsvImportService());

      expect(getIt<WeightRepository>(), same(mockRepo));
      expect(getIt<HealthService>(), same(mockHealth));
      expect(getIt<BiometricService>(), same(BiometricService.instance));
      expect(getIt<NotificationService>(), same(NotificationService.instance));
      expect(getIt<CsvImportService>(), isA<CsvImportService>());
    });

    test('resolves singleton vs factory lifetimes correctly', () {
      final mockRepo = MockWeightRepository();
      final mockHealth = MockHealthService();

      getIt.registerLazySingleton<WeightRepository>(() => mockRepo);
      getIt.registerLazySingleton<HealthService>(() => mockHealth);
      getIt.registerLazySingleton<NotificationService>(
        () => NotificationService.instance,
      );
      getIt.registerLazySingleton<AppSettingsBloc>(
        () => AppSettingsBloc(
          notificationService: getIt<NotificationService>(),
          healthService: getIt<HealthService>(),
        ),
      );
      getIt.registerFactory<WeightBloc>(
        () => WeightBloc(
          repository: getIt<WeightRepository>(),
          appSettingsBloc: getIt<AppSettingsBloc>(),
          healthService: getIt<HealthService>(),
        ),
      );

      final settingsBloc1 = getIt<AppSettingsBloc>();
      final settingsBloc2 = getIt<AppSettingsBloc>();
      expect(settingsBloc1, same(settingsBloc2));

      final weightBloc1 = getIt<WeightBloc>();
      final weightBloc2 = getIt<WeightBloc>();
      expect(weightBloc1, isNot(same(weightBloc2)));
    });
  });
}
