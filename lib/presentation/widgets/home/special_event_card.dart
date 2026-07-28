import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/data/models/islamic_event_config.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/special_event/canonical_event_motif.dart';
import 'package:huda/presentation/widgets/home/special_event/ceremonial_event_reveal.dart';

class EventPalette {
  final List<Color> gradient;
  final Color accent;
  final Color glow;
  final Color text;
  final Color subtitle;
  final Color border;
  final Color shadow;
  final IconData icon;

  const EventPalette({
    required this.gradient,
    required this.accent,
    required this.glow,
    required this.text,
    required this.subtitle,
    required this.border,
    required this.shadow,
    required this.icon,
  });

  static EventPalette forEvent(String eventKey, bool dark) {
    return switch (eventKey) {
      'ramadan' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF0D0D30),
                Color(0xFF1A1A50),
                Color(0xFF141445)
              ],
              accent: Color(0xFFD4AF37),
              glow: Color(0xFFE8D5A0),
              text: Color(0xFFF5F0E8),
              subtitle: Color(0xFFCDC4B0),
              border: Color(0xFF33336B),
              shadow: Color(0x401A1A4E),
              icon: Icons.nightlight_round,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF8F4EC),
                Color(0xFFF0E8D8),
                Color(0xFFF5F0E8)
              ],
              accent: Color(0xFF8B7532),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF1A1A50),
              subtitle: Color(0xFF4A4A70),
              border: Color(0xFFE0D8C8),
              shadow: Color(0x20806830),
              icon: Icons.nightlight_round,
            ),
      'last_ten_ramadan' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF080825),
                Color(0xFF151545),
                Color(0xFF0E0E3A)
              ],
              accent: Color(0xFFE8C84C),
              glow: Color(0xFFF0DCA0),
              text: Color(0xFFF5F0E8),
              subtitle: Color(0xFFCDC4B0),
              border: Color(0xFF2A2A60),
              shadow: Color(0x40151545),
              icon: Icons.nights_stay,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF5F2EA),
                Color(0xFFEDE4D0),
                Color(0xFFF2EDE2)
              ],
              accent: Color(0xFF7A6528),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF151545),
              subtitle: Color(0xFF3A3A60),
              border: Color(0xFFDDD5C2),
              shadow: Color(0x207A6528),
              icon: Icons.nights_stay,
            ),
      'eid_al_fitr' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF0D2818),
                Color(0xFF1A4428),
                Color(0xFF143520)
              ],
              accent: Color(0xFFFFD700),
              glow: Color(0xFFB8E4B8),
              text: Color(0xFFF0FAF0),
              subtitle: Color(0xFFB8D8B8),
              border: Color(0xFF2A5A38),
              shadow: Color(0x401A4428),
              icon: Icons.auto_awesome,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF0F7F0),
                Color(0xFFE4F0E4),
                Color(0xFFF0F7F0)
              ],
              accent: Color(0xFF2E7D32),
              glow: Color(0xFF4CAF50),
              text: Color(0xFF1B5E20),
              subtitle: Color(0xFF388E3C),
              border: Color(0xFFD0E8D0),
              shadow: Color(0x202E7D32),
              icon: Icons.auto_awesome,
            ),
      'eid_al_adha' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF250D18),
                Color(0xFF4A1A30),
                Color(0xFF3A1425)
              ],
              accent: Color(0xFFE8B923),
              glow: Color(0xFFF0D080),
              text: Color(0xFFF5EEF0),
              subtitle: Color(0xFFD0B8C0),
              border: Color(0xFF5A2A40),
              shadow: Color(0x404A1A30),
              icon: Icons.mosque,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF8F0F2),
                Color(0xFFF0E4E8),
                Color(0xFFF5EEF0)
              ],
              accent: Color(0xFF8B3A50),
              glow: Color(0xFFD4AF37),
              text: Color(0xFF4A1A30),
              subtitle: Color(0xFF6A3A50),
              border: Color(0xFFE8D4D8),
              shadow: Color(0x208B3A50),
              icon: Icons.mosque,
            ),
      'day_of_arafah' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF2A1A0D),
                Color(0xFF4A3018),
                Color(0xFF3A2512)
              ],
              accent: Color(0xFFF4C430),
              glow: Color(0xFFF8E090),
              text: Color(0xFFF8F0E8),
              subtitle: Color(0xFFD4C0A8),
              border: Color(0xFF5A4028),
              shadow: Color(0x404A3018),
              icon: Icons.terrain,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF8F2E8),
                Color(0xFFF0E4D0),
                Color(0xFFF5EEE2)
              ],
              accent: Color(0xFF8B6520),
              glow: Color(0xFFD4A020),
              text: Color(0xFF3A2510),
              subtitle: Color(0xFF6A5030),
              border: Color(0xFFE8DCC8),
              shadow: Color(0x208B6520),
              icon: Icons.terrain,
            ),
      'first_ten_dhul_hijjah' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF2A1F0D),
                Color(0xFF4A3A18),
                Color(0xFF3A2E12)
              ],
              accent: Color(0xFFFFB74D),
              glow: Color(0xFFFFD89B),
              text: Color(0xFFF8F4E8),
              subtitle: Color(0xFFD4C8A8),
              border: Color(0xFF5A4A28),
              shadow: Color(0x404A3A18),
              icon: Icons.wb_sunny_outlined,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF8F4E8),
                Color(0xFFF0E8D0),
                Color(0xFFF5F0E2)
              ],
              accent: Color(0xFF8B6B20),
              glow: Color(0xFFD4A830),
              text: Color(0xFF3A2E10),
              subtitle: Color(0xFF6A5830),
              border: Color(0xFFE8E0C8),
              shadow: Color(0x208B6B20),
              icon: Icons.wb_sunny_outlined,
            ),
      'ashura' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF0D1A25),
                Color(0xFF1A3045),
                Color(0xFF14253A)
              ],
              accent: Color(0xFF85C1E9),
              glow: Color(0xFFB0D8F0),
              text: Color(0xFFF0F5F8),
              subtitle: Color(0xFFB0C8D8),
              border: Color(0xFF2A4055),
              shadow: Color(0x401A3045),
              icon: Icons.brightness_7,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF0F5F8),
                Color(0xFFE0ECF4),
                Color(0xFFF0F5F8)
              ],
              accent: Color(0xFF1A5276),
              glow: Color(0xFF2980B9),
              text: Color(0xFF0D2A3A),
              subtitle: Color(0xFF2A5070),
              border: Color(0xFFD0E0E8),
              shadow: Color(0x201A5276),
              icon: Icons.brightness_7,
            ),
      'days_of_tashreeq' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF0D2218),
                Color(0xFF1A3E30),
                Color(0xFF143225)
              ],
              accent: Color(0xFFD4A853),
              glow: Color(0xFFE8D090),
              text: Color(0xFFF0F5F0),
              subtitle: Color(0xFFB8CDB8),
              border: Color(0xFF2A4E38),
              shadow: Color(0x401A3E30),
              icon: Icons.celebration,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF2F7F2),
                Color(0xFFE4F0E4),
                Color(0xFFF2F7F2)
              ],
              accent: Color(0xFF3A6B2A),
              glow: Color(0xFF5A9A4A),
              text: Color(0xFF1A3A12),
              subtitle: Color(0xFF3A5A30),
              border: Color(0xFFD0E0D0),
              shadow: Color(0x203A6B2A),
              icon: Icons.celebration,
            ),
      'white_days_fasting' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF0C2130),
                Color(0xFF12364A),
                Color(0xFF102B3C),
              ],
              accent: Color(0xFFB9E7F2),
              glow: Color(0xFFF0D98A),
              text: Color(0xFFF2FAFC),
              subtitle: Color(0xFFC1D8DE),
              border: Color(0xFF24546A),
              shadow: Color(0x4012364A),
              icon: Icons.brightness_5_outlined,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF2F9FA),
                Color(0xFFE2F0F2),
                Color(0xFFF4F8F5),
              ],
              accent: Color(0xFF24758A),
              glow: Color(0xFFDFC15F),
              text: Color(0xFF163743),
              subtitle: Color(0xFF426570),
              border: Color(0xFFC8E0E2),
              shadow: Color(0x2024758A),
              icon: Icons.brightness_5_outlined,
            ),
      'monday_thursday_fasting' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF12251F),
                Color(0xFF1D4235),
                Color(0xFF17352B),
              ],
              accent: Color(0xFFCDE9A4),
              glow: Color(0xFFF0CC75),
              text: Color(0xFFF5FAEE),
              subtitle: Color(0xFFCBDCC0),
              border: Color(0xFF315B4A),
              shadow: Color(0x401D4235),
              icon: Icons.wb_twilight_outlined,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF6FAF1),
                Color(0xFFE7F0DC),
                Color(0xFFF7F8EE),
              ],
              accent: Color(0xFF4E7D42),
              glow: Color(0xFFD8B44E),
              text: Color(0xFF24432A),
              subtitle: Color(0xFF526A50),
              border: Color(0xFFD6E2CA),
              shadow: Color(0x204E7D42),
              icon: Icons.wb_twilight_outlined,
            ),
      'white_days_monday_thursday_fasting' => dark
          ? const EventPalette(
              gradient: [
                Color(0xFF202040),
                Color(0xFF373166),
                Color(0xFF2A2952),
              ],
              accent: Color(0xFFF0D784),
              glow: Color(0xFFC4E7E8),
              text: Color(0xFFFAF7EE),
              subtitle: Color(0xFFD9D3E6),
              border: Color(0xFF585181),
              shadow: Color(0x40373166),
              icon: Icons.brightness_5_outlined,
            )
          : const EventPalette(
              gradient: [
                Color(0xFFF8F6FC),
                Color(0xFFEDE8F7),
                Color(0xFFF8F6EE),
              ],
              accent: Color(0xFF65548B),
              glow: Color(0xFFD2AA47),
              text: Color(0xFF372E50),
              subtitle: Color(0xFF605675),
              border: Color(0xFFDDD6EA),
              shadow: Color(0x2065548B),
              icon: Icons.brightness_5_outlined,
            ),
      _ => const EventPalette(
          gradient: [Color(0xFF1A1A2E), Color(0xFF2A2A4E), Color(0xFF1E1E3E)],
          accent: Color(0xFFD4AF37),
          glow: Color(0xFFE8D5A0),
          text: Color(0xFFF5F0E8),
          subtitle: Color(0xFFCDC4B0),
          border: Color(0xFF3A3A5E),
          shadow: Color(0x402A2A4E),
          icon: Icons.star,
        ),
    };
  }
}

class IslamicEventPresentation {
  const IslamicEventPresentation({
    required this.event,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final IslamicEventConfig event;
  final String title;
  final String subtitle;
  final EventPalette palette;

  IconData get icon => palette.icon;

  String get semanticLabel => subtitle.isEmpty ? title : '$title. $subtitle';

  factory IslamicEventPresentation.resolve(
    BuildContext context, {
    required IslamicEventConfig event,
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return IslamicEventPresentation(
      event: event,
      title: titleFor(l10n, event.eventKey),
      subtitle: subtitleFor(l10n, event.eventKey),
      palette: EventPalette.forEvent(event.eventKey, isDark),
    );
  }

  static String titleFor(AppLocalizations l10n, String eventKey) {
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadan,
      'last_ten_ramadan' => l10n.eventLastTenRamadan,
      'eid_al_fitr' => l10n.eventEidAlFitr,
      'eid_al_adha' => l10n.eventEidAlAdha,
      'day_of_arafah' => l10n.eventDayOfArafah,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjah,
      'ashura' => l10n.eventAshura,
      'days_of_tashreeq' => l10n.eventDaysTashreeq,
      'white_days_fasting' => l10n.eventWhiteDaysFasting,
      'monday_thursday_fasting' => l10n.eventMondayThursdayFasting,
      'white_days_monday_thursday_fasting' =>
        l10n.eventWhiteDaysMondayThursdayFasting,
      _ => l10n.eventSpecialOccasion,
    };
  }

  static String subtitleFor(AppLocalizations l10n, String eventKey) {
    return switch (eventKey) {
      'ramadan' => l10n.eventRamadanSubtitle,
      'last_ten_ramadan' => l10n.eventLastTenRamadanSubtitle,
      'eid_al_fitr' => l10n.eventEidAlFitrSubtitle,
      'eid_al_adha' => l10n.eventEidAlAdhaSubtitle,
      'day_of_arafah' => l10n.eventDayOfArafahSubtitle,
      'first_ten_dhul_hijjah' => l10n.eventFirstTenDhulHijjahSubtitle,
      'ashura' => l10n.eventAshuraSubtitle,
      'days_of_tashreeq' => l10n.eventDaysTashreeqSubtitle,
      'white_days_fasting' => l10n.eventWhiteDaysFastingSubtitle,
      'monday_thursday_fasting' => l10n.eventMondayThursdayFastingSubtitle,
      'white_days_monday_thursday_fasting' =>
        l10n.eventWhiteDaysMondayThursdayFastingSubtitle,
      _ => l10n.eventSpecialOccasionSubtitle,
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

class _SpecialEventCardState extends State<SpecialEventCard> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final presentation = IslamicEventPresentation.resolve(
      context,
      event: widget.event,
      isDark: widget.isDarkMode,
    );
    final palette = presentation.palette;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final highContrast = MediaQuery.highContrastOf(context);
    final active = _hovered || _focused || _pressed;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final direction = Directionality.of(context);

    return CeremonialEventReveal(
      eventKey: widget.event.eventKey,
      duration: const Duration(milliseconds: 1180),
      curve: Curves.easeOutCubic,
      builder: (context, reveal) => Semantics(
        button: true,
        focusable: true,
        focused: _focused,
        label: presentation.semanticLabel,
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.992 : 1,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const ValueKey('special-event-card-action'),
                onTap: widget.onTap,
                onHover: (value) {
                  if (_hovered != value) setState(() => _hovered = value);
                },
                onFocusChange: (value) {
                  if (_focused != value) setState(() => _focused = value);
                },
                onHighlightChanged: (pressed) {
                  if (_pressed != pressed) setState(() => _pressed = pressed);
                },
                customBorder: const _ClassicEventThresholdBorder(),
                focusColor: palette.accent.withValues(alpha: 0.13),
                hoverColor: palette.accent.withValues(alpha: 0.08),
                splashColor: palette.accent.withValues(alpha: 0.12),
                child: Ink(
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    shape: const _ClassicEventThresholdBorder(),
                    gradient: LinearGradient(
                      begin: direction == TextDirection.rtl
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      end: direction == TextDirection.rtl
                          ? Alignment.bottomLeft
                          : Alignment.bottomRight,
                      colors: palette.gradient,
                      stops: const [0, 0.52, 1],
                    ),
                    shadows: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: active ? 25 : 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: const _ClassicEventThresholdClipper(),
                    child: CustomPaint(
                      painter: _ClassicThresholdPainter(
                        progress: reveal,
                        accent: palette.accent,
                        glow: palette.glow,
                        border: palette.border,
                        active: active,
                        highContrast: highContrast,
                        textDirection: direction,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: textScale > 1.55 ? 132 : 116,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            context.responsive(
                              mobile: 16.w,
                              tablet: 22.w,
                              desktop: 28.w,
                            ),
                            textScale > 1.55 ? 16 : 13,
                            context.responsive(
                              mobile: 18.w,
                              tablet: 24.w,
                              desktop: 30.w,
                            ),
                            textScale > 1.55 ? 16 : 13,
                          ),
                          child: _buildContent(
                            context,
                            presentation,
                            reveal,
                            active: active,
                            highContrast: highContrast,
                            textScale: textScale,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    IslamicEventPresentation presentation,
    Animation<double> reveal, {
    required bool active,
    required bool highContrast,
    required double textScale,
  }) {
    final palette = presentation.palette;
    final titleSize = context.responsive(
      mobile: 17.sp,
      tablet: 20.sp,
      desktop: 23.sp,
    );
    final subtitleSize = context.responsive(
      mobile: 12.sp,
      tablet: 14.sp,
      desktop: 16.sp,
    );
    final motifExtent = textScale > 1.55
        ? 60.0
        : context.responsive(mobile: 76.0, tablet: 86.0, desktop: 94.0);
    final direction = Directionality.of(context);
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: motifExtent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: palette.accent.withValues(alpha: active ? 0.13 : 0.08),
                  shape: _EventPortalShape(
                    side: BorderSide(
                      color: palette.accent.withValues(
                        alpha: highContrast ? 0.9 : (active ? 0.68 : 0.46),
                      ),
                      width: highContrast ? 1.6 : 1,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: CanonicalEventMotif(
                  eventKey: widget.event.eventKey,
                  host: EventVisualHost.classic,
                  accent: palette.accent,
                  secondary: palette.glow,
                  progress: reveal,
                  textDirection: direction,
                  strokeWidth: highContrast ? 2 : 1.45,
                  highContrast: highContrast,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: textScale > 1.55 ? 12 : 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                presentation.title,
                maxLines: textScale > 1.55 ? null : 2,
                overflow: textScale > 1.55
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                  height: 1.22,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: textScale > 1.55 ? 6 : 4.h),
              Text(
                presentation.subtitle,
                maxLines: textScale > 1.55 ? null : 2,
                overflow: textScale > 1.55
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: palette.subtitle,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          width: 28,
          height: 38,
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                color: palette.accent.withValues(alpha: active ? 0.7 : 0.34),
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 17,
            color: palette.accent.withValues(alpha: active ? 1 : 0.72),
          ),
        ),
      ],
    );

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: reveal,
        curve: const Interval(0.22, 0.72, curve: Curves.easeOut),
      ),
      child: content,
    );
  }
}

class _ClassicEventThresholdClipper extends CustomClipper<Path> {
  const _ClassicEventThresholdClipper();

  @override
  Path getClip(Size size) => _classicThresholdPath(Offset.zero & size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ClassicEventThresholdBorder extends ShapeBorder {
  const _ClassicEventThresholdBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _classicThresholdPath(rect.deflate(1));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _classicThresholdPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

Path _classicThresholdPath(Rect rect) {
  final cut = (rect.shortestSide * 0.12).clamp(14.0, 24.0);
  final notch = (rect.width * 0.055).clamp(14.0, 30.0);
  final center = rect.center.dx;
  return Path()
    ..moveTo(rect.left + cut, rect.top)
    ..lineTo(rect.right - cut, rect.top)
    ..lineTo(rect.right, rect.top + cut)
    ..lineTo(rect.right, rect.bottom - cut * 0.72)
    ..lineTo(rect.right - cut * 0.72, rect.bottom)
    ..lineTo(center + notch, rect.bottom)
    ..lineTo(center, rect.bottom - 4)
    ..lineTo(center - notch, rect.bottom)
    ..lineTo(rect.left + cut * 0.72, rect.bottom)
    ..lineTo(rect.left, rect.bottom - cut * 0.72)
    ..lineTo(rect.left, rect.top + cut)
    ..close();
}

class _EventPortalShape extends ShapeBorder {
  const _EventPortalShape({required this.side});

  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final c = rect.center;
    return Path()
      ..moveTo(c.dx, rect.top)
      ..lineTo(rect.right, c.dy * 0.72)
      ..lineTo(rect.right, rect.bottom - rect.height * 0.22)
      ..lineTo(c.dx, rect.bottom)
      ..lineTo(rect.left, rect.bottom - rect.height * 0.22)
      ..lineTo(rect.left, c.dy * 0.72)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }

  @override
  ShapeBorder scale(double t) => _EventPortalShape(side: side.scale(t));
}

class _ClassicThresholdPainter extends CustomPainter {
  _ClassicThresholdPainter({
    required this.progress,
    required this.accent,
    required this.glow,
    required this.border,
    required this.active,
    required this.highContrast,
    required this.textDirection,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color accent;
  final Color glow;
  final Color border;
  final bool active;
  final bool highContrast;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final value = progress.value.clamp(0.0, 1.0);
    final frame = _classicThresholdPath(Offset.zero & size);
    final metric = frame.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * value);
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highContrast ? 1.8 : 1.05
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(border, accent, active ? 0.58 : 0.25)!
          .withValues(alpha: highContrast ? 1 : 0.82);
    canvas.drawPath(drawn, framePaint);

    final originOnRight = textDirection == TextDirection.ltr;
    final origin = Offset(originOnRight ? size.width * 0.84 : size.width * 0.16,
        size.height * 0.28);
    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withValues(alpha: active ? 0.15 : 0.09),
          glow.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: origin, radius: size.width * 0.3));
    canvas.drawCircle(origin, size.width * 0.3, wash);

    final ruleProgress = ((value - 0.18) / 0.56).clamp(0.0, 1.0);
    final rulePaint = Paint()
      ..color = accent.withValues(alpha: highContrast ? 0.6 : 0.22)
      ..strokeWidth = highContrast ? 1.1 : 0.65;
    final inset = size.width * 0.035;
    final extent = (size.width - inset * 2) * ruleProgress;
    canvas
      ..drawLine(Offset(inset, 7), Offset(inset + extent, 7), rulePaint)
      ..drawLine(
        Offset(size.width - inset, size.height - 8),
        Offset(size.width - inset - extent, size.height - 8),
        rulePaint,
      );
  }

  @override
  bool shouldRepaint(covariant _ClassicThresholdPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.glow != glow ||
      oldDelegate.border != border ||
      oldDelegate.active != active ||
      oldDelegate.highContrast != highContrast ||
      oldDelegate.textDirection != textDirection;
}
