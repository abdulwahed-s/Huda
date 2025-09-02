import 'package:flutter/material.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/settings/settings_app_bar.dart';
import 'package:huda/presentation/widgets/settings/settings_body.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? context.darkCardBackground : context.lightSurface,
      appBar: SettingsAppBar(isDark: isDark),
      body: SettingsBody(isDark: isDark),
    );
  }
}
