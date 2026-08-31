/// Represents the user's weight goal intent.
enum WeightGoalMode {
  /// Goal is to lose weight (weight <= target is success).
  lose,

  /// Goal is to maintain weight within a stable threshold (e.g. ±1.0 kg).
  maintain,

  /// Goal is to gain weight / build mass (weight >= target is success).
  gain,
}
