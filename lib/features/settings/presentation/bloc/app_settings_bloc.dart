import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:balance/core/integrations/health/health_service.dart';
import 'package:balance/core/integrations/notifications/notification_service.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_event.dart';
import 'package:balance/features/settings/presentation/bloc/app_settings_state.dart';

/// A BLoC responsible for managing persistent app settings.
///
/// All settings are persisted across app restarts via `HydratedBloc`.
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  final NotificationService _notificationService;
  final HealthService _healthService;

  /// Creates an [AppSettingsBloc] initialized with default settings.
  ///
  /// Uses the provided [notificationService] or the shared instance if omitted.
  /// Uses the provided [healthService] or the shared instance if omitted.
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
    on<UpdateNotificationTime>(
      _onUpdateNotificationTime,
      transformer: restartable(),
    );
    on<TargetWeightChanged>(_onTargetWeightChanged, transformer: restartable());
    on<UpdateBiometricLock>(_onUpdateBiometricLock);
    on<UpdateBiometricSupport>(_onUpdateBiometricSupport);
    on<SetLocked>(_onSetLocked);
    on<CompleteOnboarding>(_onCompleteOnboarding, transformer: droppable());
    on<ToggleHealthSync>(_onToggleHealthSync, transformer: droppable());
    on<CheckHealthSyncStatus>(
      _onCheckHealthSyncStatus,
      transformer: droppable(),
    );
    on<ResetAppSettings>(_onResetAppSettings, transformer: droppable());
    on<UpdateLastHealthSyncTimestamp>(_onUpdateLastHealthSyncTimestamp);
  }

  void _onUpdateTheme(UpdateTheme event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onUpdateMeasurementUnit(
    UpdateMeasurementUnit event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(measurementUnit: event.measurementUnit));
  }

  void _onUpdateHeight(UpdateHeight event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(height: event.height));
  }

  /// Toggles daily reminder notifications on or off.
  ///
  /// When enabling, it requests OS permissions first and only schedules the
  /// reminder when granted. A denied request emits the transient
  /// [AppSettingsState.notificationPermissionDenied] flag instead. When
  /// disabling, it cancels the scheduled reminder.
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

  /// Updates the reminder time and re-schedules the daily notification.
  ///
  /// This only occurs when notifications are currently enabled.
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

  /// Updates the target weight to the [TargetWeightChanged.weight] value.
  ///
  /// Setting the weight to `null` clears the target weight.
  void _onTargetWeightChanged(
    TargetWeightChanged event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(targetWeight: event.weight));
  }

  void _onUpdateBiometricLock(
    UpdateBiometricLock event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isBiometricLockEnabled: event.enabled));
  }

  /// Sets the app-wide locked state to the [SetLocked.locked] state.
  ///
  /// This drives the biometric shield overlay.
  void _onSetLocked(SetLocked event, Emitter<AppSettingsState> emit) {
    emit(state.copyWith(isLocked: event.locked));
  }

  void _onUpdateBiometricSupport(
    UpdateBiometricSupport event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isBiometricSupported: event.isSupported));
  }

  void _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isOnboardingCompleted: true));
  }

  /// Toggles health sync (HealthKit or Health Connect) on or off.
  ///
  /// Side effects: when enabling, it verifies the OS health API is available and
  /// requests native permissions first. A granted request activates the sync
  /// flag, and a denied one emits the transient
  /// [AppSettingsState.healthPermissionDenied] flag instead. When disabling,
  /// it deactivates the sync flag and clears the transient denied flag. Every
  /// emitted state is persisted to disk via [HydratedBloc].
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
          healthPermissionDenied: true,
        ),
      );
      emit(state.copyWith(healthPermissionDenied: false));
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
    if (!granted) {
      // Reset the transient denied flag so a subsequent denial produces a
      // distinct state; otherwise equatable de-duplication would swallow all
      // later denial events and the UI Snackbar would never show again.
      emit(state.copyWith(healthPermissionDenied: false));
    }
  }

  /// Re-evaluates the health API availability and permission grants.
  ///
  /// This runs during app initialization. Side effects: it checks native OS health
  /// permissions (no prompt is shown) and refreshes
  /// [AppSettingsState.isHealthApiAvailable]. When the persisted sync flag is
  /// set but the permissions were revoked in the OS settings, it disables the
  /// flag. The emitted state is persisted to disk via [HydratedBloc], keeping
  /// the stored sync flag in sync with the actual native permission state.
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

  void _onUpdateLastHealthSyncTimestamp(
    UpdateLastHealthSyncTimestamp event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(lastHealthSyncTimestamp: event.timestamp));
  }

  /// Resets every setting back to the default [AppSettingsState].
  void _onResetAppSettings(
    ResetAppSettings event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(const AppSettingsState());
  }

  @override
  AppSettingsState? fromJson(Map<String, dynamic> json) {
    return AppSettingsState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(AppSettingsState state) {
    return state.toJson();
  }
}
