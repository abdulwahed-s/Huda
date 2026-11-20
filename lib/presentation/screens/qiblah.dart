import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/qiblah/qiblah_service.dart';
import 'package:huda/core/services/geolocator.dart';
import 'package:huda/core/theme/huda_theme_scope.dart';
import 'package:huda/cubit/qiblah/qiblah_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_instrument.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_states.dart';

class QiblahScreen extends StatefulWidget {
  const QiblahScreen({super.key, this.readings});

  final Stream<QiblahReading> Function()? readings;

  @override
  State<QiblahScreen> createState() => QiblahScreenState();
}

class QiblahScreenState extends State<QiblahScreen> {
  Stream<QiblahReading>? _readings;

  bool _failed = false;

  bool _retrying = false;

  bool _awaitingSettings = false;

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      if (!_awaitingSettings || !mounted) return;
      _awaitingSettings = false;
      context.read<QiblahCubit>().loadQiblah();
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _retrying = true;
      _failed = false;
      _readings = null;
    });
    context.read<QiblahCubit>().loadQiblah();
  }

  void _openLocationSettings() {
    _awaitingSettings = true;
    Geolocator.openLocationSettings();
  }

  void _openAppSettings() {
    _awaitingSettings = true;
    Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaNight(
      child: HudaRevealScope(
        child: BlocConsumer<QiblahCubit, QiblahState>(
          listener: (context, state) {
            setState(() {
              if (state is QiblahLoading) {
                _readings = null;
                _failed = false;
              } else {
                _retrying = false;
              }
            });
          },
          builder: (context, state) {
            final (Object key, Widget body) = switch (state) {
              QiblahLoading() when _retrying => (
                QiblahError,
                QiblahErrorView(onRetry: _retry, retrying: true),
              ),
              QiblahError() => (
                QiblahError,
                QiblahErrorView(onRetry: _retry, retrying: false),
              ),
              QiblahReady() when _failed => (
                QiblahError,
                QiblahErrorView(onRetry: _retry, retrying: false),
              ),
              QiblahLocationServiceOff() => (
                QiblahLocationServiceOff,
                QiblahLocationOffView(
                  onOpenSettings: _openLocationSettings,
                  onRetry: _retry,
                ),
              ),
              QiblahPermissionDenied() => (
                QiblahPermissionDenied,
                QiblahAllowLocationView(
                  onAllow: () =>
                      context.read<QiblahCubit>().loadQiblah(ask: true),
                ),
              ),
              QiblahPermissionDeniedForever() => (
                QiblahPermissionDeniedForever,
                QiblahLocationBlockedView(onOpenSettings: _openAppSettings),
              ),
              QiblahReady() => (
                'instrument',
                QiblahInstrument(
                  readings: _readings ??=
                      (widget.readings ?? QiblahService.qiblahStream)(),
                  onFailed: (_) {
                    if (mounted) setState(() => _failed = true);
                  },
                  onRefreshLocation: () => setState(
                    () => _readings =
                        widget.readings?.call() ??
                        QiblahService.qiblahStream(refresh: true),
                  ),
                ),
              ),
              QiblahInitial() || QiblahLoading() => (
                'instrument',
                QiblahInstrument(readings: null, onFailed: (_) {}),
              ),
            };
            final isState = key != 'instrument';
            return Semantics(
              container: true,
              explicitChildNodes: true,
              label: l10n.qiblahDirection,
              child: HudaImmersiveScaffold(
                body: HudaStateSwitcher(
                  stateKey: key,
                  child: SizedBox.expand(
                    child: isState ? _BelowBar(child: body) : body,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BelowBar extends StatelessWidget {
  const _BelowBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
    child: child,
  );
}
