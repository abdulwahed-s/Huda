import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';

class CounselingSkeleton extends StatefulWidget {
  final bool isDark;

  const CounselingSkeleton({super.key, required this.isDark});

  @override
  State<CounselingSkeleton> createState() => _CounselingSkeletonState();
}

class _CounselingSkeletonState extends State<CounselingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSkeletonCard(
          context,
          title: AppLocalizations.of(context)!.guidance,
          lines: 5,
          icon: Icons.light_mode,
          gradientColors: const [Color(0xFF00897B), Color(0xFF00BFA5)],
        ),
        const SizedBox(height: 20),
        _buildSkeletonCard(
          context,
          title: AppLocalizations.of(context)!.quranicWisdom,
          lines: 3,
          hasSubContent: true,
          icon: Icons.menu_book,
          gradientColors: const [Color(0xFF3949AB), Color(0xFF5E35B1)],
        ),
        const SizedBox(height: 20),
        _buildSkeletonCard(
          context,
          title: AppLocalizations.of(context)!.duaa,
          lines: 2,
          hasSubContent: true,
          icon: Icons.favorite,
          gradientColors: const [Color(0xFFC2185B), Color(0xFFD81B60)],
        ),
        const SizedBox(height: 20),
        _buildActionButtonsSkeleton(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSkeletonCard(
    BuildContext context, {
    required String title,
    required int lines,
    bool hasSubContent = false,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final baseColor = widget.isDark ? Colors.white : Colors.black;
    final cardBgColor = widget.isDark
        ? [
            gradientColors[0].withValues(alpha: 0.2),
            gradientColors[1].withValues(alpha: 0.1),
          ]
        : [
            gradientColors[0].withValues(alpha: 0.05),
            gradientColors[1].withValues(alpha: 0.03),
          ];

    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: cardBgColor,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
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
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
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
              // Skeleton Lines
              ...List.generate(
                lines,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 16,
                  width: index == lines - 1 ? 200 : double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Subcontent Skeleton
              if (hasSubContent) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gradientColors[0].withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildSkeletonButton(),
          SizedBox(width: 8.w),
          _buildSkeletonButton(),
        ],
      ),
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(38),
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
