import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_event.dart';
import 'package:pure_weight/presentation/bloc/settings/app_settings_state.dart';

/// BLoC managing persistent app settings.
///
/// All settings are persisted across app restarts via [HydratedBloc].
class AppSettingsBloc extends HydratedBloc<AppSettingsEvent, AppSettingsState> {
  /// Creates an [AppSettingsBloc] initialized with default settings.
  AppSettingsBloc() : super(const AppSettingsState()) {
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateMeasurementUnit>(_onUpdateMeasurementUnit);
    on<UpdateHeight>(_onUpdateHeight);
    on<ToggleNotifications>(_onToggleNotifications);
    on<UpdateNotificationTime>(_onUpdateNotificationTime);
    on<UpdateTargetWeight>(_onUpdateTargetWeight);
    on<UpdateBiometricLock>(_onUpdateBiometricLock);
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

  void _onToggleNotifications(
    ToggleNotifications event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  void _onUpdateNotificationTime(
    UpdateNotificationTime event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(notificationTime: event.notificationTime));
  }

  void _onUpdateTargetWeight(
    UpdateTargetWeight event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(targetWeight: event.targetWeight));
  }

  void _onUpdateBiometricLock(
    UpdateBiometricLock event,
    Emitter<AppSettingsState> emit,
  ) {
    emit(state.copyWith(isBiometricLockEnabled: event.enabled));
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
