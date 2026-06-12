import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';

class SahurAlarmRingScreen extends StatefulWidget {
  const SahurAlarmRingScreen({required this.alarmSettings, super.key});

  final AlarmSettings alarmSettings;

  @override
  State<SahurAlarmRingScreen> createState() => _SahurAlarmRingScreenState();
}

class _SahurAlarmRingScreenState extends State<SahurAlarmRingScreen>
    with SingleTickerProviderStateMixin {
  StreamSubscription<AlarmSet>? _ringingSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _ringingSubscription = Alarm.ringing.listen((alarmSet) {
      final stillRinging = alarmSet.alarms.any(
        (a) => a.id == widget.alarmSettings.id,
      );
      if (!stillRinging) {
        _ringingSubscription?.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _ringingSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    _ringingSubscription?.cancel();
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _snoozeAlarm() async {
    _ringingSubscription?.cancel();
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    await Alarm.stop(widget.alarmSettings.id);
    await Alarm.set(
      alarmSettings: widget.alarmSettings.copyWith(
        dateTime: snoozeTime,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F4F8),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark
                              ? theme.primaryColor
                              : theme.primaryColor.withAlpha(30))
                          .withAlpha(isDark ? 50 : 30),
                    ),
                    child: Icon(
                      Icons.alarm,
                      size: 64,
                      color: isDark ? Colors.white : theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.sahurAlarmRinging,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.sahurAlarmDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AlarmActionButton(
                        onPressed: _snoozeAlarm,
                        icon: Icons.snooze,
                        label: l10n.snoozeAlarm,
                        backgroundColor: isDark
                            ? Colors.orange.withAlpha(50)
                            : Colors.orange.withAlpha(30),
                        foregroundColor: Colors.orange,
                      ),
                      _AlarmActionButton(
                        onPressed: _stopAlarm,
                        icon: Icons.alarm_off,
                        label: l10n.stopAlarm,
                        backgroundColor: isDark
                            ? Colors.red.withAlpha(50)
                            : Colors.red.withAlpha(30),
                        foregroundColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmActionButton extends StatelessWidget {
  const _AlarmActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(icon, size: 36, color: foregroundColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
          ),
        ),
      ],
    );
  }
}
