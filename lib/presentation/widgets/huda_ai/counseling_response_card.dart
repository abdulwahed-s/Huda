import 'package:flutter/material.dart';

class CounselingResponseCard extends StatelessWidget {
  final int index;
  final String title;
  final String content;
  final String? subContent;
  final IconData icon;
  final List<Color> gradientColors;
  final String? footer;
  final bool isDark;

  const CounselingResponseCard({
    super.key,
    required this.index,
    required this.title,
    required this.content,
    this.subContent,
    required this.icon,
    required this.gradientColors,
    this.footer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    gradientColors[0].withValues(alpha: 0.2),
                    gradientColors[1].withValues(alpha: 0.1),
                  ]
                : [
                    gradientColors[0].withValues(alpha: 0.05),
                    gradientColors[1].withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {}, // Makes it feel interactive
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Decorative line
                    Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Main content
                    Text(
                      content,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            fontSize: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                            letterSpacing: 0.2,
                          ),
                    ),
                    // Translation / subcontent
                    if (subContent != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gradientColors[0].withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: 20,
                              color: gradientColors[0].withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subContent!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      height: 1.7,
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Footer reference
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  gradientColors[0].withValues(alpha: 0.15),
                                  gradientColors[1].withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              footer!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: gradientColors[0],
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
