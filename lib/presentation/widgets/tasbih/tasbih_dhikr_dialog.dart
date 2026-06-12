import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/tasbih/tasbih_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/tasbih/tasbih_dhikr_item.dart';

void showTasbihDhikrDialog(BuildContext context) {
  final cubit = context.read<TasbihCubit>();
  showDialog(
    context: context,
    builder: (_) => TasbihDhikrDialog(cubit: cubit),
  );
}

class TasbihDhikrDialog extends StatefulWidget {
  final TasbihCubit cubit;

  const TasbihDhikrDialog({super.key, required this.cubit});

  @override
  State<TasbihDhikrDialog> createState() => _TasbihDhikrDialogState();
}

class _TasbihDhikrDialogState extends State<TasbihDhikrDialog> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.cubit.addNote(text);
    _controller.clear();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<TasbihCubit, TasbihState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final notes = state is TasbihLoaded ? state.notes : <TasbihNote>[];
        final primaryColor = context.primaryColor;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogHeader(
                  noteCount: notes.length,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onClose: () => Navigator.of(context).pop(),
                ),
                if (notes.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.36,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: notes.length,
                      itemBuilder: (_, index) => TasbihDhikrItem(
                        text: notes[index].text,
                        count: notes[index].count,
                        index: index,
                        primaryColor: primaryColor,
                        onDelete: () => widget.cubit.removeNote(index),
                        isDark: isDark,
                      ),
                    ),
                  ),
                ] else ...[
                  _EmptyDhikrState(isDark: isDark),
                ],
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                _InputRow(
                  controller: _controller,
                  focusNode: _focusNode,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onSubmit: _submit,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      minimumSize: Size(double.infinity, 44.h),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.save,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class _DialogHeader extends StatelessWidget {
  final int noteCount;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.noteCount,
    required this.primaryColor,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.format_list_bulleted_rounded,
              size: 20.sp,
              color: primaryColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.addDhikr,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (noteCount > 0)
                  Text(
                    '$noteCount ${AppLocalizations.of(context)!.dhikr}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 20.sp,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(4.w),
              minimumSize: Size(32.w, 32.h),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDhikrState extends StatelessWidget {
  final bool isDark;

  const _EmptyDhikrState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 36.sp,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.noDhikrYet,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onSubmit;

  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.primaryColor,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterDhikrHint,
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 11.h,
                ),
                isDense: true,
              ),
              style: TextStyle(fontSize: 15.sp),
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          SizedBox(width: 10.w),
          _AddButton(onPressed: onSubmit, primaryColor: primaryColor),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;

  const _AddButton({required this.onPressed, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: SizedBox(
          width: 44.w,
          height: 44.w,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 22.sp),
        ),
      ),
    );
  }
}
