import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri_plus/hijri_plus.dart';
import 'package:huda/core/services/hijri_calendar_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_grid_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_header_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/custom_app_bar.dart';
import 'package:huda/presentation/widgets/hijri_calendar/delete_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/event_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/events_section_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/hijri_adjustment_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_calendar_event.dart';
import 'package:huda/presentation/widgets/hijri_calendar/islamic_events_section_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/selected_date_info_widget.dart';
import 'package:huda/l10n/app_localizations.dart';

class HijriCalendarScreenNew extends StatefulWidget {
  const HijriCalendarScreenNew({
    super.key,
    this.calendarService,
  });

  final HijriCalendarService? calendarService;

  @override
  State<HijriCalendarScreenNew> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreenNew>
    with TickerProviderStateMixin {
  HijriDate? _selectedHijri;
  late DateTime _focusedGregorian;
  late HijriDate _focusedHijri;
  late HijriCalendarService _calendarService;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _calendarService = widget.calendarService ?? getIt<HijriCalendarService>();
    _calendarService.addListener(_handleCalendarChanged);
    _focusedGregorian = DateTime.now();
    _selectedHijri = _calendarService.toHijri(_focusedGregorian);
    _focusedHijri = _selectedHijri!;

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _headerAnimationController.forward();
    _fabAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAdjustmentDialogIfNeeded();
    });
  }

  @override
  void dispose() {
    _calendarService.removeListener(_handleCalendarChanged);
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _goToPreviousHijriMonth() {
    setState(() {
      final previousYear = _focusedHijri.month == 1
          ? _focusedHijri.year - 1
          : _focusedHijri.year;
      final previousMonth =
          _focusedHijri.month == 1 ? 12 : _focusedHijri.month - 1;
      _focusedHijri = HijriDate(previousYear, previousMonth, 1);
    });
  }

  void _goToNextHijriMonth() {
    setState(() {
      final nextYear = _focusedHijri.month == 12
          ? _focusedHijri.year + 1
          : _focusedHijri.year;
      final nextMonth = _focusedHijri.month == 12 ? 1 : _focusedHijri.month + 1;
      _focusedHijri = HijriDate(nextYear, nextMonth, 1);
    });
  }

  DateTime _getGregorianDateFromHijri(HijriDate hijriDate) {
    try {
      return _calendarService.toGregorian(hijriDate);
    } catch (e) {
      debugPrint('Date conversion error: $e');
      return DateTime.now();
    }
  }

  void _handleCalendarChanged() {
    if (!mounted) return;
    setState(() {
      _selectedHijri = _calendarService.toHijri(_focusedGregorian);
      _focusedHijri = _selectedHijri!;
    });
  }

  Future<void> _showAdjustmentDialogIfNeeded() async {
    await _calendarService.initialize();
    if (!mounted) return;

    _handleCalendarChanged();
    if (_calendarService.hasAdjustmentChoice) return;
    await _showAdjustmentDialog(isRequired: true);
  }

  Future<void> _showAdjustmentDialog({required bool isRequired}) async {
    await _calendarService.initialize();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isRequired,
      builder: (_) => HijriAdjustmentDialog(
        initialChoice: _calendarService.adjustmentChoice,
        canDismiss: !isRequired,
        onSave: _calendarService.setAdjustmentChoice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return BlocProvider(
      create: (_) => HijriCalendarCubit(calendarService: _calendarService),
      child: Builder(
        builder: (parentContext) => Scaffold(
          backgroundColor:
              isDark ? context.darkGradientStart : context.lightSurface,
          appBar: CustomAppBar(
            isDark: isDark,
            isTablet: isTablet,
            onAdjustmentPressed: () => _showAdjustmentDialog(isRequired: false),
            onTodayPressed: () {
              setState(() {
                _focusedGregorian = DateTime.now();
                _selectedHijri = _calendarService.toHijri(_focusedGregorian);
                _focusedHijri = _selectedHijri!;
              });
            },
          ),
          body: BlocBuilder<HijriCalendarCubit, HijriCalendarState>(
            builder: (context, state) {
              final List<HijriEvent> userEvents = _selectedHijri != null
                  ? state.events[
                          HijriCalendarService.eventKey(_selectedHijri!)] ??
                      const <HijriEvent>[]
                  : const <HijriEvent>[];
              final islamicEvents = _selectedHijri == null
                  ? const <IslamicCalendarEvent>[]
                  : IslamicCalendarEvents.forDate(_selectedHijri!);
              final showUserEventsSection =
                  userEvents.isNotEmpty || islamicEvents.isEmpty;
              final calendarState = HijriCalendarState(
                events: IslamicCalendarEvents.withMarkers(
                  userEvents: state.events,
                  focusedMonth: _focusedHijri,
                  daysInFocusedMonth: _calendarService.daysInMonth(
                    _focusedHijri.year,
                    _focusedHijri.month,
                  ),
                ),
              );
              final userEventsSection = EventsSectionWidget(
                events: userEvents,
                parentContext: parentContext,
                isDark: isDark,
                onEditEvent: (event) => _showEditEventDialog(
                  parentContext,
                  _focusedGregorian,
                  event,
                ),
                onDeleteEvent: (event) =>
                    _showDeleteConfirmation(parentContext, event),
                context: context,
              );

              return OrientationBuilder(
                builder: (context, orientation) {
                  final isLandscape = orientation == Orientation.landscape;

                  if (isLandscape) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(bottom: 20.h),
                            child: Column(
                              children: [
                                CalendarHeaderWidget(
                                  animation: _headerAnimation,
                                  focusedHijri: _focusedHijri,
                                  onPreviousMonth: _goToPreviousHijriMonth,
                                  onNextMonth: _goToNextHijriMonth,
                                  isDark: isDark,
                                  context: context,
                                ),
                                CalendarGridWidget(
                                  focusedHijri: _focusedHijri,
                                  calendarService: _calendarService,
                                  state: calendarState,
                                  isDark: isDark,
                                  selectedHijri: _selectedHijri,
                                  onDateSelected: (hijriDate, gregorianDate) {
                                    setState(() {
                                      _selectedHijri = hijriDate;
                                      _focusedGregorian = gregorianDate;
                                    });
                                  },
                                  onAddEvent: (p0) =>
                                      _showAddEventDialog(parentContext),
                                  context: context,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_selectedHijri != null)
                                  SelectedDateInfoWidget(
                                    selectedHijri: _selectedHijri!,
                                    focusedGregorian: _focusedGregorian,
                                    isDark: isDark,
                                    context: context,
                                  ),
                                IslamicEventsSectionWidget(
                                  events: islamicEvents,
                                  isDark: isDark,
                                ),
                                Expanded(
                                  child: showUserEventsSection
                                      ? userEventsSection
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    children: [
                      CalendarHeaderWidget(
                        animation: _headerAnimation,
                        focusedHijri: _focusedHijri,
                        onPreviousMonth: _goToPreviousHijriMonth,
                        onNextMonth: _goToNextHijriMonth,
                        isDark: isDark,
                        context: context,
                      ),
                      CalendarGridWidget(
                        focusedHijri: _focusedHijri,
                        calendarService: _calendarService,
                        state: calendarState,
                        isDark: isDark,
                        selectedHijri: _selectedHijri,
                        onDateSelected: (hijriDate, gregorianDate) {
                          setState(() {
                            _selectedHijri = hijriDate;
                            _focusedGregorian = gregorianDate;
                          });
                        },
                        onAddEvent: (p0) => _showAddEventDialog(parentContext),
                        context: context,
                      ),
                      if (_selectedHijri != null)
                        SelectedDateInfoWidget(
                          selectedHijri: _selectedHijri!,
                          focusedGregorian: _focusedGregorian,
                          isDark: isDark,
                          context: context,
                        ),
                      IslamicEventsSectionWidget(
                        events: islamicEvents,
                        isDark: isDark,
                      ),
                      if (showUserEventsSection) userEventsSection,
                    ],
                  );
                },
              );
            },
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddEventDialog(parentContext),
                  backgroundColor: context.primaryColor,
                  elevation: 6,
                  icon: Icon(Icons.add, color: Colors.white, size: 20.w),
                  label: Text(
                    AppLocalizations.of(context)!.addEvent,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              );
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, HijriEvent event) {
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        event: event,
        onDelete: () {
          final selectedDate = _selectedHijri != null
              ? _getGregorianDateFromHijri(_selectedHijri!)
              : _focusedGregorian;
          context.read<HijriCalendarCubit>().removeEvent(selectedDate, event);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => EventDialog(
        isEditMode: false,
        onSave: (event) {
          final selectedDate = _selectedHijri != null
              ? _getGregorianDateFromHijri(_selectedHijri!)
              : _focusedGregorian;
          context.read<HijriCalendarCubit>().addEvent(selectedDate, event);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showEditEventDialog(
      BuildContext context, DateTime selectedGregorian, HijriEvent oldEvent) {
    showDialog(
      context: context,
      builder: (dialogContext) => EventDialog(
        isEditMode: true,
        oldEvent: oldEvent,
        onSave: (newEvent) {
          context
              .read<HijriCalendarCubit>()
              .editEvent(selectedGregorian, newEvent);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}
