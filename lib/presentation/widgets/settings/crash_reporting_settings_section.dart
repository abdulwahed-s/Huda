import 'package:flutter/material.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/core/services/crash_reporting_consent.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/design/huda_toast.dart';

/// The FOSS build's crash-reporting switch, as a settings row. The lamp
/// spinner holds its place while the saved choice loads; a failed save
/// flips the switch back and says so.
class CrashReportingSwitchRow extends StatefulWidget {
  const CrashReportingSwitchRow({super.key, this.initialDecision});

  /// Seeds the choice without reading storage (tests and the harness).
  final bool? initialDecision;

  @override
  State<CrashReportingSwitchRow> createState() =>
      _CrashReportingSwitchRowState();
}

class _CrashReportingSwitchRowState extends State<CrashReportingSwitchRow> {
  bool? _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialDecision;
    if (_enabled == null) _load();
  }

  Future<void> _load() async {
    final enabled = await CrashReportingConsent.getDecision();
    if (mounted) setState(() => _enabled = enabled ?? false);
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_saving) return;
    HudaHaptics.selection(context);
    final previous = _enabled;
    setState(() {
      _enabled = enabled;
      _saving = true;
    });
    try {
      await CrashReporter.setFossConsent(enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enabled = previous);
      showHudaToast(
        context,
        message: AppLocalizations.of(context)!.somethingWentWrong,
        kind: HudaToastKind.failed,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = _enabled;
    return Semantics(
      toggled: enabled ?? false,
      child: HudaSettingsRow(
        key: const ValueKey('settings-crash-reporting'),
        icon: Icons.shield_outlined,
        title: l10n.crashReportingSettingsTitle,
        subtitle: l10n.crashReportingSettingsDescription,
        trailing: enabled == null
            ? const SizedBox.square(
                dimension: 48,
                child: Center(child: HudaLampSpinner(size: 24)),
              )
            : Switch(
                value: enabled,
                onChanged: _saving ? null : _setEnabled,
              ),
        onTap: enabled == null || _saving ? null : () => _setEnabled(!enabled),
      ),
    );
  }
}
