import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/quran_home/quran_identity.dart';

class MemorizationCompletedDialog extends StatefulWidget {
  const MemorizationCompletedDialog({super.key});

  @override
  State<MemorizationCompletedDialog> createState() =>
      _MemorizationCompletedDialogState();
}

class _MemorizationCompletedDialogState
    extends State<MemorizationCompletedDialog> {
  bool _lit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HudaHaptics.medium(context);
      setState(() => _lit = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('quran-memorized'),
      icon: Semantics(
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: _lit ? 1 : 0),
                duration: context.tokens.motion.of(
                  context,
                  context.tokens.motion.long,
                ),
                builder: (context, lit, _) => CustomPaint(
                  size: const Size.square(72),
                  painter: QuranRosettePainter(
                    color: theme.colorScheme.tertiary,
                    fill: theme.colorScheme.surface,
                    lit: lit,
                    stroke: 1.6,
                  ),
                ),
              ),
              Icon(
                Icons.check_rounded,
                size: 32,
                color: _lit
                    ? theme.colorScheme.surface
                    : theme.colorScheme.tertiary,
              ),
            ],
          ),
        ),
      ),
      title: Text(l10n.congratsMessage2, textAlign: TextAlign.center),
      content: Padding(
        padding: EdgeInsets.only(top: space.xs),
        child: Text(
          l10n.surahMemorized,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
