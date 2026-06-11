import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/audiobook_download/audiobook_download_cubit.dart';
import 'package:huda/data/models/audio_detail_model.dart';
import 'package:huda/l10n/app_localizations.dart';




class AudioDetailDownloadButton extends StatefulWidget {
  final int audioId;
  final AudioDetailModel? detail;
  final String language;
  final bool isDark;

  const AudioDetailDownloadButton({
    super.key,
    required this.audioId,
    required this.detail,
    required this.language,
    required this.isDark,
  });

  @override
  State<AudioDetailDownloadButton> createState() =>
      _AudioDetailDownloadButtonState();
}

class _AudioDetailDownloadButtonState extends State<AudioDetailDownloadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiobookDownloadCubit, AudiobookDownloadState>(
      builder: (context, state) {
        final downloaded = state.isDownloaded;
        final downloading = state.isDownloading;

        return ScaleTransition(
          scale: _scaleCtrl,
          child: GestureDetector(
            onTapDown: (_) => _scaleCtrl.reverse(),
            onTapUp: (_) {
              _scaleCtrl.forward();
              if (downloading) {
                context.read<AudiobookDownloadCubit>().cancel(widget.audioId);
              } else if (downloaded) {
                _showDeleteDialog(context);
              } else if (widget.detail != null) {
                context
                    .read<AudiobookDownloadCubit>()
                    .download(widget.detail!, widget.language);
              }
            },
            onTapCancel: () => _scaleCtrl.forward(),
            child: _buildButtonContent(context, state, downloaded, downloading),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(BuildContext context, AudiobookDownloadState state,
      bool downloaded, bool downloading) {
    final borderColor = downloaded
        ? Colors.green
        : downloading
            ? context.primaryColor
            : context.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52.w,
      height: 52.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: downloaded
            ? Colors.green.withValues(alpha: 0.12)
            : context.primaryColor.withValues(alpha: 0.1),
        border:
            Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (downloading)
            SizedBox(
              width: 26.w,
              height: 26.w,
              child: CircularProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                strokeWidth: 2.5,
                backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(context.primaryColor),
              ),
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: downloading
                ? Icon(Icons.close_rounded,
                    key: const ValueKey('cancel'),
                    size: 14.sp,
                    color: context.primaryColor)
                : Icon(
                    downloaded
                        ? Icons.download_done_rounded
                        : Icons.download_rounded,
                    key: ValueKey(downloaded),
                    color: downloaded ? Colors.green : context.primaryColor,
                    size: 22.sp,
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final isDark = widget.isDark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppLocalizations.of(context)!.delete,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 16.sp,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirmation,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: context.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AudiobookDownloadCubit>().delete(widget.audioId);
            },
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
