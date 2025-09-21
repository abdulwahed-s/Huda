import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/checklist/checklist_error_view.dart';
import 'package:huda/presentation/widgets/checklist/checklist_view.dart';
import 'package:huda/presentation/widgets/checklist/delete_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/checklist/checklist_app_bar.dart';
import 'package:huda/presentation/widgets/checklist/checklist_header.dart';
import '../../cubit/checklist/checklist_cubit.dart';
import '../../data/models/checklist_item.dart';
import '../../core/theme/theme_extension.dart';
import '../widgets/checklist/add_custom_item_dialog.dart';
import '../widgets/checklist/celebration_overlay.dart';

class IslamicChecklistScreen extends StatefulWidget {
  const IslamicChecklistScreen({super.key});

  @override
  State<IslamicChecklistScreen> createState() => _IslamicChecklistScreenState();
}

class _IslamicChecklistScreenState extends State<IslamicChecklistScreen> {
  late PageController _pageController;
  late ChecklistCubit _checklistCubit;
  Locale? _currentLocale;

  bool _showCelebration = false;
  bool _isFirePulsing = false;
  double _lastProgress = 0.0;
  DateTime? _lastTrackedDate;

  @override
  void initState() {
    super.initState();
    _checklistCubit = ChecklistCubit();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    final isFirstTime = _currentLocale == null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_currentLocale != currentLocale) {
        _currentLocale = currentLocale;
        try {
          await _checklistCubit
              .updateLocalizedTitles(AppLocalizations.of(context)!);
          if (isFirstTime && _checklistCubit.state is ChecklistInitial) {
            _checklistCubit.loadChecklist();
          }
        } catch (_) {
          if (isFirstTime && _checklistCubit.state is ChecklistInitial) {
            _checklistCubit.loadChecklist();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _checklistCubit.close();
    super.dispose();
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  void _showAddCustomItemDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddCustomItemDialog(),
    );
    if (result != null) {
      await _checklistCubit.addCustomItem(
        title: result['title'],
        type: result['type'],
        frequency: result['frequency'],
      );
    }
  }

  void _showDeleteConfirmation(ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        item: item,
        onConfirm: () => _checklistCubit.removeCustomItem(item.id),
      ),
    );
  }

  Widget _buildHeader(ChecklistLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = state.dailyChecklist.progressPercentage;
    final isToday = _isToday(state.currentDate);

    if (_lastTrackedDate == null ||
        !_isSameDay(_lastTrackedDate!, state.currentDate)) {
      _lastProgress = 0.0;
      _lastTrackedDate = state.currentDate;
    }

    if (progress >= 1.0 && progress > _lastProgress && isToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showCelebration = true;
          _isFirePulsing = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isFirePulsing = false);
        });
      });
    }
    _lastProgress = progress;

    return ChecklistHeader(
      currentDate: state.currentDate,
      onPreviousPressed: () {
        _checklistCubit.navigateToPreviousDay();
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      onNextPressed: () {
        _checklistCubit.navigateToNextDay();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      progress: progress,
      completedCount: state.dailyChecklist.completedCount,
      totalItems: state.dailyChecklist.items.length,
      streakCount: state.streakCount,
      isPulsing: _isFirePulsing,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;

    return BlocProvider.value(
      value: _checklistCubit,
      child: Scaffold(
        backgroundColor:
            isDark ? colors.darkCardBackground : colors.primaryExtraLight,
        body: Stack(
          children: [
            Column(
              children: [
                ChecklistAppBar(
                  onTodayPressed: () {
                    _checklistCubit.navigateToToday();
                    _pageController.animateToPage(1000,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                  isDark: isDark,
                ),
                Expanded(
                  child: BlocBuilder<ChecklistCubit, ChecklistState>(
                    builder: (context, state) {
                      if (state is ChecklistLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is ChecklistError) {
                        return ChecklistErrorView(
                          message: state.message,
                          onRetry: _checklistCubit.loadChecklist,
                        );
                      }
                      if (state is ChecklistLoaded) {
                        return Column(
                          children: [
                            _buildHeader(state),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (index) {
                                  final today = DateTime.now();
                                  final targetDate =
                                      today.add(Duration(days: index - 1000));
                                  _checklistCubit.navigateToDate(targetDate);
                                },
                                itemBuilder: (_, __) {
                                  return AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: ChecklistView(
                                      state: state,
                                      isToday: _isToday(state.currentDate),
                                      onToggle: (id, value) => _checklistCubit
                                          .toggleItemCompletion(id, value),
                                      onDelete: _showDeleteConfirmation,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return Center(
                          child:
                              Text(AppLocalizations.of(context)!.unknownState));
                    },
                  ),
                ),
              ],
            ),
            BlocBuilder<ChecklistCubit, ChecklistState>(
              builder: (context, state) {
                return CelebrationOverlay(
                  isVisible: _showCelebration,
                  streakCount: state is ChecklistLoaded ? state.streakCount : 0,
                  onComplete: () => setState(() => _showCelebration = false),
                );
              },
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<ChecklistCubit, ChecklistState>(
          builder: (context, state) {
            final isToday =
                state is ChecklistLoaded && _isToday(state.currentDate);
            final colors = context.appColors;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isToday
                  ? FloatingActionButton.extended(
                      key: const ValueKey('add_button'),
                      onPressed: _showAddCustomItemDialog,
                      backgroundColor: colors.accent,
                      foregroundColor: isDark ? colors.darkText : Colors.white,
                      elevation: 8,
                      icon: Icon(Icons.add, size: 20.sp),
                      label: Text(
                        AppLocalizations.of(context)!.addTask,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          color: isDark ? colors.darkText : Colors.white,
                          fontFamily: "Amiri",
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
