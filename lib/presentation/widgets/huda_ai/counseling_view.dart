import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_skeleton.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_empty_state.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_response_card.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_action_button.dart';

class CounselingView extends StatefulWidget {
  final bool isDark;
  final AppLocalizations appLocalizations;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool isGeneratingImage;

  const CounselingView({
    super.key,
    required this.isDark,
    required this.appLocalizations,
    required this.onCopy,
    required this.onShare,
    required this.isGeneratingImage,
  });

  @override
  State<CounselingView> createState() => _CounselingViewState();
}

class _CounselingViewState extends State<CounselingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.isLoading && state.counselingResponse == null) {
          return CounselingSkeleton(isDark: widget.isDark);
        }

        if (state.counselingResponse == null) {
          return CounselingEmptyState(isDark: widget.isDark);
        }

        // Trigger animation when response is available
        _animationController.forward(from: 0);

        final response = state.counselingResponse!;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CounselingResponseCard(
                index: 0,
                title: widget.appLocalizations.guidance,
                content: response.counselingText,
                icon: Icons.light_mode,
                gradientColors: const [Color(0xFF00897B), Color(0xFF00BFA5)],
                isDark: widget.isDark,
              ),
              const SizedBox(height: 20),
              CounselingResponseCard(
                index: 1,
                title: widget.appLocalizations.quranicWisdom,
                content: response.ayah,
                subContent: response.ayahTranslation.isNotEmpty
                    ? '"${response.ayahTranslation}"'
                    : null,
                footer: response.ayahReference,
                icon: Icons.menu_book,
                gradientColors: const [Color(0xFF3949AB), Color(0xFF5E35B1)],
                isDark: widget.isDark,
              ),
              const SizedBox(height: 20),
              CounselingResponseCard(
                index: 2,
                title: widget.appLocalizations.duaa,
                content: response.duaa,
                subContent: response.duaaTranslation.isNotEmpty
                    ? '"${response.duaaTranslation}"'
                    : null,
                icon: Icons.favorite,
                gradientColors: const [Color(0xFFC2185B), Color(0xFFD81B60)],
                isDark: widget.isDark,
              ),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          CounselingActionButton(
            icon: Icons.copy_outlined,
            onPressed: widget.onCopy,
          ),
          SizedBox(width: 8.w),
          CounselingActionButton(
            icon: widget.isGeneratingImage
                ? Icons.hourglass_empty
                : Icons.share_outlined,
            onPressed: widget.isGeneratingImage ? null : widget.onShare,
          ),
        ],
      ),
    );
  }
}
