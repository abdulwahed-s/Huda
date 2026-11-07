import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_platform.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';
import 'package:huda/data/models/miqaat_lock/miqaat_lock.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_format.dart';

/// What the lock still needs from the system, led by a lit lamp: one row
/// per permission (a tick once allowed) and "Check again".
class MiqaatAccessCard extends StatelessWidget {
  const MiqaatAccessCard({
    super.key,
    required this.permissions,
    required this.onAccessibility,
    required this.onOverlay,
    required this.onScreenTime,
    required this.onCheck,
  });

  final MiqaatLockPermissions permissions;
  final VoidCallback onAccessibility;
  final VoidCallback onOverlay;
  final VoidCallback onScreenTime;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget row(
      String key,
      IconData icon,
      String title,
      String subtitle,
      bool granted,
      VoidCallback onTap,
    ) => HudaSettingsRow(
      key: ValueKey('miqaat-permission-$key'),
      icon: granted ? Icons.check_rounded : icon,
      title: title,
      subtitle: subtitle,
      trailing: granted
          ? Icon(Icons.check_circle_rounded, color: scheme.primary)
          : const Icon(Icons.chevron_right_rounded),
      onTap: granted ? null : onTap,
    );

    final rows = switch (MiqaatLockPlatform.current) {
      MiqaatLockPlatform.ios => [
        row(
          'screen-time',
          Icons.hourglass_bottom_rounded,
          l10n.screenTimeAccess,
          l10n.screenTimeAccessDescription,
          permissions.screenTimeAuthorized,
          onScreenTime,
        ),
      ],
      _ => [
        row(
          'accessibility',
          Icons.accessibility_new_rounded,
          l10n.accessibilityService,
          l10n.accessibilityServiceDescription,
          permissions.accessibilityEnabled,
          onAccessibility,
        ),
        row(
          'overlay',
          Icons.layers_rounded,
          l10n.overlayPermission,
          l10n.overlayPermissionDescription,
          permissions.overlayPermissionGranted,
          onOverlay,
        ),
      ],
    };

    return HudaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              space.lg,
              space.lg,
              space.lg,
              space.sm,
            ),
            child: Row(
              children: [
                const HudaLamp(child: Icon(Icons.key_rounded)),
                SizedBox(width: space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.permissionsRequired, style: text.titleMedium),
                      SizedBox(height: space.xxs),
                      Text(
                        l10n.permissionsRequiredDescription,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final r in rows)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: space.xs),
              child: r,
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsets.all(space.xs),
              child: TextButton.icon(
                onPressed: onCheck,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.miqaatCheckAgain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An app's icon from the system, or a plain mark.
class MiqaatAppIcon extends StatelessWidget {
  const MiqaatAppIcon(this.app, {super.key});

  final LockedApp app;

  @override
  Widget build(BuildContext context) {
    final data = app.iconBase64;
    if (data != null && data.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(context.tokens.radius.sm),
          child: Image.memory(
            base64Decode(data),
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const HudaIconMark(Icons.apps_rounded),
          ),
        );
      } catch (_) {}
    }
    return const HudaIconMark(Icons.apps_rounded);
  }
}

/// The apps the lock closes. Android lists them, each removable; iOS
/// shows Screen Time's count. One "Add apps" row opens the chooser.
class MiqaatAppsSection extends StatelessWidget {
  const MiqaatAppsSection({
    super.key,
    required this.apps,
    required this.onAdd,
    required this.onRemove,
    this.iosCount,
  });

  final List<LockedApp> apps;
  final VoidCallback onAdd;
  final ValueChanged<LockedApp> onRemove;

  /// Screen Time's selection on iOS (null elsewhere).
  final ({int apps, int categories})? iosCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ios = iosCount;
    final scheme = Theme.of(context).colorScheme;

    final List<Widget> rows;
    if (ios != null) {
      final total = ios.apps + ios.categories;
      rows = [
        HudaSettingsRow(
          icon: Icons.shield_rounded,
          title: l10n.iosScreenTimeProtection,
          subtitle: total == 0
              ? l10n.noAppsSelected
              : ios.categories > 0
              ? l10n.iosAppsAndCategoriesSelected(ios.apps, ios.categories)
              : ios.apps == 1
              ? l10n.iosAppSelected(1)
              : l10n.iosAppsSelected(ios.apps),
        ),
      ];
    } else if (apps.isEmpty) {
      rows = [_Empty(l10n.noAppsSelected)];
    } else {
      rows = [
        for (final app in apps)
          MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: ListTile(
              key: ValueKey('miqaat-app-${app.packageId}'),
              leading: MiqaatAppIcon(app),
              title: Text(app.appName),
              trailing: IconButton(
                key: ValueKey('miqaat-remove-${app.packageId}'),
                tooltip: l10n.remove,
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => onRemove(app),
              ),
            ),
          ),
      ];
    }

    return HudaSection(
      title: l10n.lockedApps,
      children: [
        ...rows,
        HudaSettingsRow(
          key: const ValueKey('miqaat-add-apps'),
          icon: Icons.add_rounded,
          title: ios != null ? l10n.selectApps : l10n.addApps,
          onTap: onAdd,
        ),
      ],
    );
  }
}

/// The lock's time windows (up to five): tap one to edit it.
class MiqaatWindowsSection extends StatelessWidget {
  const MiqaatWindowsSection({
    super.key,
    required this.slots,
    required this.completed,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<TimeSlot> slots;
  final Set<String> completed;
  final VoidCallback onAdd;
  final ValueChanged<TimeSlot> onEdit;
  final ValueChanged<TimeSlot> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return HudaSection(
      title: l10n.timeSlots,
      footer: l10n.miqaatSlotCount(
        slots.length,
        MiqaatLockSettings.maxTimeSlots,
      ),
      children: [
        if (slots.isEmpty) _Empty(l10n.noTimeSlotsConfigured),
        for (final slot in slots)
          HudaSettingsRow(
            key: ValueKey('miqaat-slot-${slot.id}'),
            icon: slot.isActiveAt(now)
                ? Icons.lock_clock_rounded
                : completed.contains(slot.id)
                ? Icons.lock_open_rounded
                : Icons.schedule_rounded,
            title: slot.label ?? miqaatRange(context, slot),
            subtitle: [
              if (slot.label != null) miqaatRange(context, slot),
              miqaatDays(context, slot.weekdays),
            ].join('\n'),
            onTap: () => onEdit(slot),
            trailing: IconButton(
              key: ValueKey('miqaat-remove-slot-${slot.id}'),
              tooltip: l10n.remove,
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onPressed: () => onRemove(slot),
            ),
          ),
        if (slots.length < MiqaatLockSettings.maxTimeSlots)
          HudaSettingsRow(
            key: const ValueKey('miqaat-add-slot'),
            icon: Icons.add_rounded,
            title: l10n.addTimeSlot,
            onTap: onAdd,
          ),
      ],
    );
  }
}

/// How long to spend in Huda each window: the usual lengths one tap
/// away, any other length through Custom.
class MiqaatGoalSection extends StatelessWidget {
  const MiqaatGoalSection({
    super.key,
    required this.minutes,
    required this.onSelect,
    required this.onCustom,
  });

  final int minutes;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    const presets = MiqaatLockSettings.defaultDurationOptions;
    final custom = !presets.contains(minutes);
    return HudaSection(
      title: l10n.sessionDuration,
      footer: l10n.sessionDurationDescription,
      children: [
        Padding(
          padding: EdgeInsets.all(space.md),
          child: Wrap(
            spacing: space.xs,
            runSpacing: space.xs,
            children: [
              for (final m in presets)
                ChoiceChip(
                  key: ValueKey('miqaat-goal-$m'),
                  label: Text(l10n.miqaatMinutesShort(m)),
                  selected: m == minutes,
                  showCheckmark: false,
                  onSelected: (_) => onSelect(m),
                ),
              ChoiceChip(
                key: const ValueKey('miqaat-goal-custom'),
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  custom
                      ? l10n.miqaatMinutesShort(minutes)
                      : l10n.customDuration,
                ),
                selected: custom,
                showCheckmark: false,
                onSelected: (_) => onCustom(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: space.lg, vertical: space.lg),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
