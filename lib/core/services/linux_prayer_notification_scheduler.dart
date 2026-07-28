import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:path/path.dart' as path;

class LinuxPrayerNotificationScheduler {
  static const _assetPath = 'assets/linux/huda_prayer_notification_helper.sh';

  Future<bool> apply(PrayerNotificationPlan plan) async {
    if (!Platform.isLinux) return false;

    try {
      final environment = Platform.environment;
      final home = environment['HOME'];
      if (home == null || home.isEmpty) return false;

      final snapData =
          environment['SNAP_USER_COMMON'] ?? environment['SNAP_USER_DATA'];
      final dataRoot = snapData != null && snapData.isNotEmpty
          ? path.join(snapData, 'prayer-notifications')
          : path.join(
              environment['XDG_DATA_HOME'] ??
                  path.join(home, '.local', 'share'),
              'huda',
              'prayer-notifications',
            );
      final directory = Directory(dataRoot);
      await directory.create(recursive: true);

      final scheduleFile = File(path.join(dataRoot, 'schedule.tsv'));
      final temporaryFile = File('${scheduleFile.path}.new');
      await temporaryFile.writeAsString(_serialize(plan));
      await temporaryFile.rename(scheduleFile.path);

      if (snapData != null && snapData.isNotEmpty) {
        return _startSnapService(environment);
      }

      final helperFile = File(path.join(dataRoot, 'notify-prayers.sh'));
      final helperData = await rootBundle.loadString(_assetPath);
      await helperFile.writeAsString(helperData);
      await Process.run('chmod', ['700', helperFile.path]);

      if (await _installSystemdUserService(
        home: home,
        helperPath: helperFile.path,
        schedulePath: scheduleFile.path,
      )) {
        return true;
      }

      await _installAutostartFallback(home, helperFile.path, scheduleFile.path);
      await Process.start(
        helperFile.path,
        const [],
        environment: {'HUDA_PRAYER_SCHEDULE': scheduleFile.path},
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (error) {
      debugPrint('Linux prayer notification service setup failed: $error');
      return false;
    }
  }

  String _serialize(PrayerNotificationPlan plan) {
    return plan.events.map((event) {
      final title = base64Encode(utf8.encode(event.title));
      final body = base64Encode(utf8.encode(event.body));
      return '${event.scheduledTime.millisecondsSinceEpoch ~/ 1000}'
          '\t${event.id}\t$title\t$body';
    }).join('\n');
  }

  Future<bool> _startSnapService(Map<String, String> environment) async {
    final instance = environment['SNAP_INSTANCE_NAME'] ?? 'huda';
    final result = await Process.run(
      'snapctl',
      ['start', '--enable', '$instance.prayer-notifications'],
    );
    if (result.exitCode != 0) {
      debugPrint('Unable to start snap prayer service: ${result.stderr}');
    }
    return result.exitCode == 0;
  }

  Future<bool> _installSystemdUserService({
    required String home,
    required String helperPath,
    required String schedulePath,
  }) async {
    final configHome =
        Platform.environment['XDG_CONFIG_HOME'] ?? path.join(home, '.config');
    final unitDirectory = Directory(path.join(configHome, 'systemd', 'user'));
    await unitDirectory.create(recursive: true);
    final unit = File(path.join(
      unitDirectory.path,
      'huda-prayer-notifications.service',
    ));
    await unit.writeAsString('''
[Unit]
Description=Huda prayer time notifications
After=graphical-session.target

[Service]
Type=simple
Environment=${_systemdQuote('HUDA_PRAYER_SCHEDULE=$schedulePath')}
ExecStart=${_systemdQuote(helperPath)}
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
'''
        .trimLeft());

    try {
      final reload =
          await Process.run('systemctl', ['--user', 'daemon-reload']);
      if (reload.exitCode != 0) return false;
      final enable = await Process.run(
        'systemctl',
        [
          '--user',
          'enable',
          '--now',
          'huda-prayer-notifications.service',
        ],
      );
      if (enable.exitCode != 0) return false;
      await Process.run(
        'systemctl',
        ['--user', 'restart', 'huda-prayer-notifications.service'],
      );
      return true;
    } on ProcessException {
      return false;
    }
  }

  Future<void> _installAutostartFallback(
    String home,
    String helperPath,
    String schedulePath,
  ) async {
    final configHome =
        Platform.environment['XDG_CONFIG_HOME'] ?? path.join(home, '.config');
    final autostart = Directory(path.join(configHome, 'autostart'));
    await autostart.create(recursive: true);
    final desktop = File(path.join(autostart.path, 'huda-prayers.desktop'));
    await desktop.writeAsString('''
[Desktop Entry]
Type=Application
Name=Huda Prayer Notifications
Comment=Delivers locally calculated prayer time notifications
Exec=env HUDA_PRAYER_SCHEDULE=${_desktopQuote(schedulePath)} ${_desktopQuote(helperPath)}
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
'''
        .trimLeft());
  }

  String _systemdQuote(String value) =>
      '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';

  String _desktopQuote(String value) =>
      '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
}
