import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_identity.dart';
import 'package:huda/presentation/widgets/zakat_calculator/zakat_parts.dart';

bool zakatHasAmounts(ZakatCalculation calculation) =>
    calculation.assets.values.any((value) => value > 0);

class ZakatResultCard extends StatelessWidget {
  const ZakatResultCard({super.key, required this.state, this.compactHeight});

  final ZakatCalculatorLoaded state;

  final bool? compactHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final short = compactHeight ?? MediaQuery.sizeOf(context).height < 480;
    final calc = state.calculation;
    final empty = !zakatHasAmounts(calc);
    final currency = state.selectedCurrency;
    final balanceLabel = empty
        ? l10n.zakatEmptyTitle
        : '${calc.isZakatDue ? l10n.zakatIsDue : l10n.noZakatDue}. '
              '${l10n.netAssets}: ${ZakatAmounts.format(currency, calc.netAssets)}. '
              '${l10n.zakatNisab}: ${ZakatAmounts.format(currency, calc.nisabValue)}.';
    return HudaCard(
      padding: EdgeInsets.all(space.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final side =
              constraints.maxWidth >= (short ? 280 : 360) + 160 * scale;
          final balance = _Scale(
            state: state,
            height: short ? 104 : (side ? 156 : 132),
            label: balanceLabel,
          );
          final summary = _Summary(state: state, empty: empty);
          if (side) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: balance),
                SizedBox(width: space.xl),
                Expanded(flex: 6, child: summary),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              balance,
              SizedBox(height: space.md),
              summary,
            ],
          );
        },
      ),
    );
  }
}

class _Scale extends StatelessWidget {
  const _Scale({
    required this.state,
    required this.height,
    required this.label,
  });

  final ZakatCalculatorLoaded state;
  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final calc = state.calculation;
    final empty = !zakatHasAmounts(calc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: ZakatBalance(
            wealth: calc.netAssets,
            nisab: calc.nisabValue,
            due: calc.isZakatDue,
            semanticLabel: label,
          ),
        ),
        SizedBox(height: space.xs),
        ExcludeSemantics(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final pan = (constraints.maxWidth - space.xs) / 2;
              final stacked = scale > 1.3 || pan < 150;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PanLabel(
                      title: l10n.netAssets,
                      currency: state.selectedCurrency,
                      amount: empty ? null : calc.netAssets,
                      emphasized: calc.isZakatDue,
                      stacked: stacked,
                    ),
                  ),
                  SizedBox(width: space.xs),
                  Expanded(
                    child: _PanLabel(
                      title:
                          '${l10n.zakatNisab} · ${state.nisabType.metal(l10n)}',
                      currency: state.selectedCurrency,
                      amount: calc.nisabValue,
                      stacked: stacked,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PanLabel extends StatelessWidget {
  const _PanLabel({
    required this.title,
    required this.currency,
    this.amount,
    this.emphasized = false,
    this.stacked = false,
  });

  final String title;
  final String currency;

  final bool stacked;

  final double? amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amount = this.amount;
    final amountStyle = theme.textTheme.bodySmall?.copyWith(
      color: emphasized ? scheme.primary : scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (amount == null)
          Text('—', style: amountStyle)
        else if (stacked) ...[
          Text(currency, style: amountStyle),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ZakatAmounts.digits(amount),
              maxLines: 1,
              style: amountStyle,
            ),
          ),
        ] else
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ZakatAmounts.format(currency, amount),
              maxLines: 1,
              textDirection: TextDirection.ltr,
              style: amountStyle,
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.empty});

  final ZakatCalculatorLoaded state;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final calc = state.calculation;
    final currency = state.selectedCurrency;
    final due = calc.isZakatDue;
    final String headline;
    final String detail;
    if (empty) {
      headline = l10n.zakatEmptyTitle;
      detail = l10n.zakatEmptyMessage;
    } else if (due) {
      headline = l10n.zakatIsDue;
      detail =
          '${l10n.zakatRateOf(ZakatAmounts.format(currency, calc.netAssets))}\n'
          '${l10n.zakatAboveNisab(ZakatAmounts.format(currency, calc.netAssets - calc.nisabValue))}';
    } else {
      headline = l10n.noZakatDue;
      detail = l10n.zakatBelowNisab(
        ZakatAmounts.format(currency, calc.nisabValue - calc.netAssets),
      );
    }
    final amountStyle = theme.textTheme.displaySmall?.copyWith(
      color: due ? scheme.primary : scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaEyebrow(l10n.zakatDueLabel),
        SizedBox(height: space.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: ZakatCountUp(
            value: calc.zakatAmount,
            currency: currency,
            style: amountStyle,
          ),
        ),
        SizedBox(height: space.xs),
        _Headline(
          stateKey: (empty, due),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: due ? scheme.primary : scheme.onSurface,
                ),
              ),
              SizedBox(height: space.xxs),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: space.sm),
        ZakatPriceSource(
          state: state,
          prefix:
              '${state.nisabType.metal(l10n)} · ${l10n.zakatPerGram(ZakatAmounts.format(currency, state.nisabType == NisabType.gold ? state.goldPricePerGram : state.silverPricePerGram))}',
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.stateKey, required this.child});

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.tokens.motion;
    final duration = motion.of(context, motion.short);
    final keyed = KeyedSubtree(key: ValueKey(stateKey), child: child);
    if (duration == Duration.zero) return keyed;
    return AnimatedSize(
      duration: duration,
      curve: motion.standard,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: motion.standard,
        layoutBuilder: (current, _) => current ?? const SizedBox.shrink(),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: keyed,
      ),
    );
  }
}

class ZakatLedgerCard extends StatelessWidget {
  const ZakatLedgerCard({super.key, required this.state});

  final ZakatCalculatorLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final calc = state.calculation;
    final currency = state.selectedCurrency;
    String money(double v) => ZakatAmounts.format(currency, v);
    final parts = [
      for (final category in zakatAssetCategories)
        if ((calc.assets[category] ?? 0) > 0) category,
    ];
    final grow = context.tokens.motion.of(
      context,
      context.tokens.motion.medium,
    );
    final breakdown = parts.isEmpty
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: EdgeInsets.only(top: space.lg),
            child: _Breakdown(state: state, parts: parts),
          );
    return HudaCard(
      padding: EdgeInsets.symmetric(horizontal: space.lg, vertical: space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LedgerLine(label: l10n.totalAssets, amount: money(calc.totalAssets)),
          _LedgerLine(
            label: l10n.totalDebts,
            amount: '− ${money(calc.totalDebts)}',
          ),
          const _DoubleRule(),
          _LedgerLine(
            label: l10n.netAssets,
            amount: money(calc.netAssets),
            total: true,
          ),
          _LedgerLine(
            label: l10n.nisabThreshold(state.nisabType.metal(l10n)),
            amount: money(calc.nisabValue),
            muted: true,
          ),
          if (grow == Duration.zero)
            breakdown
          else
            AnimatedSize(
              duration: grow,
              curve: context.tokens.motion.standard,
              alignment: Alignment.topCenter,
              child: breakdown,
            ),
        ],
      ),
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({
    required this.label,
    required this.amount,
    this.total = false,
    this.muted = false,
  });

  final String label;
  final String amount;
  final bool total;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final space = context.tokens.space;
    final labelStyle =
        (total ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
            );
    final amountStyle = labelStyle?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: space.xs),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: space.md,
          children: [
            Text(label, style: labelStyle),
            Text(amount, style: amountStyle, textDirection: TextDirection.ltr),
          ],
        ),
      ),
    );
  }
}

class _DoubleRule extends StatelessWidget {
  const _DoubleRule();

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.ornament;
    final space = context.tokens.space;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: space.xxs),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: color),
          const SizedBox(height: 2),
          Divider(height: 1, thickness: 1, color: color),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.state, required this.parts});

  final ZakatCalculatorLoaded state;
  final List<AssetCategory> parts;

  static const _tints = [1.0, 0.72, 0.5, 0.36, 0.26, 0.18];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    final calc = state.calculation;
    final total = calc.totalAssets;
    Color tint(int i) => Color.alphaBlend(
      scheme.primary.withValues(alpha: _tints[i % _tints.length]),
      scheme.surface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaEyebrow(l10n.assetBreakdown, header: true),
        SizedBox(height: space.sm),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radius.sm),
            child: SizedBox(
              height: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: ((calc.assets[parts[i]] ?? 0) / total * 1000)
                          .round()
                          .clamp(1, 1000),
                      child: ColoredBox(color: tint(i)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: space.sm),
        for (var i = 0; i < parts.length; i++)
          MergeSemantics(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: space.xxs),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: tint(i),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: scheme.outline),
                    ),
                  ),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Text(
                      parts[i].title(l10n),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  SizedBox(width: space.xs),
                  Text(
                    '${((calc.assets[parts[i]] ?? 0) / total * 100).toStringAsFixed(1)}%'
                    ' · ${ZakatAmounts.format(state.selectedCurrency, calc.assets[parts[i]] ?? 0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
