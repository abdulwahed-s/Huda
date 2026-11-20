import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/zakat_calculator/zakat_calculator_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/feature_identity.dart';
import 'package:huda/presentation/widgets/design/ornament/ornaments.dart';

final FeatureIdentity zakatIdentity = FeatureIdentity(
  id: 'zakat',
  motif: 'A mizan: wealth against the nisab, its tongue over a graduated arc',
  count: 2,
  rhythm: IdentityRhythm.single,
  material: IdentityMaterial.brass,
  headerArt: (style) => ZakatMizanPainter(style: style, tilt: 0),
);

const double zakatMaxTilt = 9 * math.pi / 180;

double zakatBalance(double wealth, double nisab) {
  final total = wealth + nisab;
  if (total <= 0) return 0;
  return ((wealth - nisab) / total).clamp(-1.0, 1.0);
}

abstract final class ZakatAmounts {
  static final NumberFormat _format = NumberFormat('#,##0.00', 'en_US');

  static String format(String currency, double value) =>
      '$currency\u00A0${_format.format(value)}';

  static String digits(double value) => _format.format(value);

  static int cents(double value) => (value * 100).round();

  static String field(double value) {
    if (value <= 0) return '';
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }
}

const List<AssetCategory> zakatAssetCategories = [
  AssetCategory.cash,
  AssetCategory.gold,
  AssetCategory.silver,
  AssetCategory.business,
  AssetCategory.investments,
  AssetCategory.receivables,
];

extension ZakatCategoryText on AssetCategory {
  String title(AppLocalizations l10n) => switch (this) {
    AssetCategory.cash => l10n.cashAndBankBalances,
    AssetCategory.gold => l10n.goldAssets,
    AssetCategory.silver => l10n.silverAssets,
    AssetCategory.business => l10n.businessAssets,
    AssetCategory.investments => l10n.investmentsAssets,
    AssetCategory.receivables => l10n.moneyOwedToYou,
    AssetCategory.debts => l10n.debtsAndLiabilities,
  };

  String description(AppLocalizations l10n) => switch (this) {
    AssetCategory.cash => l10n.cashDescription,
    AssetCategory.gold => l10n.goldDescription,
    AssetCategory.silver => l10n.silverDescription,
    AssetCategory.business => l10n.businessDescription,
    AssetCategory.investments => l10n.investmentsDescription,
    AssetCategory.receivables => l10n.receivablesDescription,
    AssetCategory.debts => l10n.debtsDescription,
  };

  IconData get icon => switch (this) {
    AssetCategory.cash => Icons.payments_rounded,
    AssetCategory.gold => Icons.workspace_premium_rounded,
    AssetCategory.silver => Icons.toll_rounded,
    AssetCategory.business => Icons.storefront_rounded,
    AssetCategory.investments => Icons.show_chart_rounded,
    AssetCategory.receivables => Icons.call_received_rounded,
    AssetCategory.debts => Icons.receipt_long_rounded,
  };
}

extension ZakatNisabText on NisabType {
  String metal(AppLocalizations l10n) =>
      this == NisabType.gold ? l10n.gold : l10n.silver;

  String weight(AppLocalizations l10n) =>
      this == NisabType.gold ? l10n.goldGrams : l10n.silverGrams;
}

class ZakatMizanPainter extends CustomPainter {
  const ZakatMizanPainter({
    required this.style,
    required this.tilt,
    this.heavyColor,
    this.wealthColor,
  });

  final OrnamentStyle style;
  final double tilt;

  final Color? heavyColor;

  final Color? wealthColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final unit = math.min(w / 1.6, h);
    final origin = Offset((w - unit * 1.6) / 2, (h - unit) / 2);
    Offset at(double x, double y) => origin + Offset(x * unit, y * unit);

    final line = style.line;
    final fine = style.line..strokeWidth = style.stroke * 0.75;
    final pivot = at(0.8, 0.2);
    final angle = tilt * zakatMaxTilt;

    final arcRadius = unit * 0.15;
    for (var i = -4; i <= 4; i++) {
      final a = -math.pi / 2 + i * (math.pi / 24);
      final inner = arcRadius * (i == 0 ? 0.72 : 0.84);
      canvas.drawLine(
        pivot + Offset(math.cos(a), math.sin(a)) * inner,
        pivot + Offset(math.cos(a), math.sin(a)) * arcRadius,
        fine,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: arcRadius),
      -math.pi / 2 - math.pi / 6,
      math.pi / 3,
      false,
      fine,
    );

    final foot = at(0.8, 0.93);
    canvas
      ..drawLine(pivot, foot - Offset(0, unit * 0.05), line)
      ..drawLine(
        foot - Offset(unit * 0.1, unit * 0.05),
        foot + Offset(unit * 0.1, -unit * 0.05),
        line,
      )
      ..drawLine(
        foot - Offset(unit * 0.16, 0),
        foot + Offset(unit * 0.16, 0),
        line,
      )
      ..drawLine(at(0.05, 0.93), at(0.6, 0.93), fine)
      ..drawLine(at(1.0, 0.93), at(1.55, 0.93), fine);

    final reach = unit * 0.6;
    final dir = Offset(math.cos(angle), -math.sin(angle));
    final start = pivot - dir * reach;
    final end = pivot + dir * reach;
    canvas.drawLine(start, end, line..strokeWidth = style.stroke * 1.4);
    final tongue = Offset(math.sin(angle), math.cos(angle));
    final tip = pivot - tongue * (unit * 0.13);
    final tonguePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        pivot.dx + dir.dx * unit * 0.018,
        pivot.dy + dir.dy * unit * 0.018,
      )
      ..lineTo(
        pivot.dx - dir.dx * unit * 0.018,
        pivot.dy - dir.dy * unit * 0.018,
      )
      ..close();
    canvas
      ..drawPath(tonguePath, style.fill())
      ..drawCircle(pivot, unit * 0.028, style.fill())
      ..drawCircle(pivot, unit * 0.045, fine);

    void pan(Offset hook, {required bool wealth}) {
      final down = wealth ? tilt > 0.02 : tilt < -0.02;
      final color = wealth ? (wealthColor ?? style.color) : style.color;
      final drop = unit * 0.4;
      final half = unit * 0.2;
      final rim = hook + Offset(0, drop);
      final bowl = Path()
        ..moveTo(rim.dx - half, rim.dy)
        ..quadraticBezierTo(rim.dx, rim.dy + unit * 0.16, rim.dx + half, rim.dy)
        ..close();
      final chain = style.line
        ..strokeWidth = style.stroke * 0.75
        ..color = color;
      canvas
        ..drawLine(hook, rim - Offset(half, 0), chain)
        ..drawLine(hook, rim + Offset(half, 0), chain)
        ..drawCircle(hook, unit * 0.02, chain);
      final heavy = heavyColor;
      if (down && heavy != null) {
        canvas.drawPath(bowl, Paint()..color = heavy);
      }
      canvas.drawPath(
        bowl,
        style.line
          ..strokeWidth = style.stroke * 1.2
          ..color = color,
      );
    }

    pan(start, wealth: true);
    pan(end, wealth: false);
  }

  @override
  bool shouldRepaint(ZakatMizanPainter old) =>
      old.tilt != tilt ||
      old.style != style ||
      old.heavyColor != heavyColor ||
      old.wealthColor != wealthColor;
}

class ZakatSettleCurve extends Curve {
  const ZakatSettleCurve();

  @override
  double transformInternal(double t) {
    final rest = 1 - t;
    return 1 - rest * rest * rest * math.cos(2.5 * math.pi * t);
  }
}

class ZakatBalance extends StatelessWidget {
  const ZakatBalance({
    super.key,
    required this.wealth,
    required this.nisab,
    required this.due,
    this.semanticLabel,
  });

  final double wealth;
  final double nisab;
  final bool due;
  final String? semanticLabel;

  static const Duration settle = Duration(milliseconds: 1000);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final style = OrnamentStyle.of(context);
    final target = zakatBalance(wealth, nisab);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final duration = tokens.motion.of(context, settle);
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: duration == Duration.zero ? target : 0,
            end: target,
          ),
          duration: duration,
          curve: const ZakatSettleCurve(),
          builder: (context, tilt, _) => Transform.flip(
            flipX: rtl,
            child: CustomPaint(
              size: Size.infinite,
              painter: ZakatMizanPainter(
                style: style,
                tilt: tilt,
                wealthColor: due ? scheme.primary : null,
                heavyColor: (due ? scheme.primary : tokens.ornament).withValues(
                  alpha: 0.22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ZakatCountUp extends StatelessWidget {
  const ZakatCountUp({
    super.key,
    required this.value,
    required this.currency,
    this.style,
  });

  final double value;
  final String currency;
  final TextStyle? style;

  static const Duration count = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final motion = context.tokens.motion;
    final duration = motion.of(context, count);
    final text = ZakatAmounts.format(currency, value);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: duration == Duration.zero ? value : 0, end: value),
        duration: duration,
        curve: motion.standard,
        builder: (context, shown, _) => Text(
          ZakatAmounts.format(currency, shown),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          style: (style ?? DefaultTextStyle.of(context).style).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
