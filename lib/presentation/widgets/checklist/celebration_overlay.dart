import 'package:flutter/material.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/newton_effect.dart';
import 'package:lottie/lottie.dart';

class CelebrationOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onComplete;
  final int streakCount;

  const CelebrationOverlay({
    super.key,
    required this.isVisible,
    this.onComplete,
    required this.streakCount,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const _fadeInDuration = Duration(milliseconds: 800);
  static const _holdDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _fadeInDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.addStatusListener(_handleFadeStatus);
  }

  void _handleFadeStatus(AnimationStatus status) async {
    if (status == AnimationStatus.completed) {
      await Future.delayed(_holdDuration);
      if (mounted) {
        _fadeController.reverse();
      }
    } else if (status == AnimationStatus.dismissed) {
      widget.onComplete?.call();
    }
  }

  @override
  void didUpdateWidget(CelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startCelebration();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _stopCelebration();
    }
  }

  void _startCelebration() {
    _fadeController.reset();
    _fadeController.forward();
  }

  void _stopCelebration() {
    if (_fadeController.status != AnimationStatus.dismissed) {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _fadeController.removeStatusListener(_handleFadeStatus);
    _fadeController.dispose();
    super.dispose();
  }

  List<String> _getCongratsMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.congratsMessage1,
      l10n.congratsMessage2,
      l10n.congratsMessage3,
      l10n.congratsMessage4,
      l10n.congratsMessage5,
      l10n.congratsMessage6,
      l10n.congratsMessage7,
      l10n.congratsMessage8,
      l10n.congratsMessage9,
      l10n.congratsMessage10,
      l10n.congratsMessage11,
      l10n.congratsMessage12,
      l10n.congratsMessage13,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _fadeController.isDismissed) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Stack(
            children: [
              const NewtonEffect(),
              // Centered column with fire and text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 400,
                      child: Lottie.asset(
                        'assets/images/Fire.json',
                        repeat: true,
                        animate: widget.isVisible,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Text(
                          _getCongratsMessages(context)[widget.streakCount %
                              _getCongratsMessages(context).length],
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                            fontFamily: "Amiri",
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.streakCount}${AppLocalizations.of(context)!.dayStreakSuffix(widget.streakCount)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade400,
                            fontFamily: "Amiri",
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
