import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:balance/core/services/health_service.dart';
import 'package:balance/core/services/notification_service.dart';
import 'package:balance/presentation/bloc/settings/app_settings_event.dart';
import 'package:balance/presentation/bloc/settings/app_settings_state.dart';

/// BLoC managing persistent app settings.
///
/// All settings are persisted across app restarts via [HydratedBloc].
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  final NotificationService _notificationService;
  final HealthService _healthService;

  /// Creates an [AppSettingsBloc] initialized with default settings.
  ///
  /// @param notificationService Optional notification service, defaults to the shared instance.
  /// @param healthService Optional health service, defaults to the shared instance.
  AppSettingsBloc({
    NotificationService? notificationService,
    HealthService? healthService,
  }) : _notificationService =
           notificationService ?? NotificationService.instance,
       _healthService = healthService ?? NativeHealthService.instance,
       super(const AppSettingsState()) {
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateMeasurementUnit>(_onUpdateMeasurementUnit);
    on<UpdateHeight>(_onUpdateHeight);
    on<ToggleNotifications>(_onToggleNotifications);
    on<UpdateNotificationTime>(_onUpdateNotificationTime);
    on<TargetWeightChanged>(_onTargetWeightChanged);
    on<UpdateBiometricLock>(_onUpdateBiometricLock);
    on<UpdateBiometricSupport>(_onUpdateBiometricSupport);
    on<SetLocked>(_onSetLocked);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ToggleHealthSync>(_onToggleHealthSync);
    on<CheckHealthSyncStatus>(_onCheckHealthSyncStatus);
    on<ResetAppSettings>(_onResetAppSettings);
  }

  /// Updates the theme mode to [UpdateTheme.themeMode].
  void _onUpdateTheme(UpdateTheme event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  /// Updates the measurement unit to [UpdateMeasurementUnit.measurementUnit].
  void _onUpdateMeasurementUnit(
    UpdateMeasurementUnit event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(measurementUnit: event.measurementUnit));
  }

  /// Updates the user's height to [UpdateHeight.height] centimeters.
  void _onUpdateHeight(UpdateHeight event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(height: event.height));
  }

  /// Enables or disables daily reminder notifications.
  ///
  /// When enabling, requests OS permissions first and only schedules the
  /// reminder when granted; a denied request emits the transient
  /// [AppSettingsState.notificationPermissionDenied] flag instead. When
  /// disabling, cancels the scheduled reminder.
  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<AppSettingsState> emit,
  ) async {
    if (event.enabled) {
      final granted = await _notificationService.requestPermissions();
      emit(
        state.copyWith(
          notificationsEnabled: granted,
          notificationPermissionDenied: !granted,
        ),
      );
      if (granted) {
        await _notificationService.scheduleDailyReminder(
          state.notificationTime,
        );
      }
    } else {
      emit(
        state.copyWith(
          notificationsEnabled: false,
          notificationPermissionDenied: false,
        ),
      );
      await _notificationService.cancelDailyReminder();
    }
  }

  /// Updates the reminder time and re-schedules the daily notification when
  /// notifications are currently enabled.
  Future<void> _onUpdateNotificationTime(
    UpdateNotificationTime event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        notificationTime: event.notificationTime,
        notificationPermissionDenied: false,
      ),
    );
    if (state.notificationsEnabled) {
      await _notificationService.scheduleDailyReminder(event.notificationTime);
    }
  }

  /// Updates the target weight to [TargetWeightChanged.weight] (`null` clears it).
  void _onTargetWeightChanged(
    TargetWeightChanged event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(targetWeight: event.weight));
  }

  /// Updates the biometric lock preference to [UpdateBiometricLock.enabled].
  void _onUpdateBiometricLock(
    UpdateBiometricLock event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isBiometricLockEnabled: event.enabled));
  }

  /// Sets the app-wide locked state to [SetLocked.locked], driving the
  /// biometric shield overlay.
  void _onSetLocked(SetLocked event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(isLocked: event.locked));
  }

  /// Updates whether the device hardware supports biometrics.
  void _onUpdateBiometricSupport(
    UpdateBiometricSupport event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isBiometricSupported: event.isSupported));
  }

  /// Marks the initial onboarding wizard as completed.
  void _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isOnboardingCompleted: true));
  }

  /// Enables or disables health sync (HealthKit / Health Connect).
  ///
  /// When enabling, verifies the OS health API is available and requests
  /// native permissions first; a granted request activates the sync flag, a
  /// denied one emits the transient [AppSettingsState.healthPermissionDenied]
  /// flag instead. When disabling, deactivates the sync flag and clears the
  /// transient denied flag.
  Future<void> _onToggleHealthSync(
    ToggleHealthSync event,
    Emitter<AppSettingsState> emit,
  ) async {
    if (!event.enabled) {
      emit(
        state.copyWith(
          isHealthSyncEnabled: false,
          healthPermissionDenied: false,
        ),
      );
      return;
    }

    final apiAvailable = await _healthService.isHealthApiAvailable();
    if (!apiAvailable) {
      emit(
        state.copyWith(
          isHealthApiAvailable: false,
          healthPermissionDenied: false,
        ),
      );
      return;
    }

    final granted = await _healthService.requestPermissions();
    emit(
      state.copyWith(
        isHealthSyncEnabled: granted,
        isHealthApiAvailable: true,
        healthPermissionDenied: !granted,
      ),
    );
  }

  /// Re-evaluates health API availability and permission grants.
  ///
  /// Runs during app initialization: refreshes [AppSettingsState.isHealthApiAvailable]
  /// and, when the persisted sync flag is set but the native permissions were
  /// revoked in the OS settings, disables and persists the sync flag.
  Future<void> _onCheckHealthSyncStatus(
    CheckHealthSyncStatus event,
    Emitter<AppSettingsState> emit,
  ) async {
    final apiAvailable = await _healthService.isHealthApiAvailable();
    var syncEnabled = state.isHealthSyncEnabled;
    if (syncEnabled) {
      final granted = await _healthService.hasPermissions();
      if (!granted) {
        syncEnabled = false;
      }
    }
    emit(
      state.copyWith(
        isHealthApiAvailable: apiAvailable,
        isHealthSyncEnabled: syncEnabled,
      ),
    );
  }

  /// Resets every setting back to the default [AppSettingsState].
  void _onResetAppSettings(
    ResetAppSettings event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(const AppSettingsState());
  }

  /// Restores the persisted settings from the hydrated JSON map.
  @override
  AppSettingsState? fromJson(Map<String, dynamic> json) {
    return AppSettingsState.fromJson(json);
  }

  /// Serializes the current settings into a JSON map for hydration.
  @override
  Map<String, dynamic> toJson(AppSettingsState state) {
    return state.toJson();
  }
}
