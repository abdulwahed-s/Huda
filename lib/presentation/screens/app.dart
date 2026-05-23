import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:feedback/feedback.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
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
import 'package:huda/l10n/app_localizations.dart';

import 'package:huda/core/utils/responsive_utils.dart';

class App extends StatefulWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String _initialRoute = AppRoute.home;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
    WidgetDeepLinkHandler.start();
  }

  @override
  void dispose() {
    WidgetDeepLinkHandler.dispose();
    super.dispose();
  }

  Future<void> _determineInitialRoute() async {
    final cacheHelper = getIt<CacheHelper>();
    final onboardingCompleted =
        cacheHelper.getData(key: 'onboarding_completed') as bool?;

    setState(() {
      _initialRoute =
          (onboardingCompleted == true) ? AppRoute.home : AppRoute.onboarding;
    });
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
                    initialRoute: _initialRoute,
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
                          textScaler:
                              TextScaler.linear(themeState.textScaleFactor),
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
                child: screenUtilChild,
              );
            },
          );
        },
      ),
    );
  }
}
