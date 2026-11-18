import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/widget_management/prayer_widget_tab.dart';
import 'package:huda/presentation/widgets/widget_management/quran_verse_widget_tab.dart';
import 'package:huda/presentation/widgets/widget_management/widget_settings_parts.dart';

/// Which home-screen widget the page shows.
enum HomeWidgetKind { quran, prayer }

/// Home screen widgets, in the standard tier: a switch between the two
/// widgets, then the chosen widget's live preview and settings.
class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({
    super.key,
    this.initial = HomeWidgetKind.quran,
  });

  final HomeWidgetKind initial;

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  late HomeWidgetKind _kind = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = math.min(MediaQuery.textScalerOf(context).scale(16) / 16, 2);
    final switcher = LayoutBuilder(
      builder: (context, constraints) {
        // Icons only while both labels still fit beside them.
        final icons = constraints.maxWidth / 2 >= 150 * scale;
        return SegmentedButton<HomeWidgetKind>(
          key: const ValueKey('widgets-switch'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: HomeWidgetKind.quran,
              icon: icons ? const Icon(Icons.menu_book_outlined) : null,
              label: Text(
                l10n.quranVerseWidget,
                textAlign: TextAlign.center,
                key: const ValueKey('widgets-tab-quran'),
              ),
            ),
            ButtonSegment(
              value: HomeWidgetKind.prayer,
              icon: icons ? const Icon(Icons.schedule_rounded) : null,
              label: Text(
                l10n.prayerTimesWidget,
                textAlign: TextAlign.center,
                key: const ValueKey('widgets-tab-prayer'),
              ),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (selection) {
            if (selection.first == _kind) return;
            HudaHaptics.selection(context);
            setState(() => _kind = selection.first);
          },
        );
      },
    );
    final space = context.tokens.space;
    final insets = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = space.gutter(width);
    final fold = FoldInfo.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // With two panes the switch belongs to the leading (preview) pane and
    // keeps to its side of a fold; on one column it's centered.
    final twoPanes = AdaptivePanes.showsTwoPanes(
      width,
      fold,
      twoPaneMinWidth: WidgetSettingsLayout.twoPaneMinWidth,
    );
    final double? leading = !twoPanes
        ? null
        : fold.splitsHorizontally
        ? (rtl ? width - fold.end : fold.start)
        : (width * 0.38).clamp(320.0, 460.0);
    // In the leading pane only the leading edge's inset applies.
    final left = leading == null || !rtl ? insets.left : 0.0;
    final right = leading == null || rtl ? insets.right : 0.0;
    final bar = Padding(
      padding: EdgeInsets.fromLTRB(
        gutter + left,
        space.xs,
        gutter + right,
        space.sm,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SizedBox(width: double.infinity, child: switcher),
      ),
    );
    return HudaScaffold(
      title: l10n.widgetManagement,
      body: HudaRevealScope(
        child: Column(
          children: [
            // The switch stays put while the page under it changes.
            if (leading == null)
              Center(child: bar)
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(width: leading, child: bar),
              ),
            Expanded(
              child: HudaStateSwitcher(
                stateKey: _kind,
                // The old page fades out before the new one comes in, so
                // two sets of settings never show through each other.
                sequential: true,
                child: switch (_kind) {
                  HomeWidgetKind.quran => const QuranVerseWidgetTab(
                    key: ValueKey('quran'),
                  ),
                  HomeWidgetKind.prayer => const PrayerWidgetTab(
                    key: ValueKey('prayer'),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
