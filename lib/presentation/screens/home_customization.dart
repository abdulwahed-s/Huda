import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home_customization/animated_reorder_layout.dart';
import 'package:huda/presentation/widgets/home_customization/customization_cards.dart';
import 'package:huda/presentation/widgets/home_customization/customization_chrome.dart';
import 'package:huda/presentation/widgets/home_customization/customization_theme_banner.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_sheets.dart';
import 'package:huda/presentation/widgets/home_customization/unsaved_changes_confirmation.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';

class HomeCustomizationScreen extends StatefulWidget {
  const HomeCustomizationScreen({super.key});

  @override
  State<HomeCustomizationScreen> createState() =>
      _HomeCustomizationScreenState();
}

class _HomeCustomizationScreenState extends State<HomeCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _jiggleController;
  late final ScrollController _scrollController;
  late HomeCustomizationCubit _customizationCubit;

  bool _sessionStarted = false;
  bool _allowPop = false;
  bool _closing = false;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 510),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      if (reduceMotion) {
        _jiggleController
          ..stop()
          ..value = 0.5;
      } else {
        _jiggleController.repeat();
      }
    }
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
    _jiggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCustomizationCubit, HomeCustomizationState>(
      builder: (context, customization) {
        if (customization is HomeCustomizationError) {
          return _ErrorView(
            message: customization.message,
            onRetry: _customizationCubit.load,
          );
        }
        if (customization is! HomeCustomizationReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasChanges = customization.hasChanges;
        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestClose();
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                const Positioned.fill(child: _EditorBackground()),
                Positioned.fill(
                  child: _buildScrollableEditor(customization),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomizationEditorTopBar(
                    hasChanges: hasChanges,
                    isSaving: customization.isSaving,
                    onClose: _requestClose,
                    onApply: _finishEditing,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: customization.isSaving,
                    child: CustomizationEditorDock(
                      onTheme: () => showHomeThemePicker(context),
                      onReset: () {
                        HapticFeedback.mediumImpact();
                        _resetCurrentTheme();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollableEditor(HomeCustomizationReady state) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final horizontal = MediaQuery.sizeOf(context).width > 700 ? 28.0 : 16.0;
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            topInset +
                (textScale > 1.6
                    ? 108
                    : textScale > 1.35
                        ? 98
                        : 88),
            horizontal,
            bottomInset + (textScale > 1.35 ? 128 : 112),
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _CustomizationCanvas(
                  state: state,
                  jiggle: _jiggleController,
                  onDragUpdate: _autoScroll,
                  onRetrySave: _finishEditing,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestClose() async {
    if (_closing) return;
    final state = _customizationCubit.state;
    if (state is! HomeCustomizationReady || state.isSaving) return;
    if (!state.hasChanges) {
      _closing = true;
      _customizationCubit.cancelEditing();
      await _popEditor();
      return;
    }

    _closing = true;
    final outcome = await showUnsavedChangesConfirmation(context);
    if (!mounted) return;
    switch (outcome) {
      case HomeCustomizationCloseOutcome.save:
        await _applyAndClose(closeGuardHeld: true);
        return;
      case HomeCustomizationCloseOutcome.discard:
        _customizationCubit.cancelEditing();
        if (mounted) await _popEditor();
        return;
      case HomeCustomizationCloseOutcome.keepEditing:
        _closing = false;
        return;
    }
  }

  Future<void> _finishEditing() async {
    await _applyAndClose();
  }

  Future<void> _applyAndClose({bool closeGuardHeld = false}) async {
    if (!closeGuardHeld) {
      if (_closing) return;
      _closing = true;
    }
    final success = await _customizationCubit.applyDraft();
    if (!mounted) return;
    if (!success) {
      _closing = false;
      final l10n = AppLocalizations.of(context)!;
      HudaSnackBar.error(
        context,
        message: l10n.homeChangesSaveFailed,
        action: HudaSnackBarAction(
          label: l10n.retry,
          onPressed: _finishEditing,
        ),
        dismissible: true,
        replaceCurrent: false,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    await _popEditor(result: true);
  }

  Future<void> _popEditor({Object? result}) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  void _resetCurrentTheme() {
    _customizationCubit.resetCurrentTheme();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    HudaSnackBar.success(context, message: l10n.themeResetMessage);
  }

  void _autoScroll(DragUpdateDetails details) {
    if (!_scrollController.hasClients) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;
    final local = renderObject.globalToLocal(details.globalPosition);
    final size = renderObject.size;
    final topEdge = MediaQuery.paddingOf(context).top + 92.0;
    final bottomEdge =
        size.height - MediaQuery.paddingOf(context).bottom - 98.0;
    var delta = 0.0;
    if (local.dy < topEdge) {
      delta = -math.min(18.0, (topEdge - local.dy) / 3);
    } else if (local.dy > bottomEdge) {
      delta = math.min(18.0, (local.dy - bottomEdge) / 3);
    }
    if (delta == 0) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _scrollController.jumpTo(target);
  }
}

class _CustomizationCanvas extends StatelessWidget {
  const _CustomizationCanvas({
    required this.state,
    required this.jiggle,
    required this.onDragUpdate,
    required this.onRetrySave,
  });

  final HomeCustomizationReady state;
  final Animation<double> jiggle;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onRetrySave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HomeCustomizationCubit>();
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
        if (state.saveError != null) ...[
          _SaveErrorNotice(onRetry: onRetrySave),
          const SizedBox(height: 14),
        ],
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.975, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: CustomizationThemeBanner(
            key: ValueKey(draft.selectedTheme),
            theme: draft.selectedTheme,
            configuration: configuration,
          ),
        ),
        const SizedBox(height: 16),
        const _EditorInstruction(),
        if (sections.isNotEmpty) ...[
          const SizedBox(height: 34),
          CustomizationSectionHeading(
            icon: Icons.view_agenda_rounded,
            title: l10n.homeSections,
            visibleCount: sections
                .where(
                  (section) => !configuration.hiddenSections.contains(section),
                )
                .length,
            totalCount: sections.length,
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              return AnimatedReorderLayout<HomeSectionId>(
                items: sections,
                columns: columns,
                itemExtent: 68 + (textScale - 1).clamp(0, 1) * 24,
                spacing: 11,
                semanticLabelBuilder: (section) =>
                    homeSectionName(context, section),
                onDragUpdate: onDragUpdate,
                onReorder: (dragged, target) {
                  HapticFeedback.selectionClick();
                  cubit.reorderSections(dragged, target);
                },
                itemBuilder: (context, section, lifted) {
                  final visible =
                      !configuration.hiddenSections.contains(section);
                  return EditableHomeSectionCard(
                    title: homeSectionName(context, section),
                    icon: homeSectionIcon(section),
                    visible: visible,
                    lifted: lifted,
                    seed: section.index,
                    jiggle: jiggle,
                    onVisibilityChanged: (value) =>
                        cubit.setSectionVisibility(section, visible: value),
                  );
                },
              );
            },
          ),
        ],
        const SizedBox(height: 34),
        CustomizationSectionHeading(
          icon: Icons.grid_view_rounded,
          title: l10n.primaryCards,
          visibleCount: primary
              .where(
                (feature) => !configuration.hiddenFeatures.contains(feature),
              )
              .length,
          totalCount: primary.length,
        ),
        const SizedBox(height: 14),
        _FeatureReorderGrid(
          ids: primary,
          definitions: definitions,
          hidden: configuration.hiddenFeatures,
          primary: true,
          jiggle: jiggle,
          onDragUpdate: onDragUpdate,
        ),
        const SizedBox(height: 34),
        CustomizationSectionHeading(
          icon: Icons.expand_more_rounded,
          title: l10n.viewMore,
          visibleCount: more
              .where(
                (feature) => !configuration.hiddenFeatures.contains(feature),
              )
              .length,
          totalCount: more.length,
        ),
        const SizedBox(height: 14),
        if (more.isEmpty)
          const _EmptyMoreArea()
        else
          _FeatureReorderGrid(
            ids: more,
            definitions: definitions,
            hidden: configuration.hiddenFeatures,
            primary: false,
            jiggle: jiggle,
            onDragUpdate: onDragUpdate,
          ),
      ],
    );
  }
}

class _EditorInstruction extends StatelessWidget {
  const _EditorInstruction();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.customizeHomeHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveErrorNotice extends StatelessWidget {
  const _SaveErrorNotice({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('home-customization-save-error'),
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.homeChangesSaveFailed,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
              ),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureReorderGrid extends StatelessWidget {
  const _FeatureReorderGrid({
    required this.ids,
    required this.definitions,
    required this.hidden,
    required this.primary,
    required this.jiggle,
    required this.onDragUpdate,
  });

  final List<HomeFeatureId> ids;
  final Map<HomeFeatureId, HomeFeatureDefinition> definitions;
  final Set<HomeFeatureId> hidden;
  final bool primary;
  final Animation<double> jiggle;
  final ValueChanged<DragUpdateDetails> onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCustomizationCubit>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final itemExtent = 128.0 + (textScale - 1).clamp(0.0, 1.0) * 36.0;
        return AnimatedReorderLayout<HomeFeatureId>(
          items: ids,
          columns: columns,
          itemExtent: itemExtent,
          spacing: constraints.maxWidth < 500 ? 10 : 13,
          onDragUpdate: onDragUpdate,
          semanticLabelBuilder: (id) => definitions[id]?.title ?? id.name,
          onReorder: (dragged, target) {
            HapticFeedback.selectionClick();
            cubit.reorderFeature(
              primary: primary,
              dragged: dragged,
              target: target,
            );
          },
          itemBuilder: (context, id, lifted) {
            final definition = definitions[id];
            if (definition == null) return const SizedBox.shrink();
            return EditableHomeFeatureCard(
              feature: definition,
              visible: !hidden.contains(id),
              primary: primary,
              lifted: lifted,
              jiggle: jiggle,
              onVisibilityChanged: (visible) =>
                  cubit.setFeatureVisibility(id, visible: visible),
              onMove: () {
                HapticFeedback.selectionClick();
                cubit.moveFeature(id, toPrimary: !primary);
              },
            );
          },
        );
      },
    );
  }

  int _columnsFor(double width) {
    if (width >= 980) return 6;
    if (width >= 800) return 5;
    if (width >= 620) return 4;
    if (width >= 450) return 3;
    return 2;
  }
}

class _EmptyMoreArea extends StatelessWidget {
  const _EmptyMoreArea();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Icon(
        Icons.keyboard_double_arrow_down_rounded,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.46),
      ),
    );
  }
}

class _EditorBackground extends StatelessWidget {
  const _EditorBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tinted = Color.alphaBlend(
      context.primaryColor.withValues(alpha: isDark ? 0.075 : 0.045),
      scheme.surface,
    );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tinted, scheme.surface, scheme.surfaceContainerLowest],
          stops: const [0, 0.46, 1],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 14),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _noop() {}
