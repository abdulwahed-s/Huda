import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:huda/core/theme/theme_extension.dart';
import 'package:huda/cubit/qiblah/qiblah_cubit.dart';
import 'package:huda/l10n/app_localizations.dart';
import 'package:huda/presentation/widgets/qiblah/error_state.dart';
import 'package:huda/presentation/widgets/qiblah/loading_state.dart';
import 'package:huda/presentation/widgets/qiblah/permission_denied_state.dart';
import 'package:huda/presentation/widgets/qiblah/qiblah_compass.dart';

class QiblahContent extends StatefulWidget {
  const QiblahContent({super.key});

  @override
  State<QiblahContent> createState() => QiblahContentState();
}

class QiblahContentState extends State<QiblahContent>
    with TickerProviderStateMixin {
  bool _hasVibrated = false;
  bool _isAligned = false;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    FlutterQiblah().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.qiblahDirection,
          style: TextStyle(
            fontFamily: "Amiri",
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    context.darkGradientStart,
                    context.darkGradientMid,
                    context.darkGradientEnd,
                  ]
                : [
                    context.lightSurface,
                    context.primaryExtraLightColor,
                    context.primaryLightColor,
                  ],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<QiblahCubit, QiblahState>(
            builder: (context, state) {
              if (state is QiblahLoading) {
                return LoadingState(isDark: isDark);
              } else if (state is QiblahError) {
                return ErrorState(message: state.message, isDark: isDark);
              } else if (state is QiblahPermissionDenied) {
                return PermissionDeniedState(
                  message: state.message,
                  isDark: isDark,
                  isPermanent: false,
                );
              } else if (state is QiblahPermissionDeniedForever) {
                return PermissionDeniedState(
                  message: state.message,
                  isDark: isDark,
                  isPermanent: true,
                );
              } else if (state is QiblahReady) {
                return QiblahCompass(
                  isDark: isDark,
                  pulseController: _pulseController,
                  rotationController: _rotationController,
                  pulseAnimation: _pulseAnimation,
                  scaleAnimation: _scaleAnimation,
                  isAligned: _isAligned,
                  hasVibrated: _hasVibrated,
                  onAlignmentChanged: (aligned) {
                    setState(() {
                      _isAligned = aligned;
                    });
                  },
                  onVibrationChanged: (vibrated) {
                    setState(() {
                      _hasVibrated = vibrated;
                    });
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
