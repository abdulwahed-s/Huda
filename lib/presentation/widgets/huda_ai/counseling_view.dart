import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/insets.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/data/models/chat_error.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/design/huda_motion.dart';
import 'package:huda/presentation/widgets/design/huda_states.dart';
import 'package:huda/presentation/widgets/design/huda_surfaces.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_conversation.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_turns.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_identity.dart';
import 'package:huda/presentation/widgets/huda_ai/huda_ai_text.dart';

/// Counseling: one feeling, one counsel, as a page rather than a chat
/// (owner round 1: each request is its own session, so the chat's bubbles
/// and composer suggested a thread that wasn't there).
///
/// - **Write**: the breathing light, "What's on your heart?", a writing
///   area in the page with the feelings as quick picks, and a lit Seek
///   counsel.
/// - **Waiting**: the feeling quoted, the full gathering of light centered.
/// - **Failed**: the feeling, what failed, Retry (or Edit after a safety
///   refusal).
/// - **Counsel**: opened by the quoted feeling, then Guidance, the ayah and
///   the duaa rising in by section, Copy and Share, and "Share another
///   feeling" for a new one.
class CounselingView extends StatefulWidget {
  const CounselingView({
    super.key,
    required this.sessionId,
    required this.feeling,
    required this.response,
    required this.waiting,
    required this.errorType,
    required this.retrying,
    required this.controller,
    required this.canSeek,
    required this.busyElsewhere,
    required this.onSeek,
    required this.onRetry,
    required this.onEdit,
    required this.onCopy,
    required this.onShare,
    required this.onAnother,
  });

  final String? sessionId;
  final String? feeling;
  final CounselingResponse? response;
  final bool waiting;
  final ChatErrorType? errorType;
  final bool retrying;

  /// The writing area's text, kept by the screen (it survives switching
  /// modes and comes back for Edit).
  final TextEditingController controller;

  /// No other answer is being generated.
  final bool canSeek;

  /// Another conversation is being answered ([canSeek] is false).
  final bool busyElsewhere;
  final ValueChanged<String> onSeek;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onAnother;

  /// The writing page's width.
  static const double writingMeasure = 600;

  @override
  State<CounselingView> createState() => _CounselingViewState();
}

enum _Phase { write, waiting, failed, counsel }

class _CounselingViewState extends State<CounselingView> {
  /// A counsel already there when it opened doesn't rise in.
  late bool _arrived = widget.response == null;

  @override
  void didUpdateWidget(CounselingView old) {
    super.didUpdateWidget(old);
    if (old.sessionId != widget.sessionId) {
      _arrived = widget.response == null && widget.sessionId != null;
    } else if (old.response == null && widget.response != null) {
      _arrived = true;
    }
  }

  _Phase get _phase {
    if (widget.response != null) return _Phase.counsel;
    if (widget.sessionId == null) return _Phase.write;
    if (widget.waiting) return _Phase.waiting;
    if (widget.errorType != null) return _Phase.failed;
    return _Phase.write;
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phase;
    final Widget page = switch (phase) {
      _Phase.write => _WritePage(
        controller: widget.controller,
        canSeek: widget.canSeek,
        busyElsewhere: widget.busyElsewhere,
        onSeek: widget.onSeek,
      ),
      _Phase.waiting => _WaitingPage(
        feeling: widget.feeling,
        retrying: widget.retrying,
      ),
      _Phase.failed => _FailedPage(
        feeling: widget.feeling,
        error: widget.errorType!,
        onRetry: widget.onRetry,
        onEdit: widget.onEdit,
      ),
      _Phase.counsel => _CounselPage(
        feeling: widget.feeling,
        response: widget.response!,
        arrived: _arrived,
        onCopy: widget.onCopy,
        onShare: widget.onShare,
        onAnother: widget.onAnother,
      ),
    };
    return HudaStateSwitcher(
      // One key per session: waiting, failed and the counsel swap in place
      // under the same quoted feeling (it would blink in a cross-fade).
      stateKey: phase == _Phase.write ? 'write' : 'session-${widget.sessionId}',
      sequential: true,
      child: page,
    );
  }
}

/// A page at [measure], scrolling, its insets inside the scroll view;
/// [center] keeps a short page in the middle of the room.
class _Page extends StatelessWidget {
  const _Page({
    required this.children,
    this.measure = ChatConversation.measure,
    this.center = false,
    this.listKey,
  });

  final List<Widget> children;
  final double measure;
  final bool center;
  final Key? listKey;

  @override
  Widget build(BuildContext context) {
    final space = context.tokens.space;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = hudaAiSidePadding(context, constraints.maxWidth, measure);
        final padding = context.scrollPadding(
          EdgeInsets.fromLTRB(side, space.lg, side, space.xxl),
        );
        if (!center) {
          return ListView(key: listKey, padding: padding, children: children);
        }
        return SingleChildScrollView(
          key: listKey,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - padding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// "What's on your heart?": the writing page.
class _WritePage extends StatefulWidget {
  const _WritePage({
    required this.controller,
    required this.canSeek,
    required this.busyElsewhere,
    required this.onSeek,
  });

  final TextEditingController controller;
  final bool canSeek;
  final bool busyElsewhere;
  final ValueChanged<String> onSeek;

  @override
  State<_WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<_WritePage> {
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _ready => widget.canSeek && widget.controller.text.trim().isNotEmpty;

  void _seek() {
    if (_ready) widget.onSeek(widget.controller.text.trim());
  }

  /// Enter is a new line in a letter; Ctrl or ⌘ + Enter sends it.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (!keyboard.isControlPressed && !keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    _seek();
    return KeyEventResult.handled;
  }

  /// A quick pick starts the letter; there's room to say more.
  void _pick(String text) {
    widget.controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final space = tokens.space;
    // Laid out by the room this page really gets (a tabletop half, a pane)
    // and the text size, so the writing area always has the room.
    final size = MediaQuery.sizeOf(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final large = scale >= 1.5;
    final short =
        !large && (context.windowClass.isCompactHeight || size.height < 520);
    // Small phones: a smaller light and a shorter page, so the field and
    // the quick picks show above Seek counsel.
    final small = !short && size.height < 720;
    final roomy = size.width >= 840 && size.height >= 800;
    final showIntro = !large && size.height >= 380;
    final feelings = [
      (Icons.air_rounded, l10n.exampleFeelAnxious),
      (Icons.waves_rounded, l10n.exampleFeelOverwhelmed),
      (Icons.wb_twilight_rounded, l10n.exampleFeelingGrateful),
      (Icons.spa_outlined, l10n.exampleSeekingPeace),
    ];

    final noor = HudaAiNoor(
      size: large || short ? 56 : (small ? 72 : (roomy ? 160 : 120)),
      entrance: true,
      breathing: true,
    );
    final heading = Semantics(
      header: true,
      child: Text(
        l10n.hudaAiCounselHeading,
        textAlign: short ? TextAlign.start : TextAlign.center,
        style:
            (short ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
                ?.copyWith(color: scheme.onSurface),
      ),
    );
    final intro = Text(
      l10n.counselingIntro,
      textAlign: short ? TextAlign.start : TextAlign.center,
      style: (short ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
    final head = short
        ? Row(
            children: [
              noor,
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading,
                    if (showIntro) ...[SizedBox(height: space.xxs), intro],
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              noor,
              SizedBox(height: space.md),
              heading,
              if (showIntro) ...[SizedBox(height: space.xs), intro],
            ],
          );

    final border = OutlineInputBorder(
      borderRadius: tokens.radius.card,
      borderSide: BorderSide(color: scheme.outline),
    );
    final field = TextField(
      key: const ValueKey('huda_ai_feeling'),
      controller: widget.controller,
      focusNode: _focus,
      minLines: large || short || small ? 2 : (roomy ? 6 : 4),
      maxLines: 10,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: l10n.hudaAiCounselingHint,
        hintMaxLines: 1,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: EdgeInsets.all(space.md),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );

    final picks = Wrap(
      spacing: space.xs,
      runSpacing: space.xs,
      children: [
        for (final (icon, text) in feelings)
          ActionChip(
            avatar: Icon(icon, size: 18, color: tokens.ornament),
            label: Text(text),
            onPressed: () => _pick(text),
          ),
      ],
    );

    final insets = MediaQuery.paddingOf(context);
    // Seek counsel is pinned to the bottom edge, so it's always in reach
    // (its surface runs under the navigation bar, the button lifted by
    // the inset); the letter scrolls above it.
    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      // The page's own measure, so the button lines up with the field.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = hudaAiSidePadding(
            context,
            constraints.maxWidth,
            CounselingView.writingMeasure,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              insets.left + side,
              space.xs,
              insets.right + side,
              space.xs + context.bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.busyElsewhere)
                  HudaAiStatusLine(text: l10n.aiBusyOtherConversation),
                FilledButton(
                  key: const ValueKey('huda_ai_seek'),
                  onPressed: _ready ? _seek : null,
                  child: Text(l10n.hudaAiSeekCounsel),
                ),
              ],
            ),
          );
        },
      ),
    );

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            // The bar owns the bottom edge.
            removeBottom: true,
            child: HudaRevealScope(
              child: _Page(
                measure: CounselingView.writingMeasure,
                center: !short,
                children: [
                  HudaReveal(index: 0, child: head),
                  SizedBox(height: short || small ? space.md : space.xl),
                  HudaReveal(index: 1, child: field),
                  SizedBox(height: space.sm),
                  HudaReveal(index: 2, child: picks),
                  SizedBox(height: space.md),
                  const HudaReveal(index: 3, child: _Receives()),
                ],
              ),
            ),
          ),
        ),
        bar,
      ],
    );
  }
}

/// What a counsel brings: guidance, a verse and a duaa.
class _Receives extends StatelessWidget {
  const _Receives();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    return Wrap(
      spacing: space.md,
      runSpacing: space.xxs,
      children: [
        for (final (icon, label) in [
          (Icons.light_mode_outlined, l10n.guidanceTitle),
          (Icons.menu_book_outlined, l10n.quranTitle),
          (Icons.front_hand_outlined, l10n.duaaTitle),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: context.tokens.ornament),
              SizedBox(width: space.xxs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// The feeling as the counsel's opening line: a quotation under a gilt
/// rule at its start, not a chat bubble.
class _FeelingQuote extends StatelessWidget {
  const _FeelingQuote(this.feeling);

  final String feeling;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Semantics(
      label: l10n.hudaAiYouShared,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: tokens.ornament,
              width: tokens.stroke.bold,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: tokens.space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HudaEyebrow(l10n.hudaAiYouShared),
              SizedBox(height: tokens.space.xxs),
              SelectableText(
                feeling,
                textDirection: hudaAiTextDirection(feeling),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The counsel is coming: the feeling, and the full gathering of light in
/// the middle of the page.
class _WaitingPage extends StatelessWidget {
  const _WaitingPage({required this.feeling, required this.retrying});

  final String? feeling;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final space = context.tokens.space;
    final feeling = this.feeling?.trim();
    final title = retrying ? l10n.stateRetrying : l10n.hudaAIThinking;
    final short = context.windowClass.isCompactHeight;
    // The quote stays where the counsel will open, at the top.
    return _Page(
      children: [
        if (feeling != null && feeling.isNotEmpty) ...[
          _FeelingQuote(feeling),
          SizedBox(height: short ? space.lg : space.giant),
        ],
        Semantics(
          liveRegion: true,
          label: title,
          excludeSemantics: true,
          child: Column(
            key: const ValueKey('huda_ai_thinking'),
            children: [
              HudaAiNoor(size: short ? 88 : 160, gathering: true),
              SizedBox(height: space.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: space.xxs),
              Text(
                l10n.analyzingQuestion,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FailedPage extends StatelessWidget {
  const _FailedPage({
    required this.feeling,
    required this.error,
    required this.onRetry,
    required this.onEdit,
  });

  final String? feeling;
  final ChatErrorType error;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final feeling = this.feeling?.trim();
    final safety = error == ChatErrorType.safetyFilter;
    return _Page(
      children: [
        if (feeling != null && feeling.isNotEmpty) ...[
          _FeelingQuote(feeling),
          SizedBox(height: space.xl),
        ],
        HudaAiRiseIn(
          child: HudaStatusBanner(
            status: HudaStatus.failed,
            message: hudaAiErrorMessage(l10n, error),
            // Sharing the same again won't pass the safety check.
            onRetry: safety ? null : onRetry,
          ),
        ),
        if (safety) ...[
          SizedBox(height: space.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('huda_ai_edit'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.edit),
            ),
          ),
        ],
      ],
    );
  }
}

/// The counsel: one composed page, opened by the feeling.
class _CounselPage extends StatelessWidget {
  const _CounselPage({
    required this.feeling,
    required this.response,
    required this.arrived,
    required this.onCopy,
    required this.onShare,
    required this.onAnother,
  });

  final String? feeling;
  final CounselingResponse response;
  final bool arrived;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final space = context.tokens.space;
    final r = response;
    final feeling = this.feeling?.trim();
    final sections = <Widget>[
      if (r.counselingText.trim().isNotEmpty)
        _Section(
          title: l10n.guidance,
          child: HudaAiMarkdown(r.counselingText.trim()),
        ),
      if (r.ayah.trim().isNotEmpty)
        _Section(
          title: l10n.quranicWisdom,
          child: _Scripture(
            arabic: r.ayah.trim(),
            translation: r.ayahTranslation.trim(),
            reference: r.ayahReference.trim(),
          ),
        ),
      if (r.duaa.trim().isNotEmpty)
        _Section(
          title: l10n.duaa,
          child: _Scripture(
            arabic: r.duaa.trim(),
            translation: r.duaaTranslation.trim(),
          ),
        ),
    ];
    var step = 0;
    Widget rise(Widget child) => HudaAiRiseIn(
      animate: arrived,
      delay: Duration(milliseconds: 140 * step++),
      child: child,
    );
    return _Page(
      listKey: const ValueKey('huda_ai_counsel_list'),
      children: [
        if (feeling != null && feeling.isNotEmpty) ...[
          _FeelingQuote(feeling),
          SizedBox(height: space.xl),
        ],
        rise(const HudaAiTurnHeader()),
        SizedBox(height: space.md),
        for (var i = 0; i < sections.length; i++)
          rise(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (i > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: space.lg),
                    child: const HudaAiMoteDivider(),
                  ),
                sections[i],
              ],
            ),
          ),
        SizedBox(height: space.sm),
        rise(HudaAiAnswerActions(onCopy: onCopy, onShare: onShare)),
        SizedBox(height: space.xl),
        rise(
          Center(
            child: FilledButton.icon(
              key: const ValueKey('huda_ai_another'),
              onPressed: onAnother,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.hudaAiAnotherFeeling),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(header: true, child: HudaEyebrow(title)),
      SizedBox(height: context.tokens.space.sm),
      child,
    ],
  );
}

/// An ayah or a duaa: the Arabic first and large, its meaning and its
/// source below, on a quiet panel.
class _Scripture extends StatelessWidget {
  const _Scripture({
    required this.arabic,
    this.translation = '',
    this.reference = '',
  });

  final String arabic;
  final String translation;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: tokens.radius.card,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space.lg,
          vertical: tokens.space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: context.type.hadith.copyWith(color: scheme.onSurface),
            ),
            if (translation.isNotEmpty) ...[
              SizedBox(height: tokens.space.xs),
              SelectableText(
                translation,
                textAlign: TextAlign.center,
                textDirection: hudaAiTextDirection(translation),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (reference.isNotEmpty) ...[
              SizedBox(height: tokens.space.xs),
              Text(
                reference,
                textAlign: TextAlign.center,
                textDirection: hudaAiTextDirection(reference),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
