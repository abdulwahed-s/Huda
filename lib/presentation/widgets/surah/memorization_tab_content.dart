import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/memorization/memorization_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';

class MemorizationTabContent extends StatelessWidget {
  final bool isDark;
  final Color accent;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const MemorizationTabContent({
    super.key,
    required this.isDark,
    required this.accent,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<MemorizationCubit, MemorizationState>(
      builder: (context, state) {
        final isMemorizationMode =
            state is MemorizationModeUpdated && state.isMemorizationMode;
        final isListening =
            state is MemorizationModeUpdated && state.isListening;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l.memorizationMode,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _BetaBadge(isDark: isDark, label: l.beta),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                l.memorizationDescription,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12.h),
              _SpeechDisclaimer(
                isDark: isDark,
                message: l.speechRecognitionDisclaimer,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: !isMemorizationMode
                    ? _MemorizationActionButton(
                        icon: Icons.play_arrow_rounded,
                        label: l.startMemorization,
                        backgroundColor: accent.withValues(alpha: 0.8),
                        onPressed: onStart,
                      )
                    : _MemorizationActionButton(
                        icon: Icons.stop_rounded,
                        label: l.stopMemorization,
                        backgroundColor: Colors.red,
                        onPressed: onStop,
                      ),
              ),
              if (isMemorizationMode) ...[
                SizedBox(height: 20.h),
                _MicrophoneStatusCard(
                  isDark: isDark,
                  isListening: isListening,
                  idleLabel: l.microphoneIdle,
                  listeningLabel: l.listening,
                  reciteHint: l.reciteToReveal,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BetaBadge extends StatelessWidget {
  final bool isDark;
  final String label;

  const _BetaBadge({required this.isDark, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }
}

class _SpeechDisclaimer extends StatelessWidget {
  final bool isDark;
  final String message;

  const _SpeechDisclaimer({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16.sp, color: Colors.blue),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color:
                    isDark ? Colors.blue.shade200 : Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemorizationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _MemorizationActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20.sp, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

class _MicrophoneStatusCard extends StatelessWidget {
  final bool isDark;
  final bool isListening;
  final String idleLabel;
  final String listeningLabel;
  final String reciteHint;

  const _MicrophoneStatusCard({
    required this.isDark,
    required this.isListening,
    required this.idleLabel,
    required this.listeningLabel,
    required this.reciteHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isListening
            ? Colors.red.withValues(alpha: 0.1)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isListening
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          if (isListening)
            AvatarGlow(
              glowColor: Colors.red,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              child: Icon(
                Icons.mic,
                color: Colors.red,
                size: 24.sp,
              ),
            )
          else
            Icon(
              Icons.mic_none,
              color: isDark ? Colors.white54 : Colors.black45,
              size: 24.sp,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isListening ? listeningLabel : idleLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isListening
                        ? Colors.red
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
                if (isListening)
                  Text(
                    reciteHint,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isListening
                          ? Colors.red.withValues(alpha: 0.8)
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
