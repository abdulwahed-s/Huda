import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_app_bar.dart';
import 'package:huda/presentation/widgets/huda_ai/clipboard_snackbar.dart';
import 'package:huda/presentation/widgets/huda_ai/loading_indicator.dart';
import 'package:huda/presentation/widgets/huda_ai/message_input.dart';
import 'package:huda/cubit/chat/chat_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/presentation/widgets/huda_ai/message_list.dart';
import 'package:huda/presentation/widgets/huda_ai/mode_switcher.dart';
import 'package:huda/presentation/widgets/huda_ai/share_image_overlay.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_view.dart';
import 'package:huda/presentation/widgets/huda_ai/counseling_share_overlay.dart';
import 'package:huda/data/models/counseling_response_model.dart';
import 'package:huda/presentation/widgets/huda_ai/chat_history_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGeneratingImage = false;
  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatCubit>().onScreenOpened();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shareAsImage(
    BuildContext context,
    String messageText,
    AppLocalizations appLocalizations,
  ) async {
    setState(() => _isGeneratingImage = true);
    await ShareImageOverlay.shareAsImage(
      context: context,
      messageText: messageText,
      appLocalizations: appLocalizations,
      onError: (e) {
        if (mounted) {
          setState(() => _isGeneratingImage = false);
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() => _isGeneratingImage = false);
        }
      },
    );
  }

  void _copyToClipboard(
    BuildContext context,
    String text,
    AppLocalizations appLocalizations,
  ) {
    ClipboardSnackbar.showCopySnackbar(context, text, appLocalizations);
  }

  void _copyCounselingToClipboard(
    BuildContext context,
    CounselingResponse response,
    AppLocalizations appLocalizations,
  ) {
    final String formattedText =
        '''
━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Guidance
━━━━━━━━━━━━━━━━━━━━━━━━━━
${response.counselingText}

━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Quranic Wisdom
━━━━━━━━━━━━━━━━━━━━━━━━━━
${response.ayah}
${response.ayahTranslation.isNotEmpty ? '\n"${response.ayahTranslation}"' : ''}
${response.ayahReference.isNotEmpty ? '\n— ${response.ayahReference}' : ''}

━━━━━━━━━━━━━━━━━━━━━━━━━━
◆ Duaa
━━━━━━━━━━━━━━━━━━━━━━━━━━
${response.duaa}
${response.duaaTranslation.isNotEmpty ? '\n"${response.duaaTranslation}"' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
    ClipboardSnackbar.showCopySnackbar(
      context,
      formattedText,
      appLocalizations,
    );
  }

  Future<void> _shareCounselingAsImage(
    BuildContext context,
    CounselingResponse response,
    AppLocalizations appLocalizations,
  ) async {
    setState(() => _isGeneratingImage = true);
    await CounselingShareOverlay.shareAsImage(
      context: context,
      response: response,
      appLocalizations: appLocalizations,
      onError: (e) {
        if (mounted) {
          setState(() => _isGeneratingImage = false);
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() => _isGeneratingImage = false);
        }
      },
    );
  }

  void _startNewChat() {
    FocusScope.of(context).unfocus();
    _controller.clear();
    context.read<ChatCubit>().startNewSession();
  }

  void _prepareForConversationChange() {
    FocusScope.of(context).unfocus();
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLanguageCode = context
        .read<LocalizationCubit>()
        .state
        .locale
        .languageCode;
    final isRTL = currentLanguageCode == 'ar' || currentLanguageCode == 'ur';
    final appLocalizations = AppLocalizations.of(context)!;

    return MultiBlocListener(
      listeners: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              previous.isHydrating && !current.isHydrating,
          listener: (context, state) =>
              context.read<ChatCubit>().onScreenOpened(),
        ),
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (previous, current) =>
              !previous.storageWarning && current.storageWarning,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(appLocalizations.aiStorageWarning),
                action: SnackBarAction(
                  label: appLocalizations.close,
                  onPressed: context.read<ChatCubit>().dismissStorageWarning,
                ),
              ),
            );
          },
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark
            ? context.darkGradientStart
            : context.lightSurface,
        drawerScrimColor: Colors.black.withValues(alpha: 0.38),
        endDrawer: ChatHistoryDrawer(
          onNewChat: _startNewChat,
          onSessionSelected: _prepareForConversationChange,
        ),
        appBar: ChatAppBar(
          isDark: isDark,
          appLocalizations: appLocalizations,
          onHistory: () {
            FocusScope.of(context).unfocus();
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onNewChat: _startNewChat,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  return ModeSwitcher(
                    isCounselingMode: state.isCounselingMode,
                    isDark: isDark,
                    onModeChanged: () {
                      context.read<ChatCubit>().toggleMode();
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  if (state.isHydrating) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.isCounselingMode) {
                    return CounselingView(
                      isDark: isDark,
                      appLocalizations: appLocalizations,
                      onCopy: () {
                        if (state.counselingResponse != null) {
                          _copyCounselingToClipboard(
                            context,
                            state.counselingResponse!,
                            appLocalizations,
                          );
                        }
                      },
                      onShare: () {
                        if (state.counselingResponse != null) {
                          _shareCounselingAsImage(
                            context,
                            state.counselingResponse!,
                            appLocalizations,
                          );
                        }
                      },
                      isGeneratingImage: _isGeneratingImage,
                    );
                  }
                  return MessageList(
                    scrollController: _scrollController,
                    textEditingController: _controller,
                    messageKeys: _messageKeys,
                    isDark: isDark,
                    isRTL: isRTL,
                    appLocalizations: appLocalizations,
                    onCopy: (text) =>
                        _copyToClipboard(context, text, appLocalizations),
                    onShare: (text) =>
                        _shareAsImage(context, text, appLocalizations),
                    isGeneratingImage: _isGeneratingImage,
                  );
                },
              ),
            ),
            BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return LoadingIndicator(
                    isDark: isDark,
                    appLocalizations: appLocalizations,
                  );
                }
                if (state.hasActiveRequest) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: context.primaryColor.withValues(alpha: 0.08),
                    child: Text(
                      appLocalizations.aiBusyOtherConversation,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.primaryColor),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            MessageInput(controller: _controller, isDark: isDark),
          ],
        ),
      ),
    );
  }
}
