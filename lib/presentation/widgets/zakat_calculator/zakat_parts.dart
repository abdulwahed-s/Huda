import 'package:flutter/material.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_sheet.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_identity.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_result.dart';

/// "About Zakat": what zakat is and how the nisab works, with the mizan at
/// rest above it.
Future<void> showZakatAbout(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showHudaSheet<void>(
    context: context,
    title: l10n.aboutZakat,
    builder: (context) {
      final space = context.tokens.space;
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Ornament(
            painter: ZakatMizanPainter(
              style: OrnamentStyle.of(context),
              tilt: 0,
            ),
            size: const Size(double.infinity, 96),
          ),
          SizedBox(height: space.lg),
          Text(
            l10n.zakatDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    },
  );
}

/// Loading, in the shape of what's coming: the result card, then a ledger
/// section of lines.
class ZakatSkeleton extends StatelessWidget {
  const ZakatSkeleton({
    super.key,
    this.result = true,
    this.ledger = true,
    this.totals = true,
  });

  /// Two panes show each part in its own pane.
  final bool result;
  final bool ledger;

  /// The totals card under the result (not in tabletop's top half).
  final bool totals;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    Widget line() => Padding(
      padding: EdgeInsets.symmetric(vertical: space.sm),
      child: Row(
        children: [
          const HudaSkeletonBlock(width: 38, height: 38, circle: true),
          SizedBox(width: space.md),
          const Expanded(child: HudaSkeletonLines(lines: 2)),
          SizedBox(width: space.md),
          const HudaSkeletonBlock(width: 120, height: 44),
        ],
      ),
    );
    return HudaSkeleton(
      // Read "Loading" once when both panes show a part.
      announce: ledger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result) const HudaSkeletonBlock(height: 220),
          if (result && ledger) SizedBox(height: space.xl),
          if (!ledger && totals) ...[
            SizedBox(height: space.xl),
            const HudaSkeletonBlock(height: 180),
          ],
          if (ledger) ...[
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: HudaSkeletonBlock(width: 96, height: 12),
            ),
            SizedBox(height: space.sm),
            for (var i = 0; i < 6; i++) line(),
          ],
        ],
      ),
    );
  }
}

/// Phones: the result, pinned to the bottom edge while the result card is
/// scrolled away (and above the keyboard while typing), so every amount
/// shows its effect. Tapping it scrolls back to the card.
class ZakatResultStrip extends StatelessWidget {
  const ZakatResultStrip({
    super.key,
    required this.state,
    required this.visible,
    required this.onTap,
  });

  final ZakatCalculatorLoaded state;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final calc = state.calculation;
    final empty = !zakatHasAmounts(calc);
    final due = calc.isZakatDue;
    final status = empty
        ? l10n.zakatEmptyTitle
        : (due ? l10n.zakatIsDue : l10n.noZakatDue);
    final duration = tokens.motion.of(context, tokens.motion.medium);
    final insets = MediaQuery.paddingOf(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1),
        duration: duration,
        curve: tokens.motion.emphasized,
        child: Material(
          color: scheme.surfaceContainerLow,
          shape: Border(top: BorderSide(color: scheme.outlineVariant)),
          child: InkWell(
            onTap: onTap,
            child: Semantics(
              button: true,
              label: '${l10n.zakatShowResult}. $status',
              child: Padding(
                // The background reaches the edge; the content rests above
                // the navigation bar and clear of the side insets.
                padding: EdgeInsets.fromLTRB(
                  space.md + insets.left,
                  space.sm,
                  space.md + insets.right,
                  space.sm + context.bottomInset,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 40,
                      child: ExcludeSemantics(
                        child: ZakatBalance(
                          wealth: calc.netAssets,
                          nisab: calc.nisabValue,
                          due: due,
                        ),
                      ),
                    ),
                    SizedBox(width: space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: ZakatCountUp(
                              value: calc.zakatAmount,
                              currency: state.selectedCurrency,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: due ? scheme.primary : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: space.xs),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the nisab's metal price comes from: updating (with the lamp
/// spinner), the market's and its day, or the person's own.
class ZakatPriceSource extends StatelessWidget {
  const ZakatPriceSource({super.key, required this.state, this.prefix});

  final ZakatCalculatorLoaded state;

  /// Leads the line ("Gold · USD 124.62 per gram").
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final date = state.priceDate;
    // Only the automatic update: a retry has the banner's "Retrying…".
    final working =
        !state.nisabPriceIsManual &&
        state.priceStatus == ZakatPriceStatus.updating;
    final source = state.nisabPriceIsManual
        ? l10n.zakatPriceYours
        : working
        ? l10n.zakatPriceUpdating
        : date == null
        ? null
        : l10n.zakatPriceMarket(zakatPriceDay(context, date));
    final text = [?prefix, ?source].join(' · ');
    return HudaStateSwitcher(
      stateKey: (working, state.nisabPriceIsManual, date),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (working) ...[
            HudaLampSpinner(size: 14, color: tokens.gilt),
            SizedBox(width: tokens.space.xs),
          ],
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The market prices couldn't be updated (with Retry), or are being
/// retried after a tap. Nothing while they're current or updating on
/// their own (the price line says so).
class ZakatPriceBanner extends StatelessWidget {
  const ZakatPriceBanner({
    super.key,
    required this.state,
    required this.onRetry,
    this.below = false,
  });

  final ZakatCalculatorLoaded state;
  final VoidCallback onRetry;

  /// Under the result card (short windows, so the amount stays in view).
  final bool below;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final date = state.priceDate;
    final status = switch (state.priceStatus) {
      ZakatPriceStatus.failed => HudaStatus.failed,
      ZakatPriceStatus.retrying => HudaStatus.retrying,
      _ => null,
    };
    final motion = context.tokens.motion;
    final duration = motion.of(context, motion.medium);
    final switcher = AnimatedSwitcher(
      duration: duration,
      child: status == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              key: ValueKey(status),
              padding: below
                  ? EdgeInsets.only(top: space.md)
                  : EdgeInsets.only(bottom: space.md),
              child: HudaStatusBanner(
                status: status,
                message: date == null
                    ? null
                    : l10n.zakatPriceFailed(zakatPriceDay(context, date)),
                onRetry: onRetry,
              ),
            ),
    );
    // Reveal: the page eases aside for the banner instead of jumping
    // (instant under reduce motion, where a zero AnimatedSize throws).
    if (duration == Duration.zero) return switcher;
    return AnimatedSize(
      duration: duration,
      curve: motion.emphasized,
      alignment: Alignment.topCenter,
      child: switcher,
    );
  }
}

/// The day market prices are from, kept on one line ("Fri, Oct 30").
String zakatPriceDay(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateUtils.dateOnly(date)).replaceAll(' ', '\u00A0');
