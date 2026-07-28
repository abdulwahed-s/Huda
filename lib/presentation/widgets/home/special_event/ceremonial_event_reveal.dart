import 'package:flutter/material.dart';

typedef CeremonialEventRevealBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
);

class CeremonialEventReveal extends StatefulWidget {
  const CeremonialEventReveal({
    super.key,
    required this.eventKey,
    required this.builder,
    this.duration = const Duration(milliseconds: 920),
    this.curve = Curves.easeOutCubic,
    this.animateInitial = true,
    this.onCompleted,
  });

  final String eventKey;
  final CeremonialEventRevealBuilder builder;
  final Duration duration;
  final Curve curve;
  final bool animateInitial;
  final VoidCallback? onCompleted;

  @override
  State<CeremonialEventReveal> createState() => _CeremonialEventRevealState();
}

class _CeremonialEventRevealState extends State<CeremonialEventReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late Animation<double> _animation;

  bool _dependenciesReady = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;
  bool _appIsActive = true;
  String? _completionReportedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appIsActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 0,
    )..addStatusListener(_handleStatus);
    _updateCurve();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final reduceMotion = media?.disableAnimations ?? false;
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final firstConfiguration = !_dependenciesReady;

    _dependenciesReady = true;
    _reduceMotion = reduceMotion;
    _tickerEnabled = tickerEnabled;

    if (firstConfiguration && !widget.animateInitial) {
      _settleImmediately();
      return;
    }
    _synchronizeController();
  }

  @override
  void didUpdateWidget(CeremonialEventReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) _updateCurve();

    if (oldWidget.eventKey != widget.eventKey) {
      _completionReportedFor = null;
      _controller
        ..stop(canceled: false)
        ..value = 0;
      if (_dependenciesReady) _synchronizeController();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    if (_dependenciesReady) _synchronizeController();
  }

  void _updateCurve() {
    _animation = _controller.drive(CurveTween(curve: widget.curve));
  }

  void _synchronizeController() {
    if (_reduceMotion) {
      _settleImmediately();
      return;
    }

    if (!_appIsActive || !_tickerEnabled) {
      _controller.stop(canceled: false);
      return;
    }

    if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  void _settleImmediately() {
    _controller.stop(canceled: false);
    if (_controller.value != 1) _controller.value = 1;
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _completionReportedFor == widget.eventKey) {
      return;
    }
    final completedKey = widget.eventKey;
    _completionReportedFor = completedKey;
    final callback = widget.onCompleted;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.eventKey == completedKey &&
          _completionReportedFor == completedKey) {
        callback();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _animation);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }
}
