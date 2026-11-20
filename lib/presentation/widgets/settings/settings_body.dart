import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/home_preferences_service.dart';
import 'package:huda/core/services/rating_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/core/utils/platform_utils.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/settings/color_theme_picker.dart';
import 'package:huda/presentation/widgets/settings/crash_reporting_settings_section.dart';
import 'package:huda/presentation/widgets/settings/font_picker.dart';
import 'package:huda/presentation/widgets/settings/language_picker.dart';
import 'package:huda/presentation/widgets/settings/settings_layout.dart';
import 'package:huda/presentation/widgets/settings/text_size_slider.dart';
import 'package:huda/presentation/widgets/settings/theme_mode_control.dart';

class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key, required this.showPrivacy});

  final bool showPrivacy;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    var index = 0;
    Widget reveal(Widget child) => HudaReveal(index: index++, child: child);
    return SettingsColumns(
      start: [reveal(const SettingsAppearanceSection())],
      end: [
        reveal(const _GeneralSection()),
        if (showPrivacy) ...[
          SizedBox(height: space.xl),
          reveal(const _PrivacySection()),
        ],
        SizedBox(height: space.xl),
        reveal(const _SupportSection()),
      ],
    );
  }
}

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final themes = context.watch<ThemeCubit>();
    final state = themes.state;
    Widget label(String text, {String? note}) => Padding(
      padding: EdgeInsets.only(bottom: space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.titleSmall),
          if (note != null) ...[
            SizedBox(height: space.xxs),
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    Widget gap() => Padding(
      padding: EdgeInsets.symmetric(vertical: space.md),
      child: const Divider(height: 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HudaSectionHeader(l10n.settingsAppearance),
        HudaCard(
          padding: EdgeInsets.all(space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              label(l10n.theme),
              const ThemeModeControl(),
              if (state.themeMode != ThemeMode.light)
                Padding(
                  padding: EdgeInsets.only(top: space.sm),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    removeRight: true,
                    child: SwitchListTile(
                      key: const ValueKey('settings-pure-black'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.settingsPureBlack),
                      subtitle: Text(l10n.settingsPureBlackDescription),
                      value: state.pureBlack,
                      onChanged: (value) {
                        HudaHaptics.selection(context);
                        themes.setPureBlack(value);
                      },
                    ),
                  ),
                ),
              gap(),
              label(l10n.colorTheme),
              ColorThemePicker(
                selectedTheme: state.colorTheme,
                showHeader: false,
                onThemeSelected: (colorTheme) {
                  if (colorTheme == state.colorTheme) return;
                  HudaHaptics.selection(context);
                  themes.setColorTheme(colorTheme);
                },
              ),
              gap(),
              const TextSizeControl(),
              gap(),
              label(l10n.settingsAppFont, note: l10n.settingsAppFontDescription),
              FontPicker(
                selectedFont: state.fontFamily,
                onFontSelected: themes.setFontFamily,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themes = context.watch<ThemeCubit>();
    final haptics = themes.state.hapticsEnabled;
    return HudaSection(
      title: l10n.settingsGeneral,
      children: [
        const LanguageRow(),
        if (HudaHaptics.supported(context))
          HudaSettingsRow(
            key: const ValueKey('settings-haptics'),
            icon: Icons.vibration_rounded,
            title: l10n.settingsHapticFeedback,
            subtitle: l10n.settingsHapticFeedbackDescription,
            trailing: Switch(
              value: haptics,
              onChanged: (value) => _setHaptics(context, themes, value),
            ),
            onTap: () => _setHaptics(context, themes, !haptics),
          ),
        const _HomeLayoutRow(),
        if (PlatformUtils.isMobile || PlatformUtils.isMacOS)
          HudaSettingsRow(
            key: const ValueKey('settings-widgets'),
            icon: Icons.widgets_outlined,
            title: l10n.widgetManagement,
            subtitle: l10n.settingsWidgetsSubtitle,
            trailing: const _Chevron(),
            onTap: () =>
                Navigator.pushNamed(context, AppRoute.widgetManagement),
          ),
      ],
    );
  }

  void _setHaptics(BuildContext context, ThemeCubit themes, bool value) {
    themes.setHapticsEnabled(value);
    if (value) HudaHaptics.selection(context);
  }
}

class _HomeLayoutRow extends StatefulWidget {
  const _HomeLayoutRow();

  @override
  State<_HomeLayoutRow> createState() => _HomeLayoutRowState();
}

class _HomeLayoutRowState extends State<_HomeLayoutRow> {
  HomeThemeId? _style;

  @override
  void initState() {
    super.initState();
    _read();
  }

  void _read() {
    if (!getIt.isRegistered<HomePreferencesService>()) return;
    try {
      _style = getIt<HomePreferencesService>().load().selectedTheme;
    } catch (_) {
      _style = null;
    }
  }

  Future<void> _open() async {
    await Navigator.pushNamed(context, AppRoute.homeCustomization);
    if (mounted) setState(_read);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = _style;
    return HudaSettingsRow(
      key: const ValueKey('settings-home'),
      icon: Icons.dashboard_customize_outlined,
      title: l10n.customizeHome,
      subtitle: style == null ? null : homeThemeName(context, style),
      trailing: const _Chevron(),
      onTap: _open,
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaSection(
      title: l10n.settingsPrivacy,
      footer: l10n.crashReportingPrivacyNote,
      children: const [CrashReportingSwitchRow()],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return HudaSection(
      title: l10n.supportAndFeedback,
      children: [
        HudaSettingsRow(
          key: const ValueKey('settings-rate'),
          icon: Icons.star_outline_rounded,
          title: l10n.rateOurApp,
          subtitle: l10n.rateAppDescription,
          trailing: const _Chevron(),
          onTap: () => RatingService.instance.showRatingDialog(context),
        ),
        HudaSettingsRow(
          key: const ValueKey('settings-feedback'),
          icon: Icons.forum_outlined,
          title: l10n.feedbackAndIssueActionTitle,
          subtitle: l10n.feedbackAndIssueActionSubtitle,
          trailing: const _Chevron(),
          onTap: () => Navigator.pushNamed(context, AppRoute.feedback),
        ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) => Icon(
    Icons.chevron_right_rounded,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
