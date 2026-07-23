import 'package:flutter/material.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/feature_grid.dart';
import 'package:huda/presentation/widgets/home/quran_feature_stack_card.dart';
import 'package:huda/presentation/widgets/home/shared/home_section_widgets.dart';
import 'package:huda/presentation/widgets/home/themes/classic_view_more_collection.dart';

class ClassicHome extends StatefulWidget {
  const ClassicHome({
    super.key,
    required this.configuration,
    required this.features,
    required this.actions,
    required this.isDark,
    required this.openLastReadSurah,
    required this.openLastReciterAudio,
    required this.openLastRadioStation,
  });

  final HomeThemeConfiguration configuration;
  final List<HomeFeatureDefinition> features;
  final HomeDashboardActions actions;
  final bool isDark;
  final Function(Map<String, dynamic>) openLastReadSurah;
  final Function(dynamic) openLastReciterAudio;
  final Function(dynamic) openLastRadioStation;

  @override
  State<ClassicHome> createState() => _ClassicHomeState();
}

class _ClassicHomeState extends State<ClassicHome> {
  @override
  Widget build(BuildContext context) {
    final visiblePrimary = _visible(widget.configuration.primaryFeatures);
    final visibleMore = _definitions(
      _visible(widget.configuration.viewMoreFeatures),
    );
    final featureGrid = visibleMore.isEmpty
        ? _buildGrid(visiblePrimary)
        : ClassicViewMoreCollection(
            features: visibleMore,
            isDarkMode: widget.isDark,
            primaryItemCount: visiblePrimary.length,
            gridBuilder: (trailingCard) => _buildGrid(
              visiblePrimary,
              trailingCard: trailingCard,
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSpecialEventSection(isDark: widget.isDark),
        featureGrid,
      ],
    );
  }

  List<HomeFeatureDefinition> _definitions(List<HomeFeatureId> ids) {
    final byId = {for (final feature in widget.features) feature.id: feature};
    return ids
        .map((id) => byId[id])
        .whereType<HomeFeatureDefinition>()
        .toList();
  }

  List<HomeFeatureId> _visible(List<HomeFeatureId> source) {
    final available = widget.features.map((feature) => feature.id).toSet();
    return source
        .where((id) =>
            available.contains(id) &&
            !widget.configuration.hiddenFeatures.contains(id))
        .toList();
  }

  Widget _buildGrid(
    List<HomeFeatureId> ids, {
    Widget? trailingCard,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final feature in widget.features) feature.id: feature};
    final quranIndex = ids.indexOf(HomeFeatureId.quranKit);
    final cards = ids
        .where((id) => id != HomeFeatureId.quranKit)
        .map((id) => byId[id])
        .whereType<HomeFeatureDefinition>()
        .map(
          (feature) => FeatureItem(
            title: feature.title,
            svgAsset: feature.svgAsset,
            icon: feature.icon,
            onTap: feature.onTap,
          ),
        )
        .toList();

    return FeatureGrid(
      isDarkMode: widget.isDark,
      features: cards,
      trailingCard: trailingCard,
      quranStackIndex: quranIndex < 0 ? 0 : quranIndex,
      quranStackCard: quranIndex < 0
          ? null
          : QuranFeatureStackCard(
              isDarkMode: widget.isDark,
              index: quranIndex,
              stackLabel: l10n.quranKit,
              quranLabel: l10n.quran,
              audioLabel: l10n.quranAudio,
              radioLabel: l10n.quranRadio,
              bookmarkLabel: l10n.bookmarks,
              onQuranTap: widget.actions.openQuran,
              onAudioTap: widget.actions.openAudio,
              onRadioTap: widget.actions.openRadio,
              onBookmarkTap: widget.actions.openBookmarks,
              openLastReciterAudio: widget.openLastReciterAudio,
              openLastRadioStation: widget.openLastRadioStation,
            ),
      openLastReadSurah: widget.openLastReadSurah,
      openLastReciterAudio: widget.openLastReciterAudio,
      openLastRadioStation: widget.openLastRadioStation,
    );
  }
}
