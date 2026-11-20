import 'package:flutter/material.dart';
import 'package:huda/core/utils/distribution_channel.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/settings/settings_body.dart';

class Settings extends StatelessWidget {
  const Settings({super.key, this.showPrivacy});

  final bool? showPrivacy;

  @override
  Widget build(BuildContext context) {
    return HudaScaffold(
      title: AppLocalizations.of(context)!.settings,
      body: HudaRevealScope(
        child: SettingsBody(
          showPrivacy: showPrivacy ?? DistributionChannel.isFoss,
        ),
      ),
    );
  }
}
