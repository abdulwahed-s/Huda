import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:feedback/feedback.dart';
import 'package:huda/presentation/widgets/feedback/screenshot_feedback_widget.dart';
import 'package:huda/core/routes/page_router.dart';
import 'package:huda/core/services/quick_actions_service.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/core/services/widget_deep_link_handler.dart';
import 'package:huda/core/theme/app_theme.dart';
import 'package:huda/cubit/theme/theme_cubit.dart';
import 'package:huda/cubit/localization/localization_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/rating/rating_cubit.dart';
import 'package:huda/cubit/miqaat_lock/miqaat_lock_cubit.dart';
import 'package:huda/cubit/quran_player/quran_player_cubit.dart';
import 'package:huda/cubit/quran_player/download_progress_cubit.dart';
import 'package:huda/cubit/quran_player/player_bar_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_player_cubit.dart';
import 'package:huda/cubit/audiobook_player/audiobook_bar_cubit.dart';
import 'package:huda/core/services/audio_progress_service.dart';
import 'package:huda/data/services/offline_audiobooks_service.dart';
import 'package:huda/cubit/quran_radio/quran_radio_cubit.dart';
import 'package:huda/data/api/radio_services.dart';
import 'package:huda/data/repository/radio_repository.dart';
import 'package:huda/l10n/app_localizations.dart';

import 'package:huda/core/utils/responsive_utils.dart';

class App extends StatefulWidget {
  const App({super.key, required this.initialRoute});

  final String initialRoute;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    WidgetDeepLinkHandler.start();
  }

  @override
  void dispose() {
    WidgetDeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocalizationCubit()),
        BlocProvider(create: (_) => NotificationsCubit()),
        BlocProvider(create: (_) => RatingCubit()),
        BlocProvider<MiqaatLockCubit>.value(
          value: getIt<MiqaatLockCubit>(),
        ),
        BlocProvider(create: (_) => DownloadProgressCubit()),
        BlocProvider(
          create: (context) => QuranPlayerCubit(
            downloadProgressCubit: context.read<DownloadProgressCubit>(),
          ),
        ),
        BlocProvider(create: (_) => PlayerBarCubit()),
        BlocProvider(create: (_) => AudiobookBarCubit()),
        BlocProvider(
          create: (_) => AudiobookPlayerCubit(
            progressService: getIt<AudioProgressService>(),
            offlineService: getIt<OfflineAudiobooksService>(),
          ),
        ),
        BlocProvider(
          create: (_) => QuranRadioCubit(
            RadioRepository(radioServices: RadioServices()),
          ),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocalizationCubit, LocalizationState>(
            builder: (context, localizationState) {
              final screenUtilChild = ScreenUtilInit(
                designSize: ResponsiveUtils.getResponsiveDesignSize(context),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (_, __) {
                  return MaterialApp(
                    navigatorKey: App.navigatorKey,
                    debugShowCheckedModeBanner: false,
                    initialRoute: widget.initialRoute,
                    themeMode: themeState.themeMode,
                    theme: AppThemeHelper.getLightTheme(
                        themeState.colorTheme, themeState.fontFamily),
                    darkTheme: AppThemeHelper.getDarkTheme(
                      themeState.colorTheme,
                      themeState.fontFamily,
                    ),
                    locale: localizationState.locale,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: LocalizationCubit.supportedLocales,
                    localeResolutionCallback: (locale, supportedLocales) {
                      if (locale != null) {
                        for (var supportedLocale in supportedLocales) {
                          if (supportedLocale.languageCode ==
                              locale.languageCode) {
                            return supportedLocale;
                          }
                        }
                      }
                      return const Locale('en', '');
                    },
                    onGenerateRoute: PageRouter().generateRoute,
                    builder: (context, child) {
                      QuickActionsService.updateLocalizedLabels(context);
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(
                            themeState.textScaleFactor.isFinite
                                ? themeState.textScaleFactor.clamp(0.5, 2.0)
                                : 1.0,
                          ),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                },
              );

              final bool isDesktop =
                  Platform.isWindows || Platform.isLinux || Platform.isMacOS;

              if (isDesktop) return screenUtilChild;

              return BetterFeedback(
                themeMode: themeState.themeMode,
                feedbackBuilder: (context, onSubmit, scrollController) =>
                    ScreenshotFeedbackWidget(
                  onSubmit: onSubmit,
                  scrollController: scrollController,
                ),
                child: screenUtilChild,
              );
            },
          );
        },
      ),
    );
  }
}
