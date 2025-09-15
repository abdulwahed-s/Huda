import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/data/models/chat_message_model.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final bool isRTL;
  final AppLocalizations appLocalizations;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool isGeneratingImage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    required this.isRTL,
    required this.appLocalizations,
    required this.onCopy,
    required this.onShare,
    required this.isGeneratingImage,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAIIcon(context),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser) _buildAITitle(context),
                _buildMessageContent(context, isUser),
                if (!isUser) ...[
                  SizedBox(height: 12.h),
                  _buildDisclaimer(context),
                  SizedBox(height: 8.h),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12.w),
            _buildUserIcon(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAIIcon(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      child: Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 20.sp,
      ),
    );
  }

  Widget _buildUserIcon(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      child: Icon(
        Icons.person,
        color: isDark ? Theme.of(context).primaryColor : Colors.white,
        size: 20.sp,
      ),
    );
  }

  Widget _buildAITitle(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        'Huda AI',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? context.darkText : context.lightText,
          fontSize: 16.sp,
          fontFamily: 'Amiri',
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isUser) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 0.8.sw,
      ),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).primaryColor
            : isDark
                ? const Color(0xFF1A1F2E)
                : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(isUser
              ? (isRTL ? 4.r : 20.r)
              : (isRTL ? 20.r : 4.r)),
          bottomRight: Radius.circular(isUser
              ? (isRTL ? 20.r : 4.r)
              : (isRTL ? 4.r : 20.r)),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: isUser
          ? Text(
              message.text,
              style: TextStyle(
                color:
                    isUser ? Colors.white : isDark ? Colors.white : Colors.black87,
                fontSize: 14.sp,
                height: 1.5,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.start,
            )
          : Markdown(
              data: message.text,
              selectable: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 14.sp,
                  height: 1.5,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(right: 40.w),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16.sp,
            color: Colors.orange[700],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              appLocalizations.aiGeneratedDisclaimer,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ActionButton(
          icon: Icons.copy_outlined,
          onPressed: onCopy,
        ),
        SizedBox(width: 8.w),
        ActionButton(
          icon: isGeneratingImage ? Icons.hourglass_empty : Icons.share_outlined,
          onPressed: isGeneratingImage ? null : onShare,
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              icon,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}