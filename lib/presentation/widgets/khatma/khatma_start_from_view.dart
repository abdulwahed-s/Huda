import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/khatma/khatma_card.dart';
import 'package:huda/presentation/widgets/khatma/khatma_icon_list_tile.dart';
import 'package:huda/presentation/widgets/khatma/khatma_top_title.dart';

class KhatmaStartFromView extends StatelessWidget {
  final TextDirection textDirection;
  final VoidCallback onBack;
  final VoidCallback onFromBeginning;
  final VoidCallback onSpecificWird;

  const KhatmaStartFromView({
    super.key,
    required this.textDirection,
    required this.onBack,
    required this.onFromBeginning,
    required this.onSpecificWird,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: textDirection,
      child: ListView(
        padding: EdgeInsets.only(
          top: 6.h,
          bottom: 24.h + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          KhatmaTopTitle(
            title: l10n.khatmaStartFromTitle,
            onBack: onBack,
            textDirection: textDirection,
          ),
          SizedBox(height: 6.h),
          KhatmaCard(
            child: Column(
              children: [
                KhatmaIconListTile(
                  icon: Icons.import_contacts_rounded,
                  iconColor: Colors.green.shade600,
                  title: l10n.khatmaFromBeginning,
                  subtitle: l10n.khatmaFromBeginningSubtitle,
                  textDirection: textDirection,
                  onTap: onFromBeginning,
                ),
                Divider(height: 1, indent: 62.w),
                KhatmaIconListTile(
                  icon: Icons.list_rounded,
                  iconColor: Colors.orange.shade600,
                  title: l10n.khatmaSpecificWird,
                  subtitle: l10n.khatmaSpecificWirdSubtitle,
                  textDirection: textDirection,
                  onTap: onSpecificWird,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
