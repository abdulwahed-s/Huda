import 'package:flutter/material.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home/home_actions.dart';
import 'package:huda/presentation/widgets/home/home_content.dart';
import 'package:huda/presentation/widgets/home/home_event.dart';
import 'package:huda/presentation/widgets/home/home_gallery.dart';

class ClassicHome extends StatelessWidget {
  const ClassicHome({
    super.key,
    required this.tools,
    required this.more,
    required this.actions,
  });

  final List<HomeFeatureDefinition> tools;
  final List<HomeFeatureDefinition> more;
  final HomeActions actions;

  @override
  Widget build(BuildContext context) {
    final gap = homeBlockGap(context);
    final event = HomeEventCard(padding: EdgeInsets.only(bottom: gap));
    HomeGallery gallery({int skip = 0, int? take}) => HomeGallery(
      tools: tools,
      more: more,
      actions: actions,
      skip: skip,
      take: take,
    );
    int rows(BuildContext context, double width) =>
        HomeGrid.columnsFor(context, width, spansFold: false) * 2;
    return HomeLanding(
      body: Column(
        key: const ValueKey('classic-home'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [event, gallery()],
      ),
      tabletop: (
        top: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              event,
              gallery(take: rows(context, constraints.maxWidth)),
            ],
          ),
        ),
        bottom: LayoutBuilder(
          builder: (context, constraints) =>
              gallery(skip: rows(context, constraints.maxWidth)),
        ),
      ),
    );
  }
}
