import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

class RamadanPlateSkeleton extends StatelessWidget {
  const RamadanPlateSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    return HudaSkeleton(
      child: Container(
        padding: EdgeInsets.all(space.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: tokens.radius.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const HudaSkeletonBlock(width: 76, height: 76, circle: true),
                SizedBox(width: space.lg),
                Expanded(
                  child: HudaSkeletonLines(
                    lines: 2,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: space.xxl),
            HudaSkeletonLines(lines: 2, style: theme.textTheme.titleLarge),
            SizedBox(height: space.sm),
            const HudaSkeletonBlock(height: 8),
          ],
        ),
      ),
    );
  }
}

class RamadanNightsSkeleton extends StatelessWidget {
  const RamadanNightsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    final theme = Theme.of(context);
    return HudaSkeleton(
      announce: false,
      child: HudaCard(
        padding: EdgeInsets.all(space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FractionallySizedBox(
              widthFactor: 0.5,
              child: HudaSkeletonLines(
                lines: 2,
                style: theme.textTheme.titleMedium,
              ),
            ),
            SizedBox(height: space.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth / 10 >= 50 ? 10 : 6;
                final tile =
                    (constraints.maxWidth - space.xxs * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: space.xxs,
                  runSpacing: space.sm,
                  children: [
                    for (var i = 0; i < 30; i++)
                      SizedBox(
                        width: tile,
                        child: const Center(
                          child: HudaSkeletonBlock(
                            width: 26,
                            height: 26,
                            circle: true,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
