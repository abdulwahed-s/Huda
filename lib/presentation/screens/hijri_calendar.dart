import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/hijri_calendar/hijri_calendar_cubit.dart';
import 'package:huda/data/models/hijri_event.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_grid_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/calendar_header_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/custom_app_bar.dart';
import 'package:huda/presentation/widgets/hijri_calendar/delete_confirmation_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/event_dialog.dart';
import 'package:huda/presentation/widgets/hijri_calendar/events_section_widget.dart';
import 'package:huda/presentation/widgets/hijri_calendar/selected_date_info_widget.dart';
import 'package:huda/l10n/app_localizations.dart';

class HijriCalendarScreenNew extends StatefulWidget {
  const HijriCalendarScreenNew({super.key});

  @override
  State<HijriCalendarScreenNew> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreenNew>
    with TickerProviderStateMixin {
  HijriCalendar? _selectedHijri;
  late DateTime _focusedGregorian;
  late HijriCalendar _focusedHijri;
  late AnimationController _headerAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _focusedGregorian = DateTime.now();
    _selectedHijri = HijriCalendar.fromDate(_focusedGregorian);
    _focusedHijri = HijriCalendar.fromDate(_focusedGregorian);

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
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _goToPreviousHijriMonth() {
    setState(() {
      if (_focusedHijri.hMonth == 1) {
        _focusedHijri.hMonth = 12;
        _focusedHijri.hYear -= 1;
      } else {
        _focusedHijri.hMonth -= 1;
      }
      _focusedGregorian = _focusedGregorian.subtract(const Duration(days: 29));
    });
  }

  void _goToNextHijriMonth() {
    setState(() {
      if (_focusedHijri.hMonth == 12) {
        _focusedHijri.hMonth = 1;
        _focusedHijri.hYear += 1;
      } else {
        _focusedHijri.hMonth += 1;
      }
      _focusedGregorian = _focusedGregorian.add(const Duration(days: 29));
    });
  }

  DateTime _getGregorianDateFromHijri(HijriCalendar hijriDate) {
    try {
      final today = DateTime.now();
      final todayHijri = HijriCalendar.fromDate(today);
      final yearDiff = (hijriDate.hYear - todayHijri.hYear) * 354;
      final monthDiff = (hijriDate.hMonth - todayHijri.hMonth) * 29;
      final dayDiff = hijriDate.hDay - todayHijri.hDay;
      final totalDayDiff = yearDiff + monthDiff + dayDiff;
      return today.add(Duration(days: totalDayDiff));
    } catch (e) {
      debugPrint('Date conversion error: $e');
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 690));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => HijriCalendarCubit(),
      child: Builder(
        builder: (parentContext) => Scaffold(
          backgroundColor:
              isDark ? context.darkGradientStart : context.lightSurface,
          appBar: CustomAppBar(
            isDark: isDark,
            onTodayPressed: () {
              setState(() {
                _focusedGregorian = DateTime.now();
                _selectedHijri = HijriCalendar.fromDate(_focusedGregorian);
                _focusedHijri = HijriCalendar.fromDate(_focusedGregorian);
              });
            },
          ),
          body: BlocBuilder<HijriCalendarCubit, HijriCalendarState>(
            builder: (context, state) {
              final events = _selectedHijri != null
                  ? state.events[_selectedHijri.toString()] ?? []
                  : [];

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
                    state: state,
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
                  EventsSectionWidget(
                    events: events.cast<HijriEvent>(),
                    parentContext: parentContext,
                    isDark: isDark,
                    onEditEvent: (event) => _showEditEventDialog(
                        parentContext, _focusedGregorian, event),
                    onDeleteEvent: (event) =>
                        _showDeleteConfirmation(parentContext, event),
                    context: context,
                  ),
                ],
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
                      fontFamily: "Amiri",
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
