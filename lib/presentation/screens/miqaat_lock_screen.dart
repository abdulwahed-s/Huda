import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_state.dart';

import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/miqaat_lock/app_selection_dialog.dart';
import 'package:huda/presentation/widgets/miqaat_lock/permission_setup_widget.dart';
import 'package:huda/presentation/widgets/miqaat_lock/time_slot_picker.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_master_toggle.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_apps_section.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_time_slots_section.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_duration_section.dart';
import 'package:huda/presentation/widgets/miqaat_lock/miqaat_lock_error_state.dart';
import 'package:huda/presentation/widgets/miqaat_lock/animated_section.dart';
import 'package:huda/presentation/widgets/miqaat_lock/duration_picker_sheet.dart';
import 'package:huda/presentation/widgets/miqaat_lock/custom_duration_picker_content.dart';

class MiqaatLockScreen extends StatefulWidget {
  const MiqaatLockScreen({super.key});

  @override
  State<MiqaatLockScreen> createState() => _MiqaatLockScreenState();
}

class _MiqaatLockScreenState extends State<MiqaatLockScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _iosAppsRefreshKey = 0;
  late AnimationController _animController;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<MiqaatLockCubit>().loadSettings();
    context.read<MiqaatLockCubit>().refreshPermissions();

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
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MiqaatLockCubit>().refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final primary = context.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.miqaatLock,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : primary,
        foregroundColor: isDark ? theme.iconTheme.color : Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<MiqaatLockCubit, MiqaatLockState>(
        builder: (context, state) {
          if (state is MiqaatLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MiqaatLockError) {
            return MiqaatLockErrorState(
              message: state.message,
              onRetry: () => context.read<MiqaatLockCubit>().loadSettings(),
            );
          }

          if (state is! MiqaatLockLoaded) {
            return const SizedBox.shrink();
          }

          final needsPermissions = Platform.isAndroid
              ? !state.permissions.isAndroidReady
              : Platform.isIOS
                  ? !state.permissions.isIOSReady
                  : false;

          return ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
            children: [
              if (needsPermissions) ...[
                PermissionSetupWidget(
                  permissions: state.permissions,
                  onRefresh: () =>
                      context.read<MiqaatLockCubit>().refreshPermissions(),
                ),
                SizedBox(height: 16.h),
              ],
              AnimatedSection(
                animation: _sectionAnimations[0],
                child: MasterToggleSection(
                  isEnabled: state.settings.isEnabled,
                  isLocked: needsPermissions,
                  onToggle: (v) =>
                      context.read<MiqaatLockCubit>().toggleEnabled(v),
                ),
              ),
              SizedBox(height: 16.h),
              AnimatedSection(
                animation: _sectionAnimations[1],
                child: LockedAppsSection(
                  lockedApps: state.settings.lockedApps,
                  onAddAppsTap: () => _showAppSelectionDialog(context, state),
                  onRemoveApp: (packageId) => context
                      .read<MiqaatLockCubit>()
                      .removeLockedApp(packageId),
                  iosAppsRefreshKey: _iosAppsRefreshKey,
                ),
              ),
              SizedBox(height: 16.h),
              AnimatedSection(
                animation: _sectionAnimations[2],
                child: TimeSlotsSection(
                  timeSlots: state.settings.timeSlots,
                  onAddTimeSlot: () => _showTimeSlotPicker(context),
                  onRemoveTimeSlot: (id) =>
                      context.read<MiqaatLockCubit>().removeTimeSlot(id),
                ),
              ),
              SizedBox(height: 16.h),
              AnimatedSection(
                animation: _sectionAnimations[3],
                child: SessionDurationSection(
                  goalDurationMinutes: state.settings.goalDurationMinutes,
                  onEditTap: () => _showDurationPicker(
                      context, state.settings.goalDurationMinutes),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          );
        },
      ),
    );
  }

  void _showAppSelectionDialog(BuildContext context, MiqaatLockLoaded state) {
    final cubit = context.read<MiqaatLockCubit>();
    if (state.installedApps.isEmpty) {
      cubit.loadInstalledApps();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AppSelectionDialog(
          selectedApps:
              state.settings.lockedApps.map((a) => a.packageId).toList(),
        ),
      ),
    ).then((_) {
      if (Platform.isIOS && mounted) {
        setState(() => _iosAppsRefreshKey++);
      }
    });
  }

  void _showTimeSlotPicker(BuildContext context) {
    final cubit = context.read<MiqaatLockCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: const TimeSlotPickerDialog(),
      ),
    );
  }

  void _showDurationPicker(BuildContext blocContext, int currentDuration) {
    final cubit = blocContext.read<MiqaatLockCubit>();

    showModalBottomSheet(
      context: blocContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (dialogContext) => DurationPickerSheet(
        currentDuration: currentDuration,
        onDurationSelected: (duration) {
          cubit.setGoalDuration(duration);
          Navigator.pop(dialogContext);
        },
        onCustomDurationTap: () {
          Navigator.pop(dialogContext);
          _showCustomDurationPicker(blocContext, currentDuration);
        },
      ),
    );
  }



  void _showCustomDurationPicker(
      BuildContext blocContext, int currentDuration) {
    final cubit = blocContext.read<MiqaatLockCubit>();
    int selectedDuration = currentDuration;
    final theme = Theme.of(blocContext);

    showDialog(
      context: blocContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color:
                theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: StatefulBuilder(
              builder: (innerContext, setState) {
                return CustomDurationPickerContent(
                  selectedDuration: selectedDuration,
                  onChanged: (value) => setState(() => selectedDuration = value),
                  onCancel: () => Navigator.pop(dialogContext),
                  onConfirm: () {
                    cubit.setGoalDuration(selectedDuration);
                    Navigator.pop(dialogContext);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
