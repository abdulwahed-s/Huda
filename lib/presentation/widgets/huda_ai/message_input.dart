import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/l10n/app_localizations.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const MessageInput({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? context.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? context.darkGradientStart
                        : context.lightSurface,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 120.h, // limit height before scrolling
                    ),
                    child: Scrollbar(
                      thickness: 0,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? context.darkText : context.lightText,
                          fontFamily: 'Amiri',
                        ),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.typeMessageHint,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline,
                            color: context.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  )),
            ),
            SizedBox(width: 12.w),
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: state.isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [
                    context.primaryColor,
                    context.primaryColor.withValues(alpha: 0.8)
                  ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: context.primaryColor.withValues(alpha: 0.3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24.r),
            onTap: state.isLoading
                ? null
                : () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      context.read<ChatCubit>().sendMessage(text);
                      controller.clear();
                    }
                  },
            child: Container(
              width: 40.h,
              height: 40.h,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
