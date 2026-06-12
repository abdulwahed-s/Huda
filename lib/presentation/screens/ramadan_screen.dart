import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/ramadan/ramadan_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/ramadan/ramadan_header_widget.dart';
import 'package:huda/presentation/widgets/ramadan/prayer_time_cards_widget.dart';
import 'package:huda/presentation/widgets/ramadan/fasting_progress_widget.dart';
import 'package:huda/presentation/widgets/ramadan/qadhaa_tracker_widget.dart';
import 'package:huda/presentation/widgets/ramadan/ramadan_loading_widget.dart';

class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    context.read<RamadanCubit>().loadRamadanData();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _sectionAnimations = List.generate(4, (i) {
      final start = i * 0.15;
      final end = start + 0.5;
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _sectionAnimations[index],
      builder: (context, _) {
        final value = _sectionAnimations[index].value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? context.primaryLightColor : context.primaryColor;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : primary,
        foregroundColor: isDark ? theme.iconTheme.color : Colors.white,
        title: Text(
          AppLocalizations.of(context)!.ramadan,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<RamadanCubit, RamadanState>(
        builder: (context, state) {
          if (state is RamadanLoading) {
            return RamadanLoadingWidget(isDark: isDark);
          }
          if (state is RamadanError) {
            return _buildErrorState(state, isDark, primary);
          }
          if (state is RamadanLoaded) {
            return _buildLoadedContent(state, isDark, primary, theme);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(RamadanError state, bool isDark, Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 40.sp, color: primary.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 20.h),
            Text(
              state.message,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
                fontSize: 14.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => context.read<RamadanCubit>().loadRamadanData(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(
      RamadanLoaded state, bool isDark, Color primary, ThemeData theme) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16.w,
        8.h,
        16.w,
        32.h + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _buildAnimatedSection(
          index: 0,
          child: RamadanHeaderWidget(
            isRamadan: state.isRamadan,
            currentDay: state.currentDay,
            daysUntilRamadan: state.daysUntilRamadan,
            isDark: isDark,
          ),
        ),
        SizedBox(height: 16.h),
        _buildAnimatedSection(
          index: 1,
          child: PrayerTimeCardsWidget(
            fajrTime: state.fajrTime,
            maghribTime: state.maghribTime,
            isDark: isDark,
          ),
        ),
        SizedBox(height: 16.h),
        _buildAnimatedSection(
          index: 2,
          child: FastingProgressWidget(
            fajrTime: state.fajrTime,
            maghribTime: state.maghribTime,
            isDark: isDark,
          ),
        ),
        SizedBox(height: 16.h),
        _buildAnimatedSection(
          index: 3,
          child: QadhaaTrackerWidget(
            ramadanDays: state.ramadanDays,
            fastedCount: state.fastedCount,
            missedCount: state.missedCount,
            currentDay: state.currentDay,
            isRamadan: state.isRamadan,
            isDark: isDark,
            onSetStatus: (dayNumber, status) {
              context.read<RamadanCubit>().setDayStatus(dayNumber, status);
            },
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
