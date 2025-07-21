import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/cache/cache_helper.dart';
import 'package:huda/core/routes/app_route.dart';
import 'package:huda/core/services/service_locator.dart';
import 'package:huda/cubit/athan/prayer_times_cubit.dart';
import 'package:huda/cubit/athkar/athkar_cubit.dart';
import 'package:huda/cubit/athkar_details/athkar_details_cubit.dart';
import 'package:huda/cubit/home/home_cubit.dart';
import 'package:huda/cubit/notifications/notifications_cubit.dart';
import 'package:huda/cubit/quran/quran_cubit.dart';
import 'package:huda/cubit/settings/settings_cubit.dart';
import 'package:huda/presentation/screens/athkar.dart';
import 'package:huda/presentation/screens/athkar_details.dart';
import 'package:huda/presentation/screens/home.dart';
import 'package:huda/presentation/screens/home_quran.dart';
import 'package:huda/presentation/screens/notifications.dart';
import 'package:huda/presentation/screens/prayer_times.dart';
import 'package:huda/presentation/screens/settings.dart';
import 'package:huda/presentation/screens/widget_management_screen.dart';

class PageRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.home:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(),
            child: Home(),
          ),
        );
      case AppRoute.homeQuran:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<QuranCubit>(
            create: (context) => (QuranCubit()),
            child: HomeQuran(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.settings:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(),
            child: Settings(), // Replace with your actual settings screen
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.widgetManagement:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => const WidgetManagementScreen(),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
      case AppRoute.prayerTimes:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<PrayerTimesCubit>(
            create: (context) => PrayerTimesCubit(getIt<CacheHelper>()),
            child: PrayerTimes(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case AppRoute.notification:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<NotificationsCubit>(
            create: (context) => NotificationsCubit(),
            child: Notifications(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.athkar:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) => BlocProvider<AthkarCubit>(
            create: (context) => AthkarCubit(),
            child: AthkarScreen(),
          ),
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      case AppRoute.athkarDetail:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, animation, __) {
            final args = settings.arguments as Map<String, String>;
            return BlocProvider<AthkarDetailsCubit>(
              create: (context) => AthkarDetailsCubit(),
              child: AthkarDetails(
                athkarId: args['athkarId']!,
                title: args['title']!,
                titleEn: args['titleEn']!,
              ),
            );
          },
          transitionsBuilder: (_, animation, __, child) {
            const begin = Offset(1.0, 0.0); // Slide in from right
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
    }
    return null;
  }
}
