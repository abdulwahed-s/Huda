import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';

/// Lock-screen widget guidance on Samsung phones with One UI 9 (Android
/// 16, SDK 36) and later. Nothing elsewhere.
class SamsungLockWidgetSetup extends StatefulWidget {
  const SamsungLockWidgetSetup({super.key});

  @override
  State<SamsungLockWidgetSetup> createState() => _SamsungLockWidgetSetupState();
}

class _SamsungLockWidgetSetupState extends State<SamsungLockWidgetSetup> {
  late final Future<bool> _showGuidance = _isSamsungTarget();

  Future<bool> _isSamsungTarget() async {
    if (!PlatformUtils.isAndroid) return false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      // This scopes setup guidance; it does not claim to detect picker eligibility.
      return info.manufacturer.toLowerCase() == 'samsung' &&
          info.version.sdkInt >= 36;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _showGuidance,
    builder: (context, snapshot) {
      if (snapshot.data != true) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context)!;
      final space = context.tokens.space;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Padding(
        padding: EdgeInsets.only(top: space.sm),
        child: HudaCard(
          padding: EdgeInsets.all(space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: scheme.primary),
                  SizedBox(width: space.sm),
                  Expanded(
                    child: Text(
                      l10n.samsungLockWidgetsTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: space.sm),
              Text(
                l10n.samsungLockWidgetsInstructions,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: space.xs),
              Text(
                l10n.samsungLockWidgetsHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
