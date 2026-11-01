/// The app's "Haptic feedback" switch in Settings (default on).
/// `HudaHaptics` follows it, so people can keep Huda quiet without turning
/// haptics off for the whole phone. `ThemeCubit` loads and saves it.
abstract final class HudaHapticsSetting {
  static const storageKey = 'haptic_feedback_enabled';

  /// Whether Huda plays haptics at all.
  static bool enabled = true;
}
