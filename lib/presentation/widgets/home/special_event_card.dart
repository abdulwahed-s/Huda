import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/islamic_event_config.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/event_decoration_painter.dart';
import 'package:huda/presentation/widgets/home/islamic_pattern_painter.dart';

class EventPalette {
  final List<Color> gradient;
  final Color accent;
  final Color glow;
  final Color text;
  final Color subtitle;
  final Color border;
  final Color shadow;
  final Color pattern;
  final IconData icon;

  const EventPalette({
    required this.gradient,
    required this.accent,
    required this.glow,
    required this.text,
    required this.subtitle,
    required this.border,
    required this.shadow,
    required this.pattern,
    required this.icon,
  });

  static EventPalette forEvent(String eventKey, bool dark) {
    return switch (eventKey) {
      'ramadan' => dark
          ? const EventPalette(
              gradient: [Color(0xFF0D0D30), Color(0xFF1A1A50), Color(0xFF141445)],
              accent: Color(0xFFD4AF37),
              glow: Color(0xFFE8D5A0),
              text: Color(0xFFF5F0E8),
              subtitle: Color(0xFFCDC4B0),
              border: Color(0xFF33336B),
              shadow: Color(0x401A1A4E),
              pattern: Color(0x0AD4AF37),
              icon: Icons.nightlight_round,
            )
          : const EventPalette(
              gradient: [Color(0xFFF8F4EC), Color(0xFFF0E8D8), Color(0xFFF5F0E8)],
              accent: Color(0xFF8B7532),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF1A1A50),
              subtitle: Color(0xFF4A4A70),
              border: Color(0xFFE0D8C8),
              shadow: Color(0x20806830),
              pattern: Color(0x088B7532),
              icon: Icons.nightlight_round,
            ),
      'last_ten_ramadan' => dark
          ? const EventPalette(
              gradient: [Color(0xFF080825), Color(0xFF151545), Color(0xFF0E0E3A)],
              accent: Color(0xFFE8C84C),
              glow: Color(0xFFF0DCA0),
              text: Color(0xFFF5F0E8),
              subtitle: Color(0xFFCDC4B0),
              border: Color(0xFF2A2A60),
              shadow: Color(0x40151545),
              pattern: Color(0x0AE8C84C),
              icon: Icons.nights_stay,
            )
          : const EventPalette(
              gradient: [Color(0xFFF5F2EA), Color(0xFFEDE4D0), Color(0xFFF2EDE2)],
              accent: Color(0xFF7A6528),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF151545),
              subtitle: Color(0xFF3A3A60),
              border: Color(0xFFDDD5C2),
              shadow: Color(0x207A6528),
              pattern: Color(0x087A6528),
              icon: Icons.nights_stay,
            ),
      'eid_al_fitr' => dark
          ? const EventPalette(
              gradient: [Color(0xFF0D2818), Color(0xFF1A4428), Color(0xFF143520)],
              accent: Color(0xFFFFD700),
              glow: Color(0xFFB8E4B8),
              text: Color(0xFFF0FAF0),
              subtitle: Color(0xFFB8D8B8),
              border: Color(0xFF2A5A38),
              shadow: Color(0x401A4428),
              pattern: Color(0x0AFFD700),
              icon: Icons.auto_awesome,
            )
          : const EventPalette(
              gradient: [Color(0xFFF0F7F0), Color(0xFFE4F0E4), Color(0xFFF0F7F0)],
              accent: Color(0xFF2E7D32),
              glow: Color(0xFF4CAF50),
              text: Color(0xFF1B5E20),
              subtitle: Color(0xFF388E3C),
              border: Color(0xFFD0E8D0),
              shadow: Color(0x202E7D32),
              pattern: Color(0x082E7D32),
              icon: Icons.auto_awesome,
            ),
      'eid_al_adha' => dark
          ? const EventPalette(
              gradient: [Color(0xFF250D18), Color(0xFF4A1A30), Color(0xFF3A1425)],
              accent: Color(0xFFE8B923),
              glow: Color(0xFFF0D080),
              text: Color(0xFFF5EEF0),
              subtitle: Color(0xFFD0B8C0),
              border: Color(0xFF5A2A40),
              shadow: Color(0x404A1A30),
              pattern: Color(0x0AE8B923),
              icon: Icons.mosque,
            )
          : const EventPalette(
              gradient: [Color(0xFFF8F0F2), Color(0xFFF0E4E8), Color(0xFFF5EEF0)],
              accent: Color(0xFF8B3A50),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF4A1A30),
              subtitle: Color(0xFF6A3A50),
              border: Color(0xFFE8D4D8),
              shadow: Color(0x208B3A50),
              pattern: Color(0x088B3A50),
              icon: Icons.mosque,
            ),
      'day_of_arafah' => dark
          ? const EventPalette(
              gradient: [Color(0xFF2A1A0D), Color(0xFF4A3018), Color(0xFF3A2512)],
              accent: Color(0xFFF4C430),
              glow: Color(0xFFF8E090),
              text: Color(0xFFF8F0E8),
              subtitle: Color(0xFFD4C0A8),
              border: Color(0xFF5A4028),
              shadow: Color(0x404A3018),
              pattern: Color(0x0AF4C430),
              icon: Icons.terrain,
            )
          : const EventPalette(
              gradient: [Color(0xFFF8F2E8), Color(0xFFF0E4D0), Color(0xFFF5EEE2)],
              accent: Color(0xFF8B6520),
              glow: Color(0xFFD4A020),
              text: Color(0xFF3A2510),
              subtitle: Color(0xFF6A5030),
              border: Color(0xFFE8DCC8),
              shadow: Color(0x208B6520),
              pattern: Color(0x088B6520),
              icon: Icons.terrain,
            ),
      'first_ten_dhul_hijjah' => dark
          ? const EventPalette(
              gradient: [Color(0xFF2A1F0D), Color(0xFF4A3A18), Color(0xFF3A2E12)],
              accent: Color(0xFFFFB74D),
              glow: Color(0xFFFFD89B),
              text: Color(0xFFF8F4E8),
              subtitle: Color(0xFFD4C8A8),
              border: Color(0xFF5A4A28),
              shadow: Color(0x404A3A18),
              pattern: Color(0x0AFFB74D),
              icon: Icons.wb_sunny_outlined,
            )
          : const EventPalette(
              gradient: [Color(0xFFF8F4E8), Color(0xFFF0E8D0), Color(0xFFF5F0E2)],
              accent: Color(0xFF8B6B20),
              glow: Color(0xFFD4A830),
              text: Color(0xFF3A2E10),
              subtitle: Color(0xFF6A5830),
              border: Color(0xFFE8E0C8),
              shadow: Color(0x208B6B20),
              pattern: Color(0x088B6B20),
              icon: Icons.wb_sunny_outlined,
            ),
      'ashura' => dark
          ? const EventPalette(
              gradient: [Color(0xFF0D1A25), Color(0xFF1A3045), Color(0xFF14253A)],
              accent: Color(0xFF85C1E9),
              glow: Color(0xFFB0D8F0),
              text: Color(0xFFF0F5F8),
              subtitle: Color(0xFFB0C8D8),
              border: Color(0xFF2A4055),
              shadow: Color(0x401A3045),
              pattern: Color(0x0A85C1E9),
              icon: Icons.brightness_7,
            )
          : const EventPalette(
              gradient: [Color(0xFFF0F5F8), Color(0xFFE0ECF4), Color(0xFFF0F5F8)],
              accent: Color(0xFF1A5276),
              glow: Color(0xFF2980B9),
              text: Color(0xFF0D2A3A),
              subtitle: Color(0xFF2A5070),
              border: Color(0xFFD0E0E8),
              shadow: Color(0x201A5276),
              pattern: Color(0x081A5276),
              icon: Icons.brightness_7,
            ),
      'days_of_tashreeq' => dark
          ? const EventPalette(
              gradient: [Color(0xFF0D2218), Color(0xFF1A3E30), Color(0xFF143225)],
              accent: Color(0xFFD4A853),
              glow: Color(0xFFE8D090),
              text: Color(0xFFF0F5F0),
              subtitle: Color(0xFFB8CDB8),
              border: Color(0xFF2A4E38),
              shadow: Color(0x401A3E30),
              pattern: Color(0x0AD4A853),
              icon: Icons.celebration,
            )
          : const EventPalette(
              gradient: [Color(0xFFF2F7F2), Color(0xFFE4F0E4), Color(0xFFF2F7F2)],
              accent: Color(0xFF3A6B2A),
              glow: Color(0xFF5A9A4A),
              text: Color(0xFF1A3A12),
              subtitle: Color(0xFF3A5A30),
              border: Color(0xFFD0E0D0),
              shadow: Color(0x203A6B2A),
              pattern: Color(0x083A6B2A),
              icon: Icons.celebration,
            ),
      _ => const EventPalette(
          gradient: [Color(0xFF1A1A2E), Color(0xFF2A2A4E), Color(0xFF1E1E3E)],
          accent: Color(0xFFD4AF37),
          glow: Color(0xFFE8D5A0),
          text: Color(0xFFF5F0E8),
          subtitle: Color(0xFFCDC4B0),
          border: Color(0xFF3A3A5E),
          shadow: Color(0x402A2A4E),
          pattern: Color(0x0AD4AF37),
          icon: Icons.star,
        ),
    };
  }
}

class SpecialEventCard extends StatefulWidget {
  final IslamicEventConfig event;
  final bool isDarkMode;
  final VoidCallback onTap;

  const SpecialEventCard({
    super.key,
    required this.event,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<SpecialEventCard> createState() => _SpecialEventCardState();
}

class _SpecialEventCardState extends State<SpecialEventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        EventPalette.forEvent(widget.event.eventKey, widget.isDarkMode);
    final radius = BorderRadius.circular(20.r);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) {
        return Transform.scale(
          scale: 0.92 + 0.08 * v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.gradient,
                  ),
                  borderRadius: radius,
                  border: Border.all(color: palette.border, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: IslamicPatternPainter(
                            patternColor: palette.pattern,
                            tileSize: 55,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: EventDecorationPainter(
                            eventKey: widget.event.eventKey,
                            animValue: _anim.value,
                            accentColor: palette.accent,
                            glowColor: palette.glow,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(
                            mobile: 22.w,
                            tablet: 28.w,
                            desktop: 36.w,
                          ),
                          vertical: context.responsive(
                            mobile: 20.w,
                            tablet: 24.w,
                            desktop: 30.w,
                          ),
                        ),
                        child: _buildContent(context, palette),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventPalette palette) {
    final titleSize = context.responsive(
      mobile: 18.sp,
      tablet: 22.sp,
      desktop: 26.sp,
    );
    final subtitleSize = context.responsive(
      mobile: 12.sp,
      tablet: 14.sp,
      desktop: 16.sp,
    );
    final iconSize = context.responsive(
      mobile: 26.sp,
      tablet: 34.sp,
      desktop: 42.sp,
    );
    final iconContainer = context.responsive(
      mobile: 50.w,
      tablet: 62.w,
      desktop: 74.w,
    );

    return Row(
      children: [
        Container(
          width: iconContainer,
          height: iconContainer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.accent.withValues(alpha: 0.12),
            border: Border.all(
              color: palette.accent.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Icon(palette.icon, size: iconSize, color: palette.accent),
        ),
        SizedBox(width: 18.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getEventTitle(context, widget.event.eventKey),
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                  fontFamily: "Amiri",
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _getEventSubtitle(context, widget.event.eventKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: palette.subtitle,
                  fontFamily: "Amiri",
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _getEventTitle(BuildContext context, String eventKey) {
    final l10n = AppLocalizations.of(context)!;
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadan,
      'last_ten_ramadan' => l10n.eventLastTenRamadan,
      'eid_al_fitr' => l10n.eventEidAlFitr,
      'eid_al_adha' => l10n.eventEidAlAdha,
      'day_of_arafah' => l10n.eventDayOfArafah,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjah,
      'ashura' => l10n.eventAshura,
      'days_of_tashreeq' => l10n.eventDaysTashreeq,
      _ => eventKey,
    };
  }

  static String _getEventSubtitle(BuildContext context, String eventKey) {
    final l10n = AppLocalizations.of(context)!;
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadanSubtitle,
      'last_ten_ramadan' => l10n.eventLastTenRamadanSubtitle,
      'eid_al_fitr' => l10n.eventEidAlFitrSubtitle,
      'eid_al_adha' => l10n.eventEidAlAdhaSubtitle,
      'day_of_arafah' => l10n.eventDayOfArafahSubtitle,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjahSubtitle,
      'ashura' => l10n.eventAshuraSubtitle,
      'days_of_tashreeq' => l10n.eventDaysTashreeqSubtitle,
      _ => '',
    };
  }
}
