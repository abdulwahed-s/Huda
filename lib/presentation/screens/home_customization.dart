import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/home_customization/home_customization_cubit.dart';
import 'package:huda/cubit/home_customization/home_customization_state.dart';
import 'package:huda/data/models/home/home_preferences.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/feedback/huda_snack_bar.dart';
import 'package:huda/presentation/widgets/home/catalog/home_feature_catalog.dart';
import 'package:huda/presentation/widgets/home_customization/animated_reorder_layout.dart';
import 'package:huda/presentation/widgets/home_customization/customization_cards.dart';
import 'package:huda/presentation/widgets/home_customization/customization_chrome.dart';
import 'package:huda/presentation/widgets/home_customization/customization_theme_banner.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_labels.dart';
import 'package:huda/presentation/widgets/home_customization/home_customization_sheets.dart';
import 'package:huda/presentation/widgets/home_customization/unsaved_changes_confirmation.dart';

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

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestCancel();
          },
          child: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(child: _EditorBackground()),
                Positioned.fill(child: _buildScrollableEditor(customization)),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomizationEditorTopBar(
                    hasChanges: customization.hasChanges,
                    isSaving: customization.isSaving,
                    onCancel: _requestCancel,
                    onSave: _saveAndClose,
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
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final textScale = mediaQuery.textScaler.scale(1);
    final compactTopBar = width < 380 || textScale > 1.35;
    final topPadding = mediaQuery.padding.top + (compactTopBar ? 112 : 88);
    final bottomPadding = mediaQuery.viewPadding.bottom + 36;

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            16,
            topPadding,
            16,
            bottomPadding,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _CustomizationCanvas(
                  state: state,
                  onDragUpdate: _autoScroll,
                  onRetrySave: _saveAndClose,
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
        size.height - MediaQuery.viewPaddingOf(context).bottom - 32;
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
    if (state is! HomeCustomizationReady || state.isSaving) return;
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
    final success = await _customizationCubit.applyDraft();
    if (!mounted) return;
    if (!success) {
      _closing = false;
      final l10n = AppLocalizations.of(context)!;
      HudaSnackBar.error(
        context,
        message: l10n.homeChangesSaveFailed,
        action: HudaSnackBarAction(label: l10n.retry, onPressed: _saveAndClose),
        dismissible: true,
        replaceCurrent: false,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    await _popEditor(result: true);
  }

  Future<void> _restoreDefaultLayout() async {
    final confirmed = await showRestoreDefaultLayoutConfirmation(context);
    if (!mounted || !confirmed) return;
    HapticFeedback.mediumImpact();
    _customizationCubit.resetCurrentTheme();
  }

  Future<void> _popEditor({Object? result}) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }
}

class _CustomizationCanvas extends StatelessWidget {
  const _CustomizationCanvas({
    required this.state,
    required this.onDragUpdate,
    required this.onRetrySave,
    required this.onRestoreDefault,
  });

  final HomeCustomizationReady state;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onRetrySave;
  final VoidCallback onRestoreDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.saveError != null) ...[
          _SaveErrorNotice(onRetry: onRetrySave),
          const SizedBox(height: 14),
        ],
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300),
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
            onEdit: () => showHomeThemePicker(context),
          ),
        ),
        const SizedBox(height: 16),
        const _EditorInstruction(),
        if (sections.isNotEmpty) ...[
          const SizedBox(height: 30),
          CustomizationSectionHeading(title: l10n.homeSections),
          const SizedBox(height: 12),
          _SectionReorderGrid(sections: sections, onDragUpdate: onDragUpdate),
        ],
        const SizedBox(height: 30),
        CustomizationSectionHeading(title: l10n.onHome),
        const SizedBox(height: 12),
        _AnimatedGroupBody(
          empty: primary.isEmpty,
          emptyKey: 'home-empty',
          emptyIcon: Icons.home_outlined,
          child: _FeatureReorderGrid(
            key: const ValueKey('home-feature-grid'),
            ids: primary,
            definitions: definitions,
            primary: true,
            onDragUpdate: onDragUpdate,
          ),
        ),
        const SizedBox(height: 30),
        CustomizationSectionHeading(title: l10n.viewMore),
        const SizedBox(height: 12),
        _AnimatedGroupBody(
          empty: more.isEmpty,
          emptyKey: 'view-more-empty',
          emptyIcon: Icons.keyboard_double_arrow_down_rounded,
          emptyMessage: l10n.viewMoreEmpty,
          child: _FeatureReorderGrid(
            key: const ValueKey('view-more-feature-grid'),
            ids: more,
            definitions: definitions,
            primary: false,
            onDragUpdate: onDragUpdate,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('restore-default-layout'),
            onPressed: state.isSaving ? null : onRestoreDefault,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.restoreDefaultLayout),
          ),
        ),
      ],
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
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final itemExtent = 70.0 + (textScale - 1).clamp(0.0, 1.0) * 28.0;
        return AnimatedReorderLayout<HomeSectionId>(
          items: sections,
          columns: columns,
          itemExtent: itemExtent,
          spacing: 11,
          moveUpLabel: l10n.moveUp,
          moveDownLabel: l10n.moveDown,
          semanticLabelBuilder: (section) => homeSectionName(context, section),
          onDragUpdate: onDragUpdate,
          onReorder: (dragged, target) {
            final fromIndex = sections.indexOf(dragged);
            final toIndex = sections.indexOf(target);
            if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;
            HapticFeedback.selectionClick();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = _columnsFor(constraints.maxWidth, textScale);
        final spacing = constraints.maxWidth < 500 ? 10.0 : 13.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final itemExtent = textScale > 1.35
            ? math.max(198.0, math.min(itemWidth, 230.0))
            : math.max(164.0, itemWidth);
        return AnimatedReorderLayout<HomeFeatureId>(
          items: ids,
          columns: columns,
          itemExtent: itemExtent,
          spacing: spacing,
          moveUpLabel: l10n.moveUp,
          moveDownLabel: l10n.moveDown,
          semanticLabelBuilder: (id) => definitions[id]?.title ?? id.name,
          onDragUpdate: onDragUpdate,
          onReorder: (dragged, target) {
            final fromIndex = ids.indexOf(dragged);
            final toIndex = ids.indexOf(target);
            if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;
            HapticFeedback.selectionClick();
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
                HapticFeedback.selectionClick();
                cubit.moveFeature(id, toPrimary: !primary);
              },
            );
          },
        );
      },
    );
  }

  int _columnsFor(double width, double textScale) {
    if (textScale > 1.35) {
      if (width >= 800) return 3;
      if (width >= 520) return 2;
      return 1;
    }
    if (width >= 980) return 6;
    if (width >= 800) return 5;
    if (width >= 620) return 4;
    if (width >= 450) return 3;
    return 2;
  }
}

class _AnimatedGroupBody extends StatelessWidget {
  const _AnimatedGroupBody({
    required this.empty,
    required this.emptyKey,
    required this.emptyIcon,
    required this.child,
    this.emptyMessage,
  });

  final bool empty;
  final String emptyKey;
  final IconData emptyIcon;
  final String? emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: empty
            ? _EmptyGroupArea(
                key: ValueKey(emptyKey),
                icon: emptyIcon,
                message: emptyMessage,
              )
            : child,
      ),
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
          color: scheme.surfaceContainerLow.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.customizeHomeHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _EmptyGroupArea extends StatelessWidget {
  const _EmptyGroupArea({super.key, required this.icon, this.message});

  final IconData icon;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.onSurfaceVariant.withValues(alpha: 0.58)),
            if (message != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
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
      borderRadius: BorderRadius.circular(16),
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
