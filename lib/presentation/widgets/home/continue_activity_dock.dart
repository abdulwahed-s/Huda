import 'package:flutter/material.dart';

@immutable
class ContinueActivityDockItem {
  const ContinueActivityDockItem({
    required this.label,
    required this.icon,
    required this.hasActivity,
    required this.semanticHint,
    required this.unavailableLabel,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool hasActivity;
  final String semanticHint;
  final String unavailableLabel;
  final VoidCallback? onTap;
}

class ContinueActivityDock extends StatelessWidget {
  const ContinueActivityDock({
    super.key,
    required this.title,
    required this.items,
    required this.isDarkMode,
  });

  final String title;
  final List<ContinueActivityDockItem> items;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final foreground = isDarkMode
        ? const Color(0xFFF5F7FA)
        : const Color(0xFF17212B);
    final muted = isDarkMode
        ? const Color(0xFFA5AFBE)
        : const Color(0xFF667085);
    final border = isDarkMode
        ? const Color(0xFF303B4B)
        : const Color(0xFFDCE4EA);
    final dockBackground = isDarkMode
        ? const Color(0xFF111821)
        : const Color(0xFFF1F5F7);
    final hasActivity = items.any((item) => item.hasActivity);

    return Semantics(
      container: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: isDarkMode
                ? const [Color(0xFF202B37), Color(0xFF171F29)]
                : const [Color(0xFFFFFFFF), Color(0xFFF7FAFC)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: .2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? .16 : .07),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: hasActivity ? accent : muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.history_rounded, size: 16, color: muted),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final useVerticalLayout =
                    constraints.maxWidth < 300 || textScale > 1.45;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: dockBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: useVerticalLayout
                      ? _VerticalDockItems(
                          items: items,
                          accent: accent,
                          foreground: foreground,
                          muted: muted,
                          border: border,
                        )
                      : SizedBox(
                          height: 68,
                          child: _HorizontalDockItems(
                            items: items,
                            accent: accent,
                            foreground: foreground,
                            muted: muted,
                            border: border,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalDockItems extends StatelessWidget {
  const _HorizontalDockItems({
    required this.items,
    required this.accent,
    required this.foreground,
    required this.muted,
    required this.border,
  });

  final List<ContinueActivityDockItem> items;
  final Color accent;
  final Color foreground;
  final Color muted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) Container(width: 1, height: 27, color: border),
          Expanded(
            child: _DockAction(
              item: items[index],
              accent: accent,
              foreground: foreground,
              muted: muted,
              horizontal: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _VerticalDockItems extends StatelessWidget {
  const _VerticalDockItems({
    required this.items,
    required this.accent,
    required this.foreground,
    required this.muted,
    required this.border,
  });

  final List<ContinueActivityDockItem> items;
  final Color accent;
  final Color foreground;
  final Color muted;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: border,
            ),
          SizedBox(
            height: 58,
            child: _DockAction(
              item: items[index],
              accent: accent,
              foreground: foreground,
              muted: muted,
              horizontal: false,
            ),
          ),
        ],
      ],
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.item,
    required this.accent,
    required this.foreground,
    required this.muted,
    required this.horizontal,
  });

  final ContinueActivityDockItem item;
  final Color accent;
  final Color foreground;
  final Color muted;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final enabled = item.hasActivity && item.onTap != null;
    final contentColor = item.hasActivity ? foreground : muted;
    final iconColor = item.hasActivity ? accent : muted;

    return Semantics(
      button: true,
      enabled: enabled,
      label: item.label,
      hint: item.semanticHint,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? item.onTap : null,
            overlayColor: WidgetStatePropertyAll(accent.withValues(alpha: .12)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal ? 7 : 12),
              child: Row(
                mainAxisAlignment: horizontal
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(item.icon, color: iconColor, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: item.hasActivity ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: contentColor,
                            fontSize: horizontal ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        if (!item.hasActivity) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded, color: muted, size: 9),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  item.unavailableLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: horizontal ? 7.5 : 9,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!horizontal && item.hasActivity) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: contentColor,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
