import 'package:flutter/material.dart';
import 'package:huda/core/services/prayer_country_names.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_attention_items.dart';
import 'package:huda/presentation/widgets/prayer_times/prayer_palette.dart';

class PrayerAttentionStrip extends StatefulWidget {
  const PrayerAttentionStrip({
    super.key,
    required this.items,
    this.onChooseCountry,
    this.onDismissCountry,
  });

  final List<PrayerAttentionItem> items;
  final Future<void> Function(String countryCode)? onChooseCountry;
  final VoidCallback? onDismissCountry;

  @override
  State<PrayerAttentionStrip> createState() => _PrayerAttentionStripState();
}

class _PrayerAttentionStripState extends State<PrayerAttentionStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
      value: _asksQuestion(widget.items) ? 1 : 0,
    );
    _expand = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  bool get _expanded =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.completed;

  static bool _asksQuestion(List<PrayerAttentionItem> items) =>
      items.any((item) => item.countryCandidates.isNotEmpty);

  @override
  void didUpdateWidget(covariant PrayerAttentionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_asksQuestion(widget.items) && !_asksQuestion(oldWidget.items)) {
      _controller.forward();
    }
    if (widget.items.length < 2 && !_controller.isDismissed) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded ? _controller.reverse() : _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final palette = PrayerPalette.of(context);
    final top = items.first;
    final rest = items.skip(1).toList();
    final accent = attentionAccent(palette, top.tone);
    final expandable = rest.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              accent.withValues(alpha: palette.isDark ? 0.12 : 0.07),
              palette.page,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: palette.isDark ? 0.34 : 0.22),
            ),
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: accent),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      item: top,
                      moreCount: rest.length,
                      expand: expandable ? _expand : null,
                      expanded: _expanded,
                      tooltip: _expanded ? l10n.showLess : l10n.viewMore,
                      onToggle: expandable ? _toggle : null,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 50),
                      child: _ItemBody(
                        item: top,
                        expand: expandable ? _expand : null,
                        onChooseCountry: widget.onChooseCountry,
                        onDismissCountry: widget.onDismissCountry,
                      ),
                    ),
                    if (expandable)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => _controller.isDismissed
                            ? const SizedBox(width: double.infinity)
                            : ExcludeSemantics(
                                excluding: !_expanded,
                                child: IgnorePointer(
                                  ignoring: !_expanded,
                                  child: child,
                                ),
                              ),
                        child: SizeTransition(
                          sizeFactor: _expand,
                          alignment: Alignment.topCenter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < rest.length; i++)
                                _Staggered(
                                  animation: _controller,
                                  index: i,
                                  count: rest.length,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: _SubCard(
                                      item: rest[i],
                                      onChooseCountry: widget.onChooseCountry,
                                      onDismissCountry: widget.onDismissCountry,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color attentionAccent(PrayerPalette palette, PrayerAttentionTone tone) =>
    switch (tone) {
      PrayerAttentionTone.error => palette.error,
      PrayerAttentionTone.warning => palette.warning,
      PrayerAttentionTone.info => palette.primary,
    };

TextStyle? _bodyStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(
    color: PrayerPalette.of(context).muted,
    height: 1.45,
  );
}

class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.animation,
    required this.index,
    required this.count,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (0.15 + index * 0.12).clamp(0.0, 0.6);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0, 0.7, curve: Curves.easeInCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.item,
    required this.moreCount,
    required this.expand,
    required this.expanded,
    required this.tooltip,
    required this.onToggle,
  });

  final PrayerAttentionItem item;
  final int moreCount;

  final Animation<double>? expand;
  final bool expanded;
  final String tooltip;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = attentionAccent(palette, item.tone);
    final expand = this.expand;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconTile(icon: item.icon, color: accent, busy: item.busy, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                    if (item.offline) _OfflinePill(label: l10n.youreOffline),
                  ],
                ),
                if (moreCount > 0) ...[
                  const SizedBox(height: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      expanded
                          ? l10n.prayerAttentionCount(moreCount + 1)
                          : l10n.prayerAttentionMore(moreCount),
                      key: ValueKey(expanded),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (expand != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              expanded: expanded,
              label: tooltip,
              excludeSemantics: true,
              child: Material(
                color: accent.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onToggle,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: 32,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(expand),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (onToggle == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: row,
    );
  }
}

class _ItemBody extends StatelessWidget {
  const _ItemBody({
    required this.item,
    required this.expand,
    this.onChooseCountry,
    this.onDismissCountry,
  });

  final PrayerAttentionItem item;

  final Animation<double>? expand;
  final Future<void> Function(String countryCode)? onChooseCountry;
  final VoidCallback? onDismissCountry;

  @override
  Widget build(BuildContext context) {
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = attentionAccent(palette, item.tone);
    final body = _bodyStyle(context);
    final askCountry =
        item.countryCandidates.isNotEmpty && onChooseCountry != null;
    final expand = this.expand;

    final details = item.details.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                for (final detail in item.details)
                  _DetailLine(
                    icon: detail.icon,
                    text: detail.text,
                    style: body?.copyWith(color: palette.ink),
                    iconColor: palette.muted,
                  ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        if (expand == null) ...[
          Text(item.message, style: body),
          ?details,
        ] else
          AnimatedBuilder(
            animation: expand,
            builder: (context, _) {
              final open =
                  expand.status == AnimationStatus.forward ||
                  expand.status == AnimationStatus.completed;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      item.message,
                      maxLines: open ? null : 2,
                      overflow: open ? null : TextOverflow.ellipsis,
                      style: body,
                    ),
                  ),
                  if (details != null && !expand.isDismissed)
                    SizeTransition(
                      sizeFactor: expand,
                      alignment: Alignment.topCenter,
                      child: FadeTransition(opacity: expand, child: details),
                    ),
                ],
              );
            },
          ),
        if (askCountry) ...[
          const SizedBox(height: 10),
          _CountryQuestion(
            question: l10n.prayerCountryQuestion,
            notSure: l10n.prayerCountryNotSure,
            countryCodes: item.countryCandidates,
            localeCode: Localizations.localeOf(context).languageCode,
            color: accent,
            enabled: !item.busy,
            onChoose: onChooseCountry!,
            onDismiss: onDismissCountry,
          ),
        ],
        if (item.primary != null || item.secondary != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.primary != null)
                _PrimaryButton(action: item.primary!, accent: accent),
              if (item.secondary != null)
                TextButton.icon(
                  onPressed: item.secondary!.onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(item.secondary!.icon, size: 18),
                  label: Text(item.secondary!.label),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubCard extends StatelessWidget {
  const _SubCard({
    required this.item,
    this.onChooseCountry,
    this.onDismissCountry,
  });

  final PrayerAttentionItem item;
  final Future<void> Function(String countryCode)? onChooseCountry;
  final VoidCallback? onDismissCountry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = PrayerPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final accent = attentionAccent(palette, item.tone);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.black.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: item.icon, color: accent, busy: item.busy, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      if (item.offline) _OfflinePill(label: l10n.youreOffline),
                    ],
                  ),
                ),
                _ItemBody(
                  item: item,
                  expand: null,
                  onChooseCountry: onChooseCountry,
                  onDismissCountry: onDismissCountry,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.action, required this.accent});

  final PrayerAttentionAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: action.onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent.withValues(alpha: 0.16),
        foregroundColor: accent,
        disabledBackgroundColor: accent.withValues(alpha: 0.08),
        disabledForegroundColor: accent.withValues(alpha: 0.7),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
    );
  }
}

class _CountryQuestion extends StatelessWidget {
  const _CountryQuestion({
    required this.question,
    required this.notSure,
    required this.countryCodes,
    required this.localeCode,
    required this.color,
    required this.enabled,
    required this.onChoose,
    this.onDismiss,
  });
  final String question;
  final String notSure;
  final List<String> countryCodes;
  final String localeCode;
  final Color color;
  final bool enabled;
  final Future<void> Function(String countryCode) onChoose;
  final VoidCallback? onDismiss;

  static String _flag(String code) => String.fromCharCodes(
    code.toUpperCase().codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: PrayerPalette.of(context).ink,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final code in countryCodes)
              OutlinedButton(
                onPressed: enabled ? () => onChoose(code) : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: PrayerPalette.of(context).ink,
                  backgroundColor: color.withValues(alpha: 0.10),
                  side: BorderSide(color: color.withValues(alpha: 0.35)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  '${_flag(code)}  '
                  '${PrayerCountryNames.localized(code, localeCode) ?? code}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (onDismiss != null)
              TextButton(
                onPressed: enabled ? onDismiss : null,
                style: TextButton.styleFrom(
                  foregroundColor: PrayerPalette.of(context).muted,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(notSure),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.busy,
    this.size = 40,
  });
  final IconData icon;
  final Color color;
  final bool busy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: busy
            ? SizedBox.square(
                key: const ValueKey('busy'),
                dimension: size / 2,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
              )
            : Icon(icon, key: ValueKey(icon), size: size * 0.55, color: color),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.text,
    required this.style,
    required this.iconColor,
  });
  final IconData icon;
  final String text;
  final TextStyle? style;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}

class _OfflinePill extends StatelessWidget {
  const _OfflinePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = PrayerPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 12, color: colors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
