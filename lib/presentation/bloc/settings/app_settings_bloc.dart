import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/core/services/notification_service.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';

/// BLoC managing persistent app settings.
///
/// All settings are persisted across app restarts via [HydratedBloc].
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  final NotificationService _notificationService;

  /// Creates an [AppSettingsBloc] initialized with default settings.
  AppSettingsBloc({NotificationService? notificationService})
    : _notificationService =
          notificationService ?? NotificationService.instance,
      super(const AppSettingsState()) {
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateMeasurementUnit>(_onUpdateMeasurementUnit);
    on<UpdateHeight>(_onUpdateHeight);
    on<ToggleNotifications>(_onToggleNotifications);
    on<UpdateNotificationTime>(_onUpdateNotificationTime);
    on<TargetWeightChanged>(_onTargetWeightChanged);
    on<UpdateBiometricLock>(_onUpdateBiometricLock);
    on<SetLocked>(_onSetLocked);
    on<CompleteOnboarding>(_onCompleteOnboarding);
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
  /// reminder when granted; when disabling, cancels the scheduled reminder.
  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<AppSettingsState> emit,
  ) async {
    if (event.enabled) {
      final granted = await _notificationService.requestPermissions();
      if (granted) {
        emit(state.copyWith(notificationsEnabled: true));
        await _notificationService.scheduleDailyReminder(
          state.notificationTime,
        );
      } else {
        emit(state.copyWith(notificationsEnabled: false));
      }
    } else {
      emit(state.copyWith(notificationsEnabled: false));
      await _notificationService.cancelDailyReminder();
    }
  }

  /// Updates the reminder time and re-schedules the daily notification when
  /// notifications are currently enabled.
  Future<void> _onUpdateNotificationTime(
    UpdateNotificationTime event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(notificationTime: event.notificationTime));
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

  /// Marks the initial onboarding wizard as completed.
  void _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isOnboardingCompleted: true));
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
