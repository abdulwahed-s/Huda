import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/layout/adaptive_layout.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';
import 'package:huda/presentation/widgets/design/huda_lamp.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home_customization/animated_reorder_layout.dart';
import 'package:huda/presentation/widgets/home_customization/customization_cards.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/home_customization/home_theme_preview.dart';
import 'package:huda/presentation/widgets/home_customization/unsaved_changes_confirmation.dart';

/// The Home editor ("Edit Home"), standard tier: the three styles side by
/// side (one tap picks one), then, for the chosen style, its sections
/// (Quran Journey), the tools on Home and in View More (drag to reorder,
/// one button moves a tool to the other group) and Restore default layout.
/// (Path of Prayer places Prayer Times and the Quran Kit itself.)
/// Close asks before throwing changes away; Save is pinned at the foot,
/// where a failed save says so with Retry.
class HomeCustomizationScreen extends StatefulWidget {
  const HomeCustomizationScreen({super.key});

  @override
  State<HomeCustomizationScreen> createState() =>
      _HomeCustomizationScreenState();
}

class _HomeCustomizationScreenState extends State<HomeCustomizationScreen> {
  late final ScrollController _scrollController;
  late HomeCustomizationCubit _customizationCubit;

  bool _sessionStarted = false;
  bool _allowPop = false;
  bool _closing = false;

  /// The save in flight was a tap on Retry after a failure.
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionStarted) return;
    _sessionStarted = true;
    _customizationCubit = context.read<HomeCustomizationCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _customizationCubit.beginEditing();
    });
  }

  @override
  void dispose() {
    if (_sessionStarted && !_customizationCubit.isClosed) {
      final state = _customizationCubit.state;
      if (state is HomeCustomizationReady && state.isEditing) {
        _customizationCubit.cancelEditing();
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
      builder: (context, customization) {
        final Widget body;
        if (customization is HomeCustomizationError) {
          body = HudaErrorState(
            message: l10n.unexpectedError,
            onRetry: _customizationCubit.load,
          );
        } else if (customization is! HomeCustomizationReady) {
          body = const Center(child: HudaLampSpinner(size: 28));
        } else {
          body = Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: _buildScrollableEditor(customization),
                ),
              ),
              _SaveBar(
                state: customization,
                retrying: _retrying,
                onSave: _saveAndClose,
              ),
            ],
          );
        }
        return PopScope(
          canPop: _allowPop || customization is! HomeCustomizationReady,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestCancel();
          },
          child: HudaScaffold(
            title: l10n.editHome,
            leading: IconButton(
              key: const ValueKey('customization-cancel'),
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close_rounded),
              onPressed: _requestCancel,
            ),
            body: HudaStateSwitcher(
              stateKey: customization.runtimeType,
              child: body,
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollableEditor(HomeCustomizationReady state) {
    final width = MediaQuery.sizeOf(context).width;
    final space = context.tokens.space;
    final gutter = space.gutter(width);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: context.scrollPadding(
            EdgeInsets.fromLTRB(gutter, space.xs, gutter, space.xxl),
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _CustomizationCanvas(
                  state: state,
                  onDragUpdate: _autoScroll,
                  onRestoreDefault: _restoreDefaultLayout,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _autoScroll(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final local = renderObject.globalToLocal(details.globalPosition);
    final size = renderObject.size;
    final topEdge = MediaQuery.paddingOf(context).top + 92;
    final bottomEdge =
        size.height - MediaQuery.viewPaddingOf(context).bottom - 96;
    var delta = 0.0;
    if (local.dy < topEdge) {
      delta = -math.min(18.0, (topEdge - local.dy) / 3);
    } else if (local.dy > bottomEdge) {
      delta = math.min(18.0, (local.dy - bottomEdge) / 3);
    }
    if (delta == 0) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  Future<void> _requestCancel() async {
    if (_closing) return;
    final state = _customizationCubit.state;
    if (state is! HomeCustomizationReady) {
      await _popEditor();
      return;
    }
    if (state.isSaving) return;
    if (!state.hasChanges) {
      _closing = true;
      _customizationCubit.cancelEditing();
      await _popEditor();
      return;
    }

    _closing = true;
    final outcome = await showDiscardChangesConfirmation(context);
    if (!mounted) return;
    if (outcome == HomeCustomizationCloseOutcome.discard) {
      _customizationCubit.cancelEditing();
      await _popEditor();
      return;
    }
    _closing = false;
  }

  Future<void> _saveAndClose() async {
    if (_closing) return;
    final state = _customizationCubit.state;
    if (state is! HomeCustomizationReady ||
        state.isSaving ||
        !state.hasChanges) {
      return;
    }
    _closing = true;
    setState(() => _retrying = state.saveError != null);
    final success = await _customizationCubit.applyDraft();
    if (!mounted) return;
    if (!success) {
      _closing = false;
      setState(() => _retrying = false);
      return;
    }
    HudaHaptics.light(context);
    await _popEditor(result: true);
  }

  Future<void> _restoreDefaultLayout() async {
    final confirmed = await showRestoreDefaultLayoutConfirmation(context);
    if (!mounted || !confirmed) return;
    HudaHaptics.light(context);
    _customizationCubit.resetCurrentTheme();
  }

  Future<void> _popEditor({Object? result}) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }
}

/// Save, pinned at the foot (its surface runs to the edge, its button
/// above the inset): lit when there's something to save, "Saving…" while
/// it saves; after a failure, the failure with Retry, then "Retrying…".
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.state,
    required this.retrying,
    required this.onSave,
  });

  final HomeCustomizationReady state;
  final bool retrying;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final gutter = space.gutter(width);
    final insets = MediaQuery.paddingOf(context);
    final failed = state.saveError != null && !state.isSaving;
    final Widget content;
    if (failed || (state.isSaving && retrying)) {
      content = HudaStatusBanner(
        key: const ValueKey('home-customization-save-error'),
        status: failed ? HudaStatus.failed : HudaStatus.retrying,
        message: l10n.homeChangesSaveFailed,
        onRetry: failed ? onSave : null,
      );
    } else {
      content = SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('customization-save'),
          onPressed: state.hasChanges && !state.isSaving ? onSave : null,
          icon: state.isSaving
              ? const HudaLampSpinner(size: 18)
              : const Icon(Icons.check_rounded),
          label: Text(state.isSaving ? '${l10n.saving}…' : l10n.save),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          gutter + insets.left,
          space.sm,
          gutter + insets.right,
          space.sm + insets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: HudaStateSwitcher(
              stateKey: content.key ?? 'save',
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomizationCanvas extends StatelessWidget {
  const _CustomizationCanvas({
    required this.state,
    required this.onDragUpdate,
    required this.onRestoreDefault,
  });

  final HomeCustomizationReady state;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onRestoreDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final theme = Theme.of(context);
    final draft = state.draft;
    final configuration = draft.configurationFor(draft.selectedTheme);
    final features = HomeFeatureCatalog.available(
      context,
      const HomeFeatureActions(openQuran: _noop, openQuranKit: _noop),
    );
    final available = features.map((feature) => feature.id).toSet();
    final definitions = {for (final feature in features) feature.id: feature};
    final primary = configuration.primaryFeatures
        .where(available.contains)
        .toList(growable: false);
    final more = configuration.viewMoreFeatures
        .where(available.contains)
        .toList(growable: false);
    final sections = configuration.orderedSections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HudaSectionHeader(l10n.homeStyle),
        SizedBox(height: space.xs),
        _StyleChoices(selected: draft.selectedTheme),
        SizedBox(height: space.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: space.xs),
            Expanded(
              child: Text(
                l10n.customizeHomeHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        HudaAnimatedSize(
          alignment: Alignment.topCenter,
          child: sections.isEmpty
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: space.xl),
                    HudaSectionHeader(l10n.homeSections),
                    SizedBox(height: space.xs),
                    _SectionReorderGrid(
                      sections: sections,
                      onDragUpdate: onDragUpdate,
                    ),
                  ],
                ),
        ),
        SizedBox(height: space.xl),
        HudaSectionHeader(l10n.onHome),
        SizedBox(height: space.xs),
        _GroupBody(
          empty: primary.isEmpty,
          emptyKey: 'home-empty',
          child: _FeatureReorderGrid(
            key: const ValueKey('home-feature-grid'),
            ids: primary,
            definitions: definitions,
            primary: true,
            onDragUpdate: onDragUpdate,
          ),
        ),
        SizedBox(height: space.xl),
        HudaSectionHeader(l10n.viewMore),
        SizedBox(height: space.xs),
        _GroupBody(
          empty: more.isEmpty,
          emptyKey: 'view-more-empty',
          emptyMessage: l10n.viewMoreEmpty,
          child: _FeatureReorderGrid(
            key: const ValueKey('view-more-feature-grid'),
            ids: more,
            definitions: definitions,
            primary: false,
            onDragUpdate: onDragUpdate,
          ),
        ),
        SizedBox(height: space.xl),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('restore-default-layout'),
            onPressed: state.isSaving ? null : onRestoreDefault,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.restoreDefaultLayout),
          ),
        ),
      ],
    );
  }
}

/// The three styles, each its own preview, name and line; one tap picks
/// one. Three across where they fit, else a list of choice rows.
class _StyleChoices extends StatelessWidget {
  const _StyleChoices({required this.selected});

  final HomeThemeId selected;

  static const _order = [
    HomeThemeId.classic,
    HomeThemeId.prayerToday,
    HomeThemeId.quranJourney,
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCustomizationCubit>();
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // Short windows (phone landscape) get the compact list: three tall
        // previews would fill the screen.
        final across =
            !context.windowClass.isCompactHeight &&
            constraints.maxWidth >= 3 * 112 * scale + 2 * space.sm;
        if (!across) {
          return Column(
            children: [
              for (final theme in _order) ...[
                if (theme != _order.first) SizedBox(height: space.xs),
                HudaChoiceRow(
                  key: ValueKey('home-style-${theme.name}'),
                  title: homeThemeName(context, theme),
                  subtitle: homeThemeDescription(context, theme),
                  selected: selected == theme,
                  leading: SizedBox(
                    width: 42,
                    height: 56,
                    child: HomeThemePreview(theme: theme),
                  ),
                  onTap: () => cubit.selectTheme(theme),
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final theme in _order) ...[
              if (theme != _order.first) SizedBox(width: space.sm),
              Expanded(
                child: _StyleTile(
                  key: ValueKey('home-style-${theme.name}'),
                  theme: theme,
                  selected: selected == theme,
                  onTap: () => cubit.selectTheme(theme),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final HomeThemeId theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final duration = tokens.motion.of(context, tokens.motion.short);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label:
          '${homeThemeName(context, theme)}. '
          '${homeThemeDescription(context, theme)}',
      excludeSemantics: true,
      child: HudaPressable(
        child: AnimatedContainer(
          duration: duration,
          curve: tokens.motion.standard,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.06)
                : scheme.surfaceContainerLowest,
            borderRadius: tokens.radius.card,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? tokens.stroke.fine : tokens.stroke.hairline,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: tokens.radius.card,
              child: Padding(
                padding: EdgeInsets.all(space.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: HomeThemePreview(theme: theme),
                        ),
                      ),
                    ),
                    SizedBox(height: space.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            homeThemeName(context, theme),
                            style: textTheme.titleSmall,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: duration,
                          child: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  key: const ValueKey('on'),
                                  size: 20,
                                  color: scheme.primary,
                                )
                              : const SizedBox(
                                  key: ValueKey('off'),
                                  width: 20,
                                  height: 20,
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: space.xxs),
                    Text(
                      homeThemeDescription(context, theme),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionReorderGrid extends StatelessWidget {
  const _SectionReorderGrid({
    required this.sections,
    required this.onDragUpdate,
  });

  final List<HomeSectionId> sections;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCustomizationCubit>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        return AnimatedReorderLayout<HomeSectionId>(
          items: sections,
          columns: columns,
          itemExtent: EditableHomeSectionCard.extentFor(context),
          spacing: context.tokens.space.sm,
          moveUpLabel: l10n.moveUp,
          moveDownLabel: l10n.moveDown,
          semanticLabelBuilder: (section) => homeSectionName(context, section),
          onDragUpdate: onDragUpdate,
          onReorder: (dragged, target) {
            final fromIndex = sections.indexOf(dragged);
            final toIndex = sections.indexOf(target);
            if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;
            cubit.reorderSections(fromIndex: fromIndex, toIndex: toIndex);
          },
          itemBuilder: (context, section, lifted) => EditableHomeSectionCard(
            title: homeSectionName(context, section),
            icon: homeSectionIcon(section),
            lifted: lifted,
          ),
        );
      },
    );
  }
}

class _FeatureReorderGrid extends StatelessWidget {
  const _FeatureReorderGrid({
    super.key,
    required this.ids,
    required this.definitions,
    required this.primary,
    required this.onDragUpdate,
  });

  final List<HomeFeatureId> ids;
  final Map<HomeFeatureId, HomeFeatureDefinition> definitions;
  final bool primary;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCustomizationCubit>();
    final spacing = context.tokens.space.sm;
    final fold = FoldInfo.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AdaptiveGrid.columns(
          width: constraints.maxWidth,
          minTileWidth: AdaptiveGrid.tileWidth(context, 140),
          spacing: spacing,
          maxColumns: 6,
          preferEven: fold.hasFold,
        );
        return AnimatedReorderLayout<HomeFeatureId>(
          items: ids,
          columns: columns,
          itemExtent: EditableHomeFeatureCard.extentFor(context),
          spacing: spacing,
          moveUpLabel: l10n.moveUp,
          moveDownLabel: l10n.moveDown,
          semanticLabelBuilder: (id) => definitions[id]?.title ?? id.name,
          onDragUpdate: onDragUpdate,
          onReorder: (dragged, target) {
            final fromIndex = ids.indexOf(dragged);
            final toIndex = ids.indexOf(target);
            if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;
            cubit.reorderFeature(
              primary: primary,
              fromIndex: fromIndex,
              toIndex: toIndex,
              visibleFeatures: ids,
            );
          },
          itemBuilder: (context, id, lifted) {
            final definition = definitions[id];
            if (definition == null) return const SizedBox.shrink();
            return EditableHomeFeatureCard(
              key: ValueKey('feature-card-${id.name}'),
              feature: definition,
              primary: primary,
              lifted: lifted,
              onMove: () {
                HudaHaptics.selection(context);
                cubit.moveFeature(id, toPrimary: !primary);
              },
            );
          },
        );
      },
    );
  }
}

/// A group's tools, or (empty) a quiet dashed place that says what it's
/// for; the change cross-fades and eases its size.
class _GroupBody extends StatelessWidget {
  const _GroupBody({
    required this.empty,
    required this.emptyKey,
    required this.child,
    this.emptyMessage,
  });

  final bool empty;
  final String emptyKey;
  final String? emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final message = emptyMessage;
    return HudaStateSwitcher(
      stateKey: empty,
      alignment: Alignment.topCenter,
      child: empty
          ? Container(
              key: ValueKey(emptyKey),
              constraints: const BoxConstraints(minHeight: 72),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: tokens.radius.card,
                border: Border.all(color: scheme.outlineVariant),
              ),
              padding: EdgeInsets.all(tokens.space.md),
              child: message == null
                  ? Icon(Icons.home_outlined, color: scheme.onSurfaceVariant)
                  : Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            )
          : KeyedSubtree(key: const ValueKey('items'), child: child),
    );
  }
}

void _noop() {}
