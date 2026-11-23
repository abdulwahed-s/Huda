import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huda/core/services/linux_prayer_tray_bridge.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/theme/huda_theme.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/linux_prayer_panel_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('linuxPrayerPanelSupported', () {
    test('GNOME sessions, including Ubuntu’s, have the panel', () {
      expect(linuxPrayerPanelSupported({'XDG_CURRENT_DESKTOP': 'ubuntu:GNOME'}), isTrue);
      expect(linuxPrayerPanelSupported({'XDG_CURRENT_DESKTOP': 'GNOME'}), isTrue);
      expect(linuxPrayerPanelSupported({'XDG_SESSION_DESKTOP': 'gnome'}), isTrue);
    });
    test('other desktops do not', () {
      expect(linuxPrayerPanelSupported({'XDG_CURRENT_DESKTOP': 'KDE'}), isFalse);
      expect(linuxPrayerPanelSupported({'XDG_CURRENT_DESKTOP': 'XFCE'}), isFalse);
      expect(linuxPrayerPanelSupported({}), isFalse);
    });
  });

  group('LinuxPrayerPanelSetupController', () {
    late ValueNotifier<LinuxPrayerTrayStatus> status;
    late List<String> clipboard;

    setUp(() {
      status = ValueNotifier(
        const LinuxPrayerTrayStatus(extensionState: 'unknown'),
      );
      clipboard = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard.add((call.arguments as Map)['text'] as String);
            }
            return null;
          });
    });

    LinuxPrayerPanelSetupController make({String? bundled}) =>
        LinuxPrayerPanelSetupController(
          loadCommand: () async => bundled,
          refresh: () async {},
          status: status,
          poll: const Duration(milliseconds: 10),
          patience: const Duration(milliseconds: 30),
        );

    test('uses the bundled installer when the Snap has one', () async {
      final setup = make(bundled: "bash '/snap/huda/1/data/x.sh'");
      expect(setup.phase, LinuxPrayerPanelPhase.loading);
      await Future<void>.delayed(Duration.zero);
      expect(setup.phase, LinuxPrayerPanelPhase.install);
      expect(setup.command, "bash '/snap/huda/1/data/x.sh'");
      setup.dispose();
    });

    test('falls back to the GitHub one-liner', () async {
      final setup = make();
      await Future<void>.delayed(Duration.zero);
      expect(setup.command, linuxPrayerPanelGithubCommand);
      setup.dispose();
    });

    test('copy → waiting → logout hint → ready, with no check button', () async {
      final setup = make();
      await Future<void>.delayed(Duration.zero);
      await setup.copy();
      expect(clipboard, [linuxPrayerPanelGithubCommand]);
      expect(setup.phase, LinuxPrayerPanelPhase.waiting);
      expect(setup.waitedLong, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(setup.waitedLong, isTrue);
      status.value = const LinuxPrayerTrayStatus(extensionState: 'enabled');
      expect(setup.phase, LinuxPrayerPanelPhase.ready);
      expect(setup.waitedLong, isFalse);
      setup.dispose();
    });

    testWidgets('the view shows the steps, then the confirmation', (
      tester,
    ) async {
      final setup = make();
      await tester.pumpWidget(
        MaterialApp(
          theme: HudaTheme.build(
            colorTheme: AppColorTheme.teal,
            brightness: Brightness.light,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: LinuxPrayerPanelSetupView(controller: setup)),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('linux-panel-copy')), findsOneWidget);
      expect(find.text(linuxPrayerPanelGithubCommand), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('linux-panel-copy')));
      await tester.pump();
      expect(find.byKey(const ValueKey('linux-panel-waiting')), findsOneWidget);
      status.value = const LinuxPrayerTrayStatus(extensionState: 'enabled');
      await tester.pump();
      expect(find.byKey(const ValueKey('linux-panel-ready')), findsOneWidget);
      setup.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });
}
