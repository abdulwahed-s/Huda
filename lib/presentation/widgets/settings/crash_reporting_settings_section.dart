import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/services/crash_reporter.dart';
import 'package:huda/core/services/crash_reporting_consent.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/core/utils/responsive_utils.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/settings/settings_card.dart';

class CrashReportingSettingsSection extends StatefulWidget {
  const CrashReportingSettingsSection({super.key});

  @override
  State<CrashReportingSettingsSection> createState() =>
      _CrashReportingSettingsSectionState();
}

class _CrashReportingSettingsSectionState
    extends State<CrashReportingSettingsSection> {
  bool? _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await CrashReportingConsent.getDecision();
    if (mounted) setState(() => _enabled = enabled ?? false);
  }

  Future<void> _setEnabled(bool enabled) async {
    if (_saving) return;
    final previous = _enabled;
    setState(() {
      _enabled = enabled;
      _saving = true;
    });

    try {
      await CrashReporter.setFossConsent(enabled);
    } catch (_) {
      if (mounted) setState(() => _enabled = previous);
      rethrow;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = _enabled ?? false;
    final primary = context.primaryColor;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  context.responsive(
                    mobile: 12.w,
                    tablet: 14.0,
                    desktop: 14.0,
                  ),
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: primary,
                  size: context.responsive(
                    mobile: 24.sp,
                    tablet: 26.0,
                    desktop: 26.0,
                  ),
                ),
              ),
              SizedBox(width: context.responsive(mobile: 14.w, tablet: 16.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.crashReportingSettingsTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        enabled
                            ? l10n.crashReportingEnabledLabel
                            : l10n.crashReportingDisabledLabel,
                        key: ValueKey(enabled),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: enabled
                              ? primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_enabled == null || _saving)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primary,
                  ),
                )
              else
                Switch.adaptive(
                  value: enabled,
                  onChanged: _setEnabled,
                ),
            ],
          ),
          SizedBox(height: context.responsive(mobile: 18.h, tablet: 18.0)),
          Text(
            l10n.crashReportingSettingsDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.responsive(mobile: 14.h, tablet: 14.0)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              context.responsive(mobile: 14.w, tablet: 16.0, desktop: 16.0),
            ),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.data_object_rounded, size: 20, color: primary),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.crashReportingSharedDataTitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        l10n.crashReportingSharedDataDescription,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
