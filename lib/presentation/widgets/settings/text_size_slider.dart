import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:intl/intl.dart' show NumberFormat;

class TextSizeControl extends StatelessWidget {
  const TextSizeControl({super.key});

  static const double _min = 0.5;
  static const double _max = 2.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scale = context.select<ThemeCubit, double>(
      (cubit) => cubit.state.textScaleFactor,
    );
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    final value = percent.format(scale);
    final isDefault = (scale - 1).abs() < 0.001;
    final muted = scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.textSize, style: theme.textTheme.titleSmall),
                  SizedBox(height: space.xxs),
                  Text(
                    l10n.settingsTextSizeRelative,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            SizedBox(width: space.sm),
            Text(
              value,
              key: const ValueKey('settings-text-size-value'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: space.xs),
        Row(
          children: [
            ExcludeSemantics(
              child: Text(
                'A',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelMedium?.copyWith(color: muted),
              ),
            ),
            Expanded(
              child: Slider(
                key: const ValueKey('settings-text-size'),
                value: scale.clamp(_min, _max),
                min: _min,
                max: _max,
                divisions: 30,
                label: value,
                semanticFormatterCallback: (v) => percent.format(v),
                onChanged: (next) {
                  HudaHaptics.selection(context);
                  context.read<ThemeCubit>().setTextScaleFactor(next);
                },
              ),
            ),
            ExcludeSemantics(
              child: Text(
                'A',
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleLarge?.copyWith(color: muted),
              ),
            ),
          ],
        ),
        SizedBox(height: space.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: space.md,
            vertical: space.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            l10n.sampleTextPreview,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        HudaAnimatedSize(
          alignment: AlignmentDirectional.topStart,
          child: isDefault
              ? const SizedBox(width: double.infinity)
              : Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: EdgeInsets.only(top: space.xs),
                    child: TextButton.icon(
                      key: const ValueKey('settings-text-size-reset'),
                      onPressed: () {
                        HudaHaptics.light(context);
                        context.read<ThemeCubit>().setTextScaleFactor(1.0);
                      },
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(l10n.reset),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
