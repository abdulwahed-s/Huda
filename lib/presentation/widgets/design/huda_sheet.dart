import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';

Future<T?> showHudaSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double maxDialogWidth = 560,
  bool sideSheet = false,
  bool expand = false,
  WidgetBuilder? footer,
}) {
  final tokens = context.tokens;
  final size = MediaQuery.sizeOf(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final fold = FoldInfo.of(context);
  final split = fold.avoided;
  final vertical = split && fold.splitsHorizontally;
  final horizontal = split && !fold.splitsHorizontally;
  final anchor = Offset(
    rtl ? 0 : size.width,
    horizontal ? size.height : size.height / 2,
  );

  var side = EdgeInsets.zero;
  if (vertical) {
    side = rtl
        ? EdgeInsets.only(right: size.width - fold.start)
        : EdgeInsets.only(left: fold.end);
  } else if (horizontal) {
    side = EdgeInsets.only(top: fold.end);
  }
  final sideSize = side.deflateSize(size);
  Widget onSide(BuildContext context, Widget child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(size: sideSize),
    child: child,
  );

  if (sideSheet &&
      context.windowClass.width >= WindowWidthClass.expanded &&
      !split) {
    final barrier = MaterialLocalizations.of(context).modalBarrierDismissLabel;
    final curve = tokens.motion.standard;
    final themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context, rootNavigator: true).context,
    );
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrier,
      barrierColor: tokens.chrome.withValues(alpha: 0.55),
      transitionDuration: tokens.motion.of(context, tokens.motion.medium),
      pageBuilder: (context, _, _) => themes.wrap(
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: 400,
              height: double.infinity,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: Radius.circular(context.tokens.radius.xl),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  left: !rtl,
                  right: rtl,
                  bottom: false,
                  child: HudaSheetFrame(
                    title: title,
                    dialog: true,
                    reachesBottom: true,
                    expand: expand,
                    footer: footer?.call(context),
                    child: builder(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: curve);
        return SlideTransition(
          position: Tween(
            begin: Offset(rtl ? -1 : 1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  final scrim = tokens.chrome.withValues(alpha: 0.55);
  const motion = HudaMotion();
  final instant = motion.of(context, motion.long) == Duration.zero;
  final style = instant ? AnimationStyle.noAnimation : null;

  if (context.windowClass.isCompact) {
    final column = SideChrome.sideOf(context);
    final top = column == null
        ? MediaQuery.viewPaddingOf(context).top
        : math.max(
            MediaQuery.viewPaddingOf(context).top,
            SideChrome.freeTop(context, column),
          );
    final ownHandle = column != null;
    return showModalBottomSheet<T>(
      context: context,
      barrierColor: scrim,
      sheetAnimationStyle: style,
      isScrollControlled: true,
      showDragHandle: ownHandle ? false : null,
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: math.max(0, size.height - top - 8),
      ),
      anchorPoint: anchor,
      builder: (context) => onSide(
        context,
        Builder(
          builder: (context) => HudaSheetFrame(
            title: title,
            dialog: false,
            dragHandle: ownHandle,
            expand: expand,
            footer: footer?.call(context),
            child: builder(context),
          ),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    anchorPoint: anchor,
    barrierColor: scrim,
    animationStyle: style,
    builder: (context) => onSide(
      context,
      Padding(
        padding: SideChrome.clearance(context),
        child: Builder(
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxDialogWidth),
              child: HudaSheetFrame(
                title: title,
                dialog: true,
                expand: expand,
                footer: footer?.call(context),
                child: builder(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HudaSheetFrame extends StatelessWidget {
  const HudaSheetFrame({
    super.key,
    required this.title,
    required this.child,
    required this.dialog,
    this.reachesBottom,
    this.dragHandle = false,
    this.expand = false,
    this.footer,
  });

  final String title;

  final Widget? footer;

  final bool expand;
  final Widget child;
  final bool dialog;

  final bool dragHandle;

  final bool? reachesBottom;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final space = tokens.space;
    final edge = reachesBottom ?? !dialog;
    final insets = MediaQuery.paddingOf(context);
    final surface = Theme.of(context).brightness;
    if (expand) {
      final body = Semantics(
        label: title,
        explicitChildNodes: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: dialog && !edge ? 760 : double.infinity,
          ),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (dragHandle)
                  SizedBox(
                    height: kMinInteractiveDimension,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).bottomSheetTheme.dragHandleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: edge
                      ? child
                      : MediaQuery.removePadding(
                          context: context,
                          removeBottom: true,
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!edge) return body;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: HudaSystemUi.over(top: surface, bottom: surface),
        child: body,
      );
    }
    final frame = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dragHandle)
          Padding(
            padding: EdgeInsets.only(left: insets.left, right: insets.right),
            child: SizedBox(
              height: kMinInteractiveDimension,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).bottomSheetTheme.dragHandleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding:
              EdgeInsetsDirectional.fromSTEB(
                space.xl,
                dialog ? space.md : 0,
                dialog ? space.xs : space.xl,
                space.xs,
              ).add(
                edge
                    ? EdgeInsets.only(left: insets.left, right: insets.right)
                    : EdgeInsets.zero,
              ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              if (dialog)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              space.xl + (edge ? insets.left : 0),
              space.xs,
              space.xl + (edge ? insets.right : 0),
              footer != null
                  ? space.md
                  : space.xl + (edge ? insets.bottom : 0),
            ),
            child: child,
          ),
        ),
        if (footer case final footer?)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                space.xl + (edge ? insets.left : 0),
                space.sm,
                space.xl + (edge ? insets.right : 0),
                (dialog ? space.md : space.sm) + (edge ? insets.bottom : 0),
              ),
              child: footer,
            ),
          ),
      ],
    );
    if (!edge) return frame;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: surface, bottom: surface),
      child: frame,
    );
  }
}
