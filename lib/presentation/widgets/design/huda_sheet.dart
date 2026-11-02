import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/layout/fold.dart';
import 'package:huda/core/layout/window_class.dart';
import 'package:huda/core/theme/huda_system_ui.dart';
import 'package:huda/core/theme/huda_tokens.dart';
import 'package:huda/presentation/widgets/design/huda_app_bars.dart';

/// The adaptive sheet presenter: a bottom sheet on compact width, a dialog
/// on medium and wider, and optionally a side sheet on expanded windows.
///
/// A flat fold is one screen: the sheet centers on the whole window, as on
/// a tablet of that size, even across the crease. A half-open fold (book or
/// tabletop), or a fold with a width (a hinge), splits the screen: the sheet
/// stays on the trailing side of a vertical fold (where the content will be
/// when the device closes) or the bottom of a horizontal one, and inside it
/// `MediaQuery.sizeOf` is that side, so content sizes itself to the space it
/// really has. Flutter's routes keep it there from the [anchorPoint]. See
/// `design/RESPONSIVE.md`, "A flat fold is one screen".
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
  // The folds Flutter's dialog and sheet routes avoid. A flat zero-width
  // fold isn't one of them, and shouldn't be.
  final split = fold.avoided;
  final vertical = split && fold.splitsHorizontally;
  final horizontal = split && !fold.splitsHorizontally;
  final anchor = Offset(
    rtl ? 0 : size.width,
    horizontal ? size.height : size.height / 2,
  );

  // The side the sheet lives on, and how far it is from each window edge.
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

  // Side sheets suit secondary panels (filters, details) on wide windows,
  // flat folds included; on a split screen the dialog keeps to one side.
  if (sideSheet &&
      context.windowClass.width >= WindowWidthClass.expanded &&
      !split) {
    final barrier = MaterialLocalizations.of(context).modalBarrierDismissLabel;
    // Unlike showDialog, showGeneralDialog doesn't carry the screen's
    // themes (a route-level theme such as `HudaNight`) into the overlay
    // (found by `quran`).
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
                // Top and trailing insets; the frame adds the bottom one
                // inside its scroll view.
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

  // A scrim tinted from the chrome, and no motion under reduce motion.
  final scrim = tokens.chrome.withValues(alpha: 0.55);
  const motion = HudaMotion();
  final instant = motion.of(context, motion.long) == Duration.zero;
  final style = instant ? AnimationStyle.noAnimation : null;

  if (context.windowClass.isCompact) {
    // Edge to edge: the surface runs under the side insets (the iPhone
    // Duo's side column) and the navigation bar, and the frame insets its
    // content. Only the top stays below the status bar.
    // Beside the iPhone Duo's side column the sheet also stays below the
    // column's camera and status items, so no corner reaches under them.
    final column = SideChrome.sideOf(context);
    final top = column == null
        ? MediaQuery.viewPaddingOf(context).top
        : math.max(
            MediaQuery.viewPaddingOf(context).top,
            SideChrome.freeTop(context, column),
          );
    // Beside the iPhone Duo's side column the frame draws the handle, so it
    // centers on the content like everything else in the sheet.
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
      // Beside the iPhone Duo's side column, centered on the content.
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

/// The shared sheet and dialog layout: a title (with a close button in
/// dialogs), then scrolling content.
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

  /// A row pinned under the scrolling content (the sheet's actions), so
  /// they stay in reach on short windows. Its background is the sheet's;
  /// on bottom sheets it takes the bottom inset. Ignored with [expand].
  final Widget? footer;

  /// For sheets with their own pages (a nested navigator): no title row
  /// and no scroll view here; [child] fills the sheet (a bottom sheet up to
  /// its full height, a dialog up to 760 tall, a side sheet) and lays out
  /// its own header, scrolling and bottom inset (`MediaQuery.paddingOf`).
  /// [title] still names the route for screen readers.
  final bool expand;
  final Widget child;
  final bool dialog;

  /// Draws the bottom sheet's drag handle inside the side insets (the
  /// route's own handle centers on the whole window).
  final bool dragHandle;

  /// Whether the surface runs to the screen's bottom edge (bottom and side
  /// sheets). Its background then continues under the navigation bar and
  /// the content takes the inset as end padding inside the scroll view.
  /// Defaults to `!dialog`.
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
                // Dialogs end above the screen's edge: no bottom inset.
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
    // The sheet is what's under the navigation bar now.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: HudaSystemUi.over(top: surface, bottom: surface),
      child: frame,
    );
  }
}
