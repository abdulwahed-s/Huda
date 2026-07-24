import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/themes/prayer_today/prayer_today_motion.dart';

class PrayerTodayHeaderSection extends StatelessWidget {
  const PrayerTodayHeaderSection({
    super.key,
    required this.onCustomize,
    required this.entranceAnimation,
  });

  final VoidCallback onCustomize;
  final Animation<double> entranceAnimation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  label: l10n.huda,
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.13),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Image.asset(
                              'assets/images/huda.png',
                              key: const ValueKey('prayer-home-app-mark'),
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            l10n.huda,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const ValueKey('prayer-home-customize'),
                tooltip: l10n.customizeHome,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onCustomize();
                },
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(48),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  hoverColor: Colors.white.withValues(alpha: 0.18),
                  focusColor: Colors.white.withValues(alpha: 0.16),
                  highlightColor: Colors.white.withValues(alpha: 0.14),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      key: const ValueKey('prayer-home-header-section'),
      container: true,
      explicitChildNodes: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? content
          : AnimatedBuilder(
              animation: entranceAnimation,
              child: content,
              builder: (context, child) {
                final value = PrayerTodayMotion.phase(
                  entranceAnimation.value,
                  begin: 0,
                  end: 0.24,
                );
                return Opacity(
                  opacity: 0.72 + value * 0.28,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 2),
                    child: child,
                  ),
                );
              },
            ),
    );
  }
}
