/// Routes native desktop settings requests to an existing prayer page first.
abstract final class DesktopPrayerSettingsNavigation {
  static final List<bool Function()> _actions = [];

  static void register(bool Function() action) => _actions.add(action);
  static void unregister(bool Function() action) => _actions.remove(action);

  static bool openOnCurrentPage() {
    for (final action in _actions.reversed) {
      if (action()) return true;
    }
    return false;
  }
}
