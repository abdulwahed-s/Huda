import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_row.dart';

void showTasbihResetDialog(BuildContext context) {
  final cubit = context.read<TasbihCubit>();
  final state = cubit.state;
  if (state is! TasbihLoaded || state.notes.isEmpty) return;
  final size = MediaQuery.sizeOf(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  showDialog<void>(
    context: context,
    barrierColor: context.tokens.chrome.withValues(alpha: 0.6),
    anchorPoint: Offset(rtl ? 0 : size.width, size.height),
    builder: (dialogContext) => Padding(
      padding: SideChrome.clearance(dialogContext),
      child: TasbihResetDialog(
        note: state.notes[state.selectedNoteIndex],
        onReset: () {
          cubit.reset();
          HudaHaptics.light(dialogContext, enabled: state.mode);
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}

class TasbihResetDialog extends StatelessWidget {
  const TasbihResetDialog({
    super.key,
    required this.note,
    required this.onReset,
  });

  final TasbihNote note;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final count = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Text(
        '${note.count}',
        textAlign: TextAlign.center,
        style: context.type.counter.copyWith(
          fontSize: 44,
          height: 1.1,
          color: scheme.onSurface,
        ),
      ),
    );

    final words = Text(
      note.text,
      textAlign: TextAlign.center,
      textDirection: tasbihTextDirection(note.text),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: tasbihDhikrTitleStyle(
        context,
        note.text,
      ).copyWith(color: scheme.onSurface),
    );

    final cancel = OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(l10n.cancel, textAlign: TextAlign.center),
    );
    final reset = FilledButton(
      onPressed: onReset,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: scheme.errorContainer,
        foregroundColor: scheme.onErrorContainer,
        shape: RoundedRectangleBorder(borderRadius: tokens.radius.control),
      ),
      child: Text(l10n.reset, textAlign: TextAlign.center),
    );

    final buttons = LayoutBuilder(
      builder: (context, constraints) {
        final style = text.labelLarge!;
        final scaler = MediaQuery.textScalerOf(context);
        double label(String s) => (TextPainter(
          text: TextSpan(text: s, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout()).width;
        final widest = [l10n.cancel, l10n.reset].map(label).reduce(math.max);
        if ((constraints.maxWidth - space.sm) / 2 >= widest + 2 * space.xl) {
          return Row(
            children: [
              Expanded(child: cancel),
              SizedBox(width: space.sm),
              Expanded(child: reset),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            reset,
            SizedBox(height: space.xs),
            cancel,
          ],
        );
      },
    );
    final title = Text(
      l10n.resetCounter,
      textAlign: TextAlign.center,
      style: text.titleLarge?.copyWith(color: scheme.onSurface),
    );
    final message = Text(
      l10n.tasbihResetMessage,
      textAlign: TextAlign.center,
      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    );

    final subject = Container(
      padding: EdgeInsets.symmetric(horizontal: space.md, vertical: space.sm),
      decoration: ShapeDecoration(
        color: tokens.onChrome.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: tokens.radius.card,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          count,
          SizedBox(height: space.xxs),
          words,
        ],
      ),
    );

    final short = context.windowClass.isCompactHeight;
    final Widget body = short
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 168,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [subject],
                ),
              ),
              SizedBox(width: space.xl),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    SizedBox(height: space.xs),
                    message,
                    SizedBox(height: space.lg),
                    buttons,
                  ],
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              subject,
              SizedBox(height: space.lg),
              title,
              SizedBox(height: space.xs),
              message,
              SizedBox(height: space.xl),
              buttons,
            ],
          );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: space.xxl,
        vertical: short ? space.md : space.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: short ? 600 : 400),
        child: SingleChildScrollView(
          padding: short
              ? EdgeInsets.all(space.lg)
              : EdgeInsets.fromLTRB(space.xl, space.xl, space.xl, space.lg),
          child: body,
        ),
      ),
    );
  }
}
